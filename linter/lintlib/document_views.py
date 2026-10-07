"""Document classification, glossary forms and byte locations."""
from lintlib.byte_patterns import T, get, set_, truth, first, unpack, call, concat, length, method, string, table, utf8, math, io, pairs, ipairs, tostring, tonumber, type_, error
M = T([])
LEFT_PAREN = '（'.encode('utf-8')
RIGHT_PAREN = '）'.encode('utf-8')
TERM_BOUNDARY_CHARS = T([(b',', True), (b'.', True), (b';', True), (b':', True), (b'!', True), (b'?', True), ('，'.encode('utf-8'), True), ('。'.encode('utf-8'), True), ('；'.encode('utf-8'), True), ('：'.encode('utf-8'), True), ('！'.encode('utf-8'), True), ('？'.encode('utf-8'), True), ('「'.encode('utf-8'), True), ('」'.encode('utf-8'), True), ('『'.encode('utf-8'), True), ('』'.encode('utf-8'), True), ('（'.encode('utf-8'), True), ('）'.encode('utf-8'), True), (b'(', True), (b')', True), (b'[', True), (b']', True), (b'{', True), (b'}', True), (b'<', True), (b'>', True), (b'"', True), (b"'", True)])

# Source: scripts/lintlib/core.lua:36
def read_file(path=None, *_ignored):
    handle, err = unpack([call(io.open, path, b'rb')], 2)
    if not truth(handle):
        call(error, concat(b'failed to open ', concat(path, concat(b': ', first(call(tostring, err))))))
    text = first(method(handle, b'read', b'*a'))
    method(handle, b'close')
    return text
set_(M, b'read_file', read_file)

# Source: scripts/lintlib/core.lua:47
def file_exists(path=None, *_ignored):
    handle = first(call(io.open, path, b'rb'))
    if not truth(handle):
        return False
    method(handle, b'close')
    return True
set_(M, b'file_exists', file_exists)

# Source: scripts/lintlib/core.lua:56
def trim(text=None, *_ignored):
    return first(method(first(method(text, b'gsub', b'^%s+', b'')), b'gsub', b'%s+$', b''))
set_(M, b'trim', trim)

# Source: scripts/lintlib/core.lua:60
def split_csv(text=None, *_ignored):
    values = T([])
    for _iteration_1 in first(method(first(call(tostring, text)), b'gmatch', b'([^,]+)')):
        chunk, = unpack([_iteration_1], 1)
        trimmed = first(call(M.trim, chunk))
        if trimmed != b'':
            call(table.insert, values, trimmed)
    return values
set_(M, b'split_csv', split_csv)

# Source: scripts/lintlib/core.lua:71
def make_set(values=None, *_ignored):
    set = T([])
    for _iteration_2 in first(call(ipairs, values)):
        _, value = unpack([_iteration_2], 2)
        set_(set, value, True)
    return set
set_(M, b'make_set', make_set)

# Source: scripts/lintlib/core.lua:79
def count_substring(text=None, needle=None, *_ignored):
    count = 0
    start = 1
    while True:
        first__2 = first(method(text, b'find', needle, start, True))
        if not truth(first__2):
            break
        count = count + 1
        start = first__2 + length(needle)
    return count
set_(M, b'count_substring', count_substring)

# Source: scripts/lintlib/core.lua:93
def contains_ascii_letter(text=None, *_ignored):
    return first(method(text, b'find', b'%a')) != None
set_(M, b'contains_ascii_letter', contains_ascii_letter)

# Source: scripts/lintlib/core.lua:97
def contains_non_ascii(text=None, *_ignored):
    return first(method(text, b'find', b'[\x80-\xff]')) != None
set_(M, b'contains_non_ascii', contains_non_ascii)

# Source: scripts/lintlib/core.lua:101
def is_cjk(cp=None, *_ignored):
    return _condition_7 if truth((_condition_7 := (_condition_5 if truth((_condition_5 := first(cp <= 19903 if truth((_condition_3 := (cp >= 13312))) else _condition_3))) else first(cp <= 40959 if truth((_condition_4 := (cp >= 19968))) else _condition_4)))) else first(cp <= 64255 if truth((_condition_6 := (cp >= 63744))) else _condition_6)
