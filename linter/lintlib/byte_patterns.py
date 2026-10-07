"""Byte-oriented primitives used by the migrated predicates.

Positions and slices are 1-based UTF-8 byte offsets. Character classification
uses ASCII classes, preserving the original thresholds and match order. The
public document and report interfaces use ordinary Python dicts and strings.
"""
from functools import lru_cache, cmp_to_key
import math as _math
from pathlib import Path
import re
from types import SimpleNamespace


def B(value):
    return value.encode('utf-8') if isinstance(value, str) else bytes(value)


class T(dict):
    """A sparse, 1-based sequence or record; an absent field is None."""
    def __init__(self, fields=()):
        super().__init__()
        self._sequence_length = 0
        cursor = 1
        for key, value in fields:
            if key is None:
                key = cursor
                cursor += 1
            if value is not None:
                self[key] = value

    def __getattr__(self, name):
        return self.get(name.encode('ascii'))

    def __setitem__(self, key, value):
        super().__setitem__(key, value)
        if key == self._sequence_length + 1:
            while self._sequence_length + 1 in self:
                self._sequence_length += 1

    def _truncate_sequence(self, key):
        if isinstance(key, (int, float)) and 1 <= key <= self._sequence_length:
            self._sequence_length = int(key) - 1

    def __delitem__(self, key):
        super().__delitem__(key)
        self._truncate_sequence(key)

    def pop(self, key, *default):
        if len(default) > 1:
            raise TypeError(f'pop expected at most 2 arguments, got {len(default) + 1}')
        if key not in self:
            if default:
                return default[0]
            raise KeyError(key)
        value = self[key]
        del self[key]
        return value

    def popitem(self):
        key, value = super().popitem()
        self._truncate_sequence(key)
        return key, value

    def clear(self):
        super().clear()
        self._sequence_length = 0

    def update(self, other=(), **kwargs):
        fields = ((key, other[key]) for key in other.keys()) if hasattr(other, 'keys') else other
        for key, value in fields:
            self[key] = value
        for key, value in kwargs.items():
            self[key] = value

    def setdefault(self, key, default=None):
        if key not in self:
            self[key] = default
        return self[key]

    def __ior__(self, other):
        self.update(other)
        return self


class Multi(tuple):
    """Multiple return values, distinct from one sequence value."""


def first(value):
    return value[0] if isinstance(value, Multi) and value else (None if isinstance(value, Multi) else value)


def truth(value):
    value = first(value)
    return value is not None and value is not False


def pack(*values):
    if not values:
        return ()
    return tuple(first(value) for value in values[:-1]) + (tuple(values[-1]) if isinstance(values[-1], Multi) else (values[-1],))


def unpack(values, size):
    result = pack(*values)
    return (result + (None,) * size)[:size]


def ret(*values):
    return Multi(pack(*values))


def call(function, *args):
    return function(*pack(*args))


def get(value, key):
    value = first(value)
    if isinstance(value, dict):
        return value.get(key)
    if isinstance(key, bytes):
        key = key.decode('ascii')
    return getattr(value, key)


def set_(value, key, item):
    value = first(value)
    if isinstance(value, dict):
        if item is None:
            value.pop(key, None)
        else:
            value[key] = item
    else:
        setattr(value, key.decode() if isinstance(key, bytes) else key, item)


def length(value):
    value = first(value)
    if isinstance(value, T):
        return value._sequence_length
    return len(value)


def pairs(value):
    return (ret(key,item) for key,item in first(value).items())


def ipairs(value):
    value = first(value)
    return (ret(index, value[index]) for index in range(1, length(value) + 1))


def tostring(value):
    value = first(value)
    if isinstance(value, bytes):
        return value
    if value is None:
        return b'nil'
    if value is True:
        return b'true'
    if value is False:
        return b'false'
    return str(value).encode('utf-8')


def tonumber(value):
    try:
        return float(first(value))
    except (TypeError, ValueError):
        return None


def type_(value):
    value = first(value)
    if value is None:
        return b'nil'
    if isinstance(value, bool):
        return b'boolean'
    if isinstance(value, (int, float)):
        return b'number'
    if isinstance(value, bytes):
        return b'string'
    if isinstance(value, dict):
        return b'table'
    return b'function' if callable(value) else b'userdata'


def concat(a, b):
    return tostring(a) + tostring(b)


_CLASSES = {
    ord('a'): b'A-Za-z', ord('d'): b'0-9', ord('l'): b'a-z',
    ord('u'): b'A-Z', ord('w'): b'A-Za-z0-9',
    ord('s'): b'\\x09-\\x0d ', ord('c'): b'\\x00-\\x1f\\x7f',
    ord('p'): b'!-/:-@[-`{-~', ord('x'): b'A-Fa-f0-9', ord('z'): b'\\x00',
}