set_(M, b'is_cjk', is_cjk)

# Source: scripts/lintlib/core.lua:108
def codepoints(text=None, *_ignored):
    values = T([])
    for _iteration_8 in first(call(utf8.codes, text)):
        pos, cp = unpack([_iteration_8], 2)
        call(table.insert, values, T([(b'pos', pos), (b'cp', cp), (b'char', first(call(utf8.char, cp)))]))
    return values
set_(M, b'codepoints', codepoints)

# Source: scripts/lintlib/core.lua:120
def contains_cjk(text=None, *_ignored):
    for _iteration_9 in first(call(ipairs, call(M.codepoints, text))):
        _, item = unpack([_iteration_9], 2)
        if truth(first(call(M.is_cjk, item.cp))):
            return True
    return False
set_(M, b'contains_cjk', contains_cjk)

# Source: scripts/lintlib/core.lua:129
def visible_length(text=None, *_ignored):
    count = 0
    for _iteration_10 in first(call(ipairs, call(M.codepoints, text))):
        _, item = unpack([_iteration_10], 2)
        char = item.char
        if not truth(first(method(char, b'match', b'%s'))):
            count = count + 1
    return count
set_(M, b'visible_length', visible_length)

# Source: scripts/lintlib/core.lua:140
def mask_inline_code(text=None, *_ignored):

    def _callback_11(segment=None, *_ignored):
        return call(string.rep, b' ', length(segment))
    return first(method(text, b'gsub', b'`[^`\n]-`', _callback_11))
set_(M, b'mask_inline_code', mask_inline_code)

# Source: scripts/lintlib/core.lua:146
def escape_pattern(text=None, *_ignored):
    return first(method(text, b'gsub', b'([%(%)%.%%%+%-%*%?%[%]%^%$])', b'%%%1'))
set_(M, b'escape_pattern', escape_pattern)

# Source: scripts/lintlib/core.lua:150
def normalize_english_term(text=None, *_ignored):
    normalized = first(method(first(call(M.trim, call(tostring, _condition_12 if truth((_condition_12 := text)) else b''))), b'lower'))
    normalized = first(method(normalized, b'gsub', '（[^）]-）'.encode('utf-8'), b''))
    normalized = first(method(normalized, b'gsub', b'%b()', b''))
    normalized = first(method(normalized, b'gsub', b'%s+', b' '))
    return call(M.trim, normalized)
set_(M, b'normalize_english_term', normalize_english_term)

# Source: scripts/lintlib/core.lua:158
def normalize_chinese_term(text=None, *_ignored):
    normalized = first(call(M.trim, call(tostring, _condition_13 if truth((_condition_13 := text)) else b'')))
    normalized = first(method(normalized, b'gsub', b'%s+', b''))
    normalized = first(method(normalized, b'gsub', '^[、，；：]+'.encode('utf-8'), b''))
    normalized = first(method(normalized, b'gsub', '^和'.encode('utf-8'), b''))
    normalized = first(method(normalized, b'gsub', '^與'.encode('utf-8'), b''))
    normalized = first(method(normalized, b'gsub', '^及'.encode('utf-8'), b''))
    return normalized
set_(M, b'normalize_chinese_term', normalize_chinese_term)

# Source: scripts/lintlib/core.lua:168
def first_nonspace_col(text=None, *_ignored):
    first__2 = first(method(text, b'find', b'%S'))
    return _condition_14 if truth((_condition_14 := first__2)) else 1
set_(M, b'first_nonspace_col', first_nonspace_col)

# Source: scripts/lintlib/core.lua:173
def byte_to_char_col(text=None, byte_col=None, *_ignored):
    source = first(call(tostring, _condition_15 if truth((_condition_15 := text)) else b''))
    target = first(call(math.floor, _condition_16 if truth((_condition_16 := first(call(tonumber, byte_col)))) else 1))
    if target <= 1:
        return 1
    after_end = length(source) + 1
    if target > after_end:
        target = after_end
    char_col = 1
    for _iteration_17 in first(call(utf8.codes, source)):
        pos, _ = unpack([_iteration_17], 2)
        if pos >= target:
            return char_col
        char_col = char_col + 1
    return char_col
set_(M, b'byte_to_char_col', byte_to_char_col)

# Source: scripts/lintlib/core.lua:197
def is_sentence_like(text=None, *_ignored):
    trimmed = first(call(M.trim, text))
    if trimmed == b'':
        return False
    if truth(first(method(trimmed, b'find', '[。！？；：%.%!%?]$'.encode('utf-8')))):
        return True
    return first(method(trimmed, b'find', '：$'.encode('utf-8'))) != None
set_(M, b'is_sentence_like', is_sentence_like)

# Source: scripts/lintlib/core.lua:210
def last_nonspace_codepoint(codepoints=None, *_ignored):
    _start_18, _stop_19, _step_20 = (length(codepoints), 1, -1)
    for index in range(int(_start_18), int(_stop_19) + (1 if _step_20 > 0 else -1), int(_step_20)):
        if not truth(first(method(get(codepoints, index).char, b'match', b'%s'))):
            return get(codepoints, index)
    return None
set_(M, b'last_nonspace_codepoint', last_nonspace_codepoint)

# Source: scripts/lintlib/core.lua:219
def previous_nonspace(codepoints=None, index=None, *_ignored):
    _start_21, _stop_22, _step_23 = (index - 1, 1, -1)
    for cursor in range(int(_start_21), int(_stop_22) + (1 if _step_23 > 0 else -1), int(_step_23)):
        if not truth(first(method(get(codepoints, cursor).char, b'match', b'%s'))):
            return get(codepoints, cursor)
    return None
set_(M, b'previous_nonspace', previous_nonspace)

# Source: scripts/lintlib/core.lua:228
def next_nonspace(codepoints=None, index=None, *_ignored):
    _start_24, _stop_25, _step_26 = (index + 1, length(codepoints), 1)
    for cursor in range(int(_start_24), int(_stop_25) + (1 if _step_26 > 0 else -1), int(_step_26)):
        if not truth(first(method(get(codepoints, cursor).char, b'match', b'%s'))):
            return get(codepoints, cursor)
    return None
set_(M, b'next_nonspace', next_nonspace)

# Source: scripts/lintlib/core.lua:237
def is_code_fence_start(stripped=None, *_ignored):
    return method(stripped, b'match', b'^([`~][`~][`~]+)')

# Source: scripts/lintlib/core.lua:241
def is_code_fence_end(stripped=None, fence_char=None, fence_len=None, *_ignored):
    run = first(method(stripped, b'match', concat(b'^(', concat(fence_char, b'+)'))))
    return length(run) >= fence_len if truth((_condition_27 := run)) else _condition_27

# Source: scripts/lintlib/core.lua:246
def count_pipes(text=None, *_ignored):
    _, count = unpack([method(text, b'gsub', b'|', b'')], 2)
    return count

# Source: scripts/lintlib/core.lua:251
def is_html_like_tag(stripped=None, *_ignored):
    return first(method(stripped, b'match', b'^</?[%a][%w%-]*[^>]*>$')) != None

# Source: scripts/lintlib/core.lua:255
def is_directive_marker(stripped=None, *_ignored):
    return first(method(stripped, b'match', b'^:::+')) != None