def _character_class(pattern, start):
    """Translate one byte class; return regex class and next offset."""
    output = bytearray(b'[')
    cursor = start + 1
    if pattern[cursor:cursor+1] == b'^':
        output.extend(b'^')
        cursor += 1
    while cursor < len(pattern):
        char = pattern[cursor]
        if char == ord(']'):
            output.extend(b']')
            return bytes(output), cursor + 1
        if char == ord('%'):
            cursor += 1
            escaped = pattern[cursor]
            if escaped in _CLASSES:
                output.extend(_CLASSES[escaped])
            elif escaped + 32 in _CLASSES:
                positive = re.compile(b'[' + _CLASSES[escaped + 32] + b']')
                output.extend(b''.join(re.escape(bytes([item])) for item in range(256) if positive.fullmatch(bytes([item])) is None))
            else:
                output.extend(re.escape(bytes([escaped])))
        elif char == ord('\\'):
            output.extend(b'\\\\')
        elif char == ord('['):
            output.extend(b'\\[')
        else:
            output.append(char)
        cursor += 1
    raise ValueError(f'unclosed byte pattern class: {pattern!r}')


@lru_cache(maxsize=1024)
def compile_pattern(pattern):
    output = bytearray()
    cursor = 0
    can_repeat = False
    while cursor < len(pattern):
        char = pattern[cursor]
        if char == ord('['):
            translated, cursor = _character_class(pattern, cursor)
            output.extend(translated)
            can_repeat = True
            continue
        if char == ord('%'):
            cursor += 1
            escaped = pattern[cursor]
            if escaped in _CLASSES or escaped + 32 in _CLASSES:
                inverted = escaped not in _CLASSES
                body = _CLASSES.get(escaped, _CLASSES.get(escaped + 32))
                output.extend(b'[' + (b'^' if inverted else b'') + body + b']')
            elif escaped == ord('f'):
                body, cursor = _character_class(pattern, cursor + 1)
                includes_zero = re.fullmatch(body, b'\x00') is not None
                previous = b'(?<!' + body + b')' + (b'(?!\\A)' if includes_zero else b'')
                current = b'(?=' + body + (b'|\\Z)' if includes_zero else b')')
                output.extend(previous + current)
                can_repeat = False
                continue
            elif ord('1') <= escaped <= ord('9'):
                output.extend(b'\\' + bytes([escaped]))
            else:
                output.extend(re.escape(bytes([escaped])))
            can_repeat = True
        elif char in b'*+?-':
            if can_repeat:
                output.extend(b'*?' if char == ord('-') else bytes([char]))
                can_repeat = False
            else:
                output.extend(re.escape(bytes([char])))
                can_repeat = True
        elif char in b'()':
            output.append(char)
            can_repeat = False
        elif char == ord('^') and cursor == 0:
            output.extend(b'^')
            can_repeat = False
        elif char == ord('$') and cursor == len(pattern)-1:
            output.extend(b'\\Z')
            can_repeat = False
        elif char == ord('.'):
            output.extend(b'.')
            can_repeat = True
        else:
            output.extend(re.escape(bytes([char])))
            can_repeat = True
        cursor += 1
    return re.compile(bytes(output), re.DOTALL)


def _index(value, size):
    value = int(value)
    return size + value + 1 if value < 0 else value


def _balanced_spans(data, opener, closer):
    depth, start = 0, None
    for index, char in enumerate(data):
        if char == opener:
            if depth == 0:
                start = index
            depth += 1
        elif char == closer and depth:
            depth -= 1
            if depth == 0:
                yield start, index + 1