# Source: scripts/lintlib/core.lua:259
def classify_lines(text=None, *_ignored):
    lines = T([])
    byte_offset = 1
    in_code_fence = False
    fence_char = None
    fence_len = 0
    in_frontmatter = False
    frontmatter_pending = False
    in_math_block = False
    for _iteration_28 in first(method(first(concat(text, b'\n')), b'gmatch', b'(.-)\n')):
        raw_line, = unpack([_iteration_28], 1)
        stripped = first(call(M.trim, raw_line))
        leading_ws = _condition_29 if truth((_condition_29 := first(method(raw_line, b'match', b'^(%s*)')))) else b''
        if length(lines) == 0 and stripped == b'---':
            frontmatter_pending = True
        line = T([(b'number', length(lines) + 1), (b'text', raw_line), (b'masked_text', first(call(M.mask_inline_code, raw_line))), (b'stripped', stripped), (b'start_byte', byte_offset), (b'end_byte', byte_offset + length(raw_line) - 1), (b'is_blank', stripped == b''), (b'is_code', False), (b'is_fence', False), (b'is_heading', False), (b'is_list', False), (b'list_indent', length(leading_ws)), (b'is_table', False), (b'is_blockquote', False), (b'is_tag', False), (b'is_frontmatter', False), (b'is_directive', False), (b'is_math', False)])
        if truth(frontmatter_pending) or truth(in_frontmatter):
            set_(line, b'is_frontmatter', True)
            set_(line, b'is_code', True)
            if truth(frontmatter_pending):
                in_frontmatter = True
                frontmatter_pending = False
            elif stripped == b'---':
                in_frontmatter = False
        elif not truth(in_code_fence):
            opener = first(call(is_code_fence_start, stripped))
            if truth(opener):
                set_(line, b'is_code', True)
                set_(line, b'is_fence', True)
                in_code_fence = True
                fence_char = first(method(opener, b'sub', 1, 1))
                fence_len = length(opener)
            elif truth(in_math_block):
                set_(line, b'is_math', True)
                set_(line, b'is_code', True)
                if stripped == b'$$':
                    in_math_block = False
            elif stripped == b'$$':
                set_(line, b'is_math', True)
                set_(line, b'is_code', True)
                in_math_block = True
            elif truth(first(call(is_directive_marker, stripped))):
                set_(line, b'is_directive', True)
            elif truth(first(call(is_html_like_tag, stripped))):
                set_(line, b'is_tag', True)
            else:
                set_(line, b'is_heading', first(method(stripped, b'match', b'^#+%s+')) != None)
                set_(line, b'is_blockquote', first(method(stripped, b'match', b'^>%s*')) != None)
                set_(line, b'is_list', _condition_30 if truth((_condition_30 := (first(method(stripped, b'match', b'^[-*+]%s+')) != None))) else first(method(stripped, b'match', b'^%d+%.%s+')) != None)
                set_(line, b'is_table', _condition_31 if truth((_condition_31 := (first(call(count_pipes, raw_line)) >= 2))) else first(method(stripped, b'match', b'^|?%s*:?-+:?%s*(|%s*:?-+:?%s*)+|?$')) != None)
        else:
            set_(line, b'is_code', True)
            if truth(first(call(is_code_fence_end, stripped, fence_char, fence_len))):
                set_(line, b'is_fence', True)
                in_code_fence = False
                fence_char = None
                fence_len = 0
        call(table.insert, lines, line)
        byte_offset = byte_offset + length(raw_line) + 1
    return lines

# Source: scripts/lintlib/core.lua:352
def build_paragraphs(lines=None, *_ignored):
    paragraphs = T([])
    current = T([])

    def flush(*_ignored):
        nonlocal current
        if length(current) == 0:
            return None
        texts = T([])
        for _iteration_32 in first(call(ipairs, current)):
            _, line = unpack([_iteration_32], 2)
            call(table.insert, texts, line.text)
        text = first(call(table.concat, texts, b'\n'))
        call(table.insert, paragraphs, T([(b'start_line', get(current, 1).number), (b'end_line', get(current, length(current)).number), (b'lines', current), (b'line_count', length(current)), (b'text', text), (b'visible_length', first(call(M.visible_length, text)))]))
        current = T([])
    for _iteration_33 in first(call(ipairs, lines)):
        _, line = unpack([_iteration_33], 2)
        if ((((((truth(line.is_blank) or truth(line.is_code)) or truth(line.is_tag)) or truth(line.is_directive)) or truth(line.is_list)) or truth(line.is_heading)) or truth(line.is_table)) or truth(line.is_blockquote):
            call(flush)
        else:
            call(table.insert, current, line)
    call(flush)
    return paragraphs

# Source: scripts/lintlib/core.lua:400
def build_prose_text(lines=None, *_ignored):
    fragments = T([])
    for _iteration_34 in first(call(ipairs, lines)):
        _, line = unpack([_iteration_34], 2)
        if not truth(line.is_code):
            call(table.insert, fragments, line.masked_text)
        else:
            call(table.insert, fragments, b'')
    return call(table.concat, fragments, b'\n')

# Source: scripts/lintlib/core.lua:412
def build_document(path=None, text=None, *_ignored):
    lines = first(call(classify_lines, text))
    paragraphs = first(call(build_paragraphs, lines))
    return T([(b'path', path), (b'text', text), (b'prose_text', first(call(build_prose_text, lines))), (b'lines', lines), (b'paragraphs', paragraphs), (b'first_paragraph', get(paragraphs, 1))])
set_(M, b'build_document', build_document)

# Source: scripts/lintlib/core.lua:425
def split_markdown_row(text=None, *_ignored):
    row = first(call(M.trim, text))
    if first(method(row, b'sub', 1, 1)) == b'|':
        row = first(method(row, b'sub', 2))
    if first(method(row, b'sub', -1)) == b'|':
        row = first(method(row, b'sub', 1, -2))
    cells = T([])
    for _iteration_35 in first(method(first(concat(row, b'|')), b'gmatch', b'(.-)|')):
        cell, = unpack([_iteration_35], 1)
        call(table.insert, cells, call(M.trim, cell))
    return cells

# Source: scripts/lintlib/core.lua:441
def is_separator_row(cells=None, *_ignored):
    if length(cells) == 0:
        return False
    for _iteration_36 in first(call(ipairs, cells)):
        _, cell = unpack([_iteration_36], 2)
        if cell == b'' or not truth(first(method(cell, b'match', b'^:?-+:?$'))):
            return False
    return True

# Source: scripts/lintlib/core.lua:455
def append_unique(values=None, seen=None, value=None, *_ignored):
    if value != b'' and (not truth(get(seen, value))):
        set_(seen, value, True)
        call(table.insert, values, value)

# Source: scripts/lintlib/core.lua:462
def expand_optional_parentheses(text=None, values=None, seen=None, *_ignored):
    open_pos = first(method(text, b'find', LEFT_PAREN, 1, True))
    if not truth(open_pos):
        call(append_unique, values, seen, text)
        return None
    close_pos = first(method(text, b'find', RIGHT_PAREN, open_pos + length(LEFT_PAREN), True))
    if not truth(close_pos):
        call(append_unique, values, seen, text)
        return None
    prefix = first(method(text, b'sub', 1, open_pos - 1))
    inner = first(method(text, b'sub', open_pos + length(LEFT_PAREN), close_pos - 1))
    suffix = first(method(text, b'sub', close_pos + length(RIGHT_PAREN)))
    call(expand_optional_parentheses, concat(prefix, suffix), values, seen)
    call(expand_optional_parentheses, concat(prefix, concat(inner, suffix)), values, seen)

# Source: scripts/lintlib/core.lua:483
def parse_english_variants(text=None, *_ignored):
    cleaned = first(method(first(method(first(call(tostring, _condition_37 if truth((_condition_37 := text)) else b'')), b'gsub', '（[^）]-）'.encode('utf-8'), b'')), b'gsub', b'%b()', b''))
    raw_variants = T([])
    if truth(first(method(cleaned, b'find', b'%s/%s'))):
        for _iteration_38 in first(method(cleaned, b'gmatch', b'([^/]+)')):
            chunk, = unpack([_iteration_38], 1)
            variant = first(call(M.normalize_english_term, chunk))
            if variant != b'':
                call(table.insert, raw_variants, variant)
    else:
        normalized = first(call(M.normalize_english_term, cleaned))
        if normalized != b'':
            call(table.insert, raw_variants, normalized)
    return raw_variants