def method(value, name, *args):
    value = first(value)
    args = pack(*args)
    name = name.decode() if isinstance(name, bytes) else name
    if not isinstance(value, bytes):
        if name == 'read':
            return value.read() if args == (b'*a',) else value.read(*args)
        return getattr(value, name)(*args)
    if name == 'sub':
        start = max(1, _index(args[0], len(value)))
        end = min(len(value), _index(args[1], len(value))) if len(args) > 1 else len(value)
        return value[start - 1:end]
    if name in ('lower', 'upper'):
        return getattr(value, name)()
    if name == 'byte':
        start = _index(args[0], len(value)) if args else 1
        end = _index(args[1], len(value)) if len(args) > 1 else start
        return Multi(value[max(0, start-1):end])
    if name == 'find':
        pattern = args[0]
        start = max(0, _index(args[1], len(value)) - 1) if len(args) > 1 else 0
        if len(args) > 2 and truth(args[2]):
            pos = value.find(pattern, start)
            return None if pos < 0 else ret(pos+1, pos+len(pattern))
        match = compile_pattern(pattern).search(value[start:])
        return None if match is None else ret(match.start()+start+1, match.end()+start, *match.groups())
    if name == 'match':
        start = max(0, _index(args[1], len(value))-1) if len(args) > 1 else 0
        match = compile_pattern(args[0]).search(value[start:])
        if match is None:
            return None
        return ret(*match.groups()) if match.groups() else match.group()
    if name == 'gmatch':
        return (ret(*match.groups()) if match.groups() else match.group() for match in compile_pattern(args[0]).finditer(value))
    if name == 'gsub':
        pattern, replacement = args[:2]
        count = int(args[2]) if len(args) > 2 else 0
        if pattern == b'%b()':
            spans = list(_balanced_spans(value, ord('('), ord(')')))
            if count:
                spans = spans[:count]
            parts, cursor = [], 0
            for start, end in spans:
                parts.extend((value[cursor:start], replacement))
                cursor = end
            return ret(b''.join(parts) + value[cursor:], len(spans))
        def replace(match):
            captures = match.groups() or (match.group(),)
            if callable(replacement):
                result = first(replacement(*captures))
            elif isinstance(replacement, dict):
                result = replacement.get(captures[0])
            else:
                result = re.sub(rb'%([0-9%])', lambda found: b'%' if found[1] == b'%' else match.group(int(found[1])), replacement)
            return tostring(result) if truth(result) else match.group()
        result, total = compile_pattern(pattern).subn(replace, value, count=count)
        return ret(result, total)
    raise ValueError(f'unknown byte operation: {name}')


def _insert(values, *args):
    index, value = (length(values)+1, args[0]) if len(args) == 1 else args
    for cursor in range(length(values), index-1, -1):
        values[cursor+1] = values[cursor]
    values[index] = value


def _sort(values, compare=None):
    items = [item for _, item in ipairs(values)]
    if compare is None:
        items.sort()
    else:
        items.sort(key=cmp_to_key(lambda a,b: -1 if truth(first(compare(a,b))) else (1 if truth(first(compare(b,a))) else 0)))
    for index, item in enumerate(items, 1):
        values[index] = item


def _codes(text):
    cursor = 1
    for char in text.decode('utf-8'):
        yield ret(cursor, ord(char))
        cursor += len(char.encode('utf-8'))


def _codepoint(text, pos=1):
    start = int(pos) - 1
    lead = text[start]
    width = 1 if lead < 0x80 else (2 if lead < 0xE0 else (3 if lead < 0xF0 else 4))
    return ord(text[start:start + width].decode('utf-8'))


def _offset(text, n, pos=None):
    n = int(n)
    pos = int(pos if pos is not None else (1 if n >= 0 else len(text)+1))
    starts = [start for start,_ in _codes(text)] + [len(text)+1]
    if n == 0:
        return next((start for start in reversed(starts) if start <= pos), None)
    candidates = [start for start in starts if start >= pos] if n > 0 else [start for start in reversed(starts) if start < pos]
    index = n-1 if n > 0 else -n-1
    return candidates[index] if index < len(candidates) else None


def _open(path, mode=b'rb'):
    try:
        return ret(open(path.decode() if isinstance(path,bytes) else path, mode.decode()))
    except OSError as error:
        return ret(None, str(error).encode())


def error(message):
    raise ValueError(tostring(message).decode('utf-8'))


string = SimpleNamespace(rep=lambda value,n: value * int(n), byte=lambda value: value[0], format=lambda format_,*args: format_ % tuple(args))
table = SimpleNamespace(insert=_insert, concat=lambda values, separator=b'': separator.join(item for _,item in ipairs(values)), sort=_sort)
utf8 = SimpleNamespace(codes=_codes, char=lambda cp: chr(cp).encode(), codepoint=_codepoint, offset=_offset)
math = SimpleNamespace(floor=_math.floor, max=max, min=min)
io = SimpleNamespace(open=_open)


def from_native(value):
    if isinstance(value, str):
        return B(value)
    if isinstance(value, dict):
        return T((from_native(key), from_native(item)) for key,item in value.items())
    if isinstance(value, (list,tuple)):
        return T((None,from_native(item)) for item in value)
    return value


def to_native(value):
    value = first(value)
    if isinstance(value, bytes):
        return value.decode('utf-8')
    if isinstance(value, T):
        if value and all(isinstance(key,int) for key in value) and len(value) == length(value):
            return [to_native(value[index]) for index in range(1,length(value)+1)]
        return {to_native(key):to_native(item) for key,item in value.items()}
    return value


def next_(value):
    return next(iter(first(value)), None)