# Source: scripts/lintlib/core.lua:502
def parse_chinese_variants(text=None, *_ignored):
    raw = first(call(M.trim, call(tostring, _condition_39 if truth((_condition_39 := text)) else b'')))
    if raw == b'':
        return T([])
    pieces = T([])
    normalized_separators = first(method(first(method(first(method(raw, b'gsub', '、'.encode('utf-8'), b'|')), b'gsub', '，'.encode('utf-8'), b'|')), b'gsub', b',', b'|'))
    if truth(first(method(normalized_separators, b'find', b'|', 1, True))):
        for _iteration_40 in first(method(normalized_separators, b'gmatch', b'([^|]+)')):
            chunk, = unpack([_iteration_40], 1)
            variant = first(call(M.trim, chunk))
            if variant != b'':
                call(table.insert, pieces, variant)
    else:
        call(table.insert, pieces, raw)
    variants = T([])
    seen = T([])
    for _iteration_41 in first(call(ipairs, pieces)):
        _, piece = unpack([_iteration_41], 2)
        expanded = T([])
        call(expand_optional_parentheses, piece, expanded, T([]))
        for _iteration_42 in first(call(ipairs, expanded)):
            ___2, candidate = unpack([_iteration_42], 2)
            normalized = first(call(M.normalize_chinese_term, candidate))
            call(append_unique, variants, seen, normalized)
    return variants

# Source: scripts/lintlib/core.lua:535
def copy_glossary_entries(entries=None, *_ignored):
    copied = T([])
    for _iteration_44 in first(call(pairs, _condition_43 if truth((_condition_43 := entries)) else T([]))):
        english, entry = unpack([_iteration_44], 2)
        clone = T([(b'preferred_terms', T([])), (b'preferred_set', T([]))])
        for _iteration_46 in first(call(ipairs, _condition_45 if truth((_condition_45 := entry.preferred_terms)) else T([]))):
            _, term = unpack([_iteration_46], 2)
            call(table.insert, clone.preferred_terms, term)
            set_(clone.preferred_set, term, True)
        set_(copied, english, clone)
    return copied

# Source: scripts/lintlib/core.lua:551
def parse_glossary_file(path=None, *_ignored):
    entries = T([])
    if not truth(first(call(M.file_exists, path))):
        return entries
    text = first(call(M.read_file, path))
    for _iteration_47 in first(method(first(concat(text, b'\n')), b'gmatch', b'(.-)\n')):
        raw_line, = unpack([_iteration_47], 1)
        stripped = first(call(M.trim, raw_line))
        if truth(first(method(stripped, b'match', b'^|'))):
            cells = first(call(split_markdown_row, stripped))
            if length(cells) >= 2 and (not truth(first(call(is_separator_row, cells)))):
                is_header = first(call(M.normalize_chinese_term, get(cells, 2))) == '臺灣用語'.encode('utf-8') if truth((_condition_48 := (first(call(M.normalize_chinese_term, get(cells, 1))) == '英文'.encode('utf-8')))) else _condition_48
                if not truth(is_header):
                    english_terms = first(call(parse_english_variants, get(cells, 1)))
                    chinese_terms = first(call(parse_chinese_variants, get(cells, 2)))
                    for _iteration_49 in first(call(ipairs, english_terms)):
                        _, english = unpack([_iteration_49], 2)
                        entry = get(entries, english)
                        if not truth(entry):
                            entry = T([(b'preferred_terms', T([])), (b'preferred_set', T([]))])
                            set_(entries, english, entry)
                        for _iteration_50 in first(call(ipairs, chinese_terms)):
                            ___2, chinese = unpack([_iteration_50], 2)
                            if not truth(get(entry.preferred_set, chinese)):
                                call(table.insert, entry.preferred_terms, chinese)
                                set_(entry.preferred_set, chinese, True)
    return entries
set_(M, b'parse_glossary_file', parse_glossary_file)

# Source: scripts/lintlib/core.lua:594
def merge_glossary_entries(base_entries=None, override_entries=None, *_ignored):
    merged = first(call(copy_glossary_entries, base_entries))
    for _iteration_52 in first(call(pairs, _condition_51 if truth((_condition_51 := override_entries)) else T([]))):
        english, entry = unpack([_iteration_52], 2)
        set_(merged, english, get(first(call(copy_glossary_entries, T([(english, entry)]))), english))
    return merged
set_(M, b'merge_glossary_entries', merge_glossary_entries)

# Source: scripts/lintlib/core.lua:602
def infer_project_root(path=None, *_ignored):
    raw_path = first(call(tostring, _condition_53 if truth((_condition_53 := path)) else b''))
    project_root = first(method(raw_path, b'match', b'^(.-/working/[^/]+)/'))
    if truth(project_root):
        return project_root
    return method(raw_path, b'match', b'^%.?/?(working/[^/]+)/')

# Source: scripts/lintlib/core.lua:611
def load_glossary_context(path=None, repo_root=None, *_ignored):
    glossary = T([])
    if truth(repo_root):
        glossary = first(call(M.merge_glossary_entries, glossary, call(M.parse_glossary_file, concat(repo_root, b'/references/glossary.md'))))
    project_root = first(call(infer_project_root, path))
    if truth(project_root):
        for _iteration_54 in first(call(ipairs, T([(None, b'glossary.md'), (None, b'termbase.md')]))):
            _, filename = unpack([_iteration_54], 2)
            glossary = first(call(M.merge_glossary_entries, glossary, call(M.parse_glossary_file, concat(project_root, concat(b'/', filename)))))
    return glossary
set_(M, b'load_glossary_context', load_glossary_context)

# Source: scripts/lintlib/core.lua:628
def extract_outer_term(text=None, *_ignored):
    trimmed = first(call(M.trim, text))
    ascii = first(method(trimmed, b'match', b'([%a][%w%-%._/ ]-)$'))
    if truth(ascii) and ascii != b'':
        return call(M.trim, ascii)
    trailing = T([])
    codepoints = first(call(M.codepoints, trimmed))
    _start_55, _stop_56, _step_57 = (length(codepoints), 1, -1)
    for index in range(int(_start_55), int(_stop_56) + (1 if _step_57 > 0 else -1), int(_step_57)):
        char = get(codepoints, index).char
        if truth(first(method(char, b'match', b'%s'))) or truth(get(TERM_BOUNDARY_CHARS, char)):
            break
        call(table.insert, trailing, 1, char)
    candidate = first(call(M.trim, call(table.concat, trailing)))
    markers = T([(None, '也就是'.encode('utf-8')), (None, '就是'.encode('utf-8')), (None, '則是'.encode('utf-8')), (None, '叫做'.encode('utf-8')), (None, '稱作'.encode('utf-8')), (None, '稱為'.encode('utf-8')), (None, '具有'.encode('utf-8')), (None, '屬於'.encode('utf-8')), (None, '是'.encode('utf-8')), (None, '為'.encode('utf-8'))])
    for _iteration_58 in first(call(ipairs, markers)):
        _, marker = unpack([_iteration_58], 2)
        search_from = 1
        while True:
            found = first(method(candidate, b'find', marker, search_from, True))
            if not truth(found):
                break
            before = first(call(M.trim, method(candidate, b'sub', 1, found - 1)))
            after = first(call(M.trim, method(candidate, b'sub', found + length(marker))))
            if first(call(M.visible_length, before)) >= 2 and first(call(M.visible_length, after)) >= 2:
                candidate = after
                search_from = 1
            else:
                search_from = found + length(marker)
    for _iteration_59 in first(call(ipairs, T([(None, '也就是'.encode('utf-8')), (None, '就是'.encode('utf-8')), (None, '則是'.encode('utf-8')), (None, '是'.encode('utf-8')), (None, '為'.encode('utf-8'))]))):
        ___2, marker__2 = unpack([_iteration_59], 2)
        if first(method(candidate, b'find', marker__2, 1, True)) == 1:
            after__2 = first(call(M.trim, method(candidate, b'sub', length(marker__2) + 1)))
            if first(call(M.visible_length, after__2)) >= 2:
                candidate = after__2
            break
    if first(call(M.visible_length, candidate)) >= 3:
        candidate = first(method(candidate, b'gsub', '的$'.encode('utf-8'), b''))
    return call(M.trim, candidate)

# Source: scripts/lintlib/core.lua:695
def encode_json_string(text=None, *_ignored):
    replacements = T([(b'\\', b'\\\\'), (b'"', b'\\"'), (b'\x08', b'\\b'), (b'\x0c', b'\\f'), (b'\n', b'\\n'), (b'\r', b'\\r'), (b'\t', b'\\t')])
    return concat(b'"', concat(first(method(text, b'gsub', b'[\\"\x08\x0c\n\r\t]', replacements)), b'"'))

# Source: scripts/lintlib/core.lua:709
def is_array(value=None, *_ignored):
    count = 0
    for _iteration_60 in first(call(pairs, value)):
        key, = unpack([_iteration_60], 1)
        if first(call(type_, key)) != b'number':
            return False
        count = count + 1
    _start_61, _stop_62, _step_63 = (1, count, 1)
    for index in range(int(_start_61), int(_stop_62) + (1 if _step_63 > 0 else -1), int(_step_63)):
        if get(value, index) == None:
            return False
    return True

# Source: scripts/lintlib/core.lua:727
def json_encode(value=None, *_ignored):
    value_type = first(call(type_, value))
    if value_type == b'nil':
        return b'null'
    if value_type == b'boolean':
        return _condition_65 if truth((_condition_65 := (b'true' if truth((_condition_64 := value)) else _condition_64))) else b'false'
    if value_type == b'number':
        return call(tostring, value)
    if value_type == b'string':
        return call(encode_json_string, value)
    if value_type != b'table':
        call(error, concat(b'unsupported json type: ', value_type))
    if truth(first(call(is_array, value))):
        items = T([])
        for _iteration_66 in first(call(ipairs, value)):
            _, item = unpack([_iteration_66], 2)
            call(table.insert, items, call(M.json_encode, item))
        return concat(b'[', concat(first(call(table.concat, items, b',')), b']'))
    keys = T([])
    for _iteration_67 in first(call(pairs, value)):
        key, = unpack([_iteration_67], 1)
        call(table.insert, keys, key)
    call(table.sort, keys)
    fields = T([])
    for _iteration_68 in first(call(ipairs, keys)):
        ___2, key__2 = unpack([_iteration_68], 2)
        call(table.insert, fields, concat(first(call(encode_json_string, call(tostring, key__2))), concat(b':', first(call(M.json_encode, get(value, key__2))))))
    return concat(b'{', concat(first(call(table.concat, fields, b',')), b'}'))
set_(M, b'json_encode', json_encode)

# Source: scripts/lintlib/core.lua:766
def extract_bilingual_pairs(text=None, *_ignored):
    pairs__2 = T([])
    search_from = 1
    while True:
        open_pos = first(method(text, b'find', LEFT_PAREN, search_from, True))
        if not truth(open_pos):
            break
        close_pos = first(method(text, b'find', RIGHT_PAREN, open_pos + length(LEFT_PAREN), True))
        if not truth(close_pos):
            break
        inner = first(call(M.trim, method(text, b'sub', open_pos + length(LEFT_PAREN), close_pos - 1)))
        left = first(call(M.trim, method(text, b'sub', 1, open_pos - 1)))
        outer = first(call(extract_outer_term, left))
        if outer != b'' and inner != b'':
            outer_ascii = first(call(M.contains_ascii_letter, outer))
            inner_ascii = first(call(M.contains_ascii_letter, inner))
            outer_non_ascii = first(call(M.contains_non_ascii, outer))
            inner_non_ascii = first(call(M.contains_non_ascii, inner))
            if truth(outer_ascii) and truth(inner_non_ascii) or (truth(inner_ascii) and truth(outer_non_ascii)):
                english = _condition_70 if truth((_condition_70 := (outer if truth((_condition_69 := outer_ascii)) else _condition_69))) else inner
                chinese = _condition_72 if truth((_condition_72 := (inner if truth((_condition_71 := outer_ascii)) else _condition_71))) else outer
                call(table.insert, pairs__2, T([(b'key', concat(outer, concat(LEFT_PAREN, concat(inner, RIGHT_PAREN)))), (b'outer', outer), (b'inner', inner), (b'english', english), (b'chinese', chinese), (b'col', open_pos)]))
        search_from = close_pos + length(RIGHT_PAREN)
    return pairs__2
set_(M, b'extract_bilingual_pairs', extract_bilingual_pairs)
