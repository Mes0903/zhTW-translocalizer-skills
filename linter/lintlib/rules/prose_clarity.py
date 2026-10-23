"""Bounded review candidates for assurances and article/section openings.

These surface signals cannot establish whether a source or task authorizes a
sentence. They deliberately produce review prompts, never deletion instructions.
"""
import re

from lintlib.byte_patterns import B, first, to_native
from lintlib.clauses import markdown_link_spans
from lintlib.core import byte_to_char_col
from lintlib.registry import load_catalog

ASSURANCE_PATTERNS = tuple(re.compile(pattern) for pattern in (
    r'(?:閱讀|理解|讀者)[^。！？；\n]{0,24}?(?P<signal>不需要|不必|不用|無須)'
    r'(?:再|另外|另行)?(?:離開本文|另開(?:其他|別的)?文件|查閱(?:其他|別的)文件)',
    r'(?P<signal>不要求|不需要|不必|無須)(?:為[^。！？；，\n]{0,16})?'
    r'(?:各自|各|每(?:個|一個)?[^。！？；，\n]{0,8})(?:建|建立)(?:一個)?\s*(?:class\b|類別)',
    r'(?:原本的|原有的|既有的)?(?:文章目錄|使用者(?:的)?修改)[^。！？；\n]{0,24}?'
    r'(?P<signal>沒有|並未|未曾|未|不會)(?:被)?(?:覆寫|覆蓋|更動|改動)',
    r'(?P<signal>沒有|並未|不會|不曾)(?:被)?(?:覆寫|覆蓋|更動|改動)'
    r'(?:原有|既有|原本的?)(?:檔案|文件|文章目錄|使用者修改)',
))
EXAMPLE_PREFIX = re.compile(r'^\s*(?:例如|例句|範例|錯例|原句|改寫前|避免)\s*[：:]')
INLINE_CODE = re.compile(r'(`+)(.*?)\1(?!`)')
GENERIC_PROMPT = re.compile(
    r'(?:我們)?(?:先|讓我們先)(?:看|觀察)(?:一個|一下)?'
    r'(?:可見的|具體的)?(?:事件|例子|案例|現象)[。.!！]?\s*')
ROADMAP_PREFIX = re.compile(r'^(?:本[文章節篇]|這(?:一)?[章節篇]|我們)(?:將|會)?(?:先|從)')
TOPIC_LIST = re.compile(r'[^，。！？；\n]{1,48}、[^，。！？；\n]{1,48}(?:、|與|和|及)[^，。！？；\n]{1,48}')
ROADMAP_ACTION = re.compile(r'介紹|建立|追蹤|比較|理解|討論|說明|用|檢視|探討')
EXCLUDED_FLAGS = ('is_blank', 'is_code', 'is_tag', 'is_directive', 'is_heading',
                  'is_list', 'is_table', 'is_blockquote')
QUOTE_CLOSE = {'「': '」', '『': '』', '“': '”', '‘': '’', '"': '"'}


def _visible_lines(document: dict) -> dict[int, str]:
    """Mask protected text with character-width spaces, retaining locations."""
    result = {}
    quote_stack = []
    in_comment = False
    for line in document['lines']:
        if any(line.get(flag) for flag in EXCLUDED_FLAGS):
            continue
        text = line['text']
        chars = list(text)
        # Reuse the existing destination parser; its offsets count UTF-8 bytes.
        spans = to_native(first(markdown_link_spans(B(text)))) or []
        for span in spans:
            start = byte_to_char_col(text, span['hidden_start_col']) - 1
            end = byte_to_char_col(text, span['end_col'] + 1) - 1
            chars[start:end] = ' ' * (end - start)
        for match in INLINE_CODE.finditer(text):
            chars[match.start():match.end()] = ' ' * (match.end() - match.start())
        # Ignore simple autolinks and reference definitions as destinations too.
        masked = ''.join(chars)
        for match in re.finditer(r'<https?://[^>]+>', masked):
            chars[match.start():match.end()] = ' ' * (match.end() - match.start())
        if re.match(r'^\s*\[[^\]]+\]:\s*\S+', text):
            chars = [' '] * len(text)
        cursor = 0
        while cursor < len(chars):
            tail = ''.join(chars[cursor:cursor + 4])
            if in_comment:
                if ''.join(chars[cursor:cursor + 3]) == '-->':
                    chars[cursor:cursor + 3] = '   '
                    cursor += 3
                    in_comment = False
                else:
                    chars[cursor] = ' '
                    cursor += 1
                continue
            if tail == '<!--':
                chars[cursor:cursor + 4] = '    '
                cursor += 4
                in_comment = True
                continue
            char = chars[cursor]
            if quote_stack and char == quote_stack[-1]:
                quote_stack.pop()
                chars[cursor] = ' '
            elif char in QUOTE_CLOSE:
                quote_stack.append(QUOTE_CLOSE[char])
                chars[cursor] = ' '
            elif quote_stack:
                chars[cursor] = ' '
            cursor += 1
        visible = ''.join(chars)
        if EXAMPLE_PREFIX.match(visible):
            visible = ' ' * len(text)
        result[line['number']] = visible
    return result


def _issue(document: dict, lint_id: str, line: int, col: int) -> dict:
    return {'path': document['path'], 'line': line, 'col': col,
            'lint_id': lint_id, 'message': load_catalog()[lint_id]['warning_message'],
            'severity': 'warning'}


def _assurances(document: dict, visible: dict[int, str]) -> list[dict]:
    issues = []
    reported = set()
    for line, text in visible.items():
        for pattern in ASSURANCE_PATTERNS:
            for match in pattern.finditer(text):
                col = match.start('signal') + 1
                if (line, col) not in reported:
                    reported.add((line, col))
                    issues.append(_issue(document, 'L137', line, col))
    return issues


def _openings(document: dict, visible: dict[int, str]) -> list[dict]:
    issues = []
    headings = [line['number'] for line in document['lines'] if line.get('is_heading')]
    heading_index = 0
    seen_regions = set()
    for paragraph in document['paragraphs']:
        while heading_index < len(headings) and headings[heading_index] < paragraph['start_line']:
            heading_index += 1
        if heading_index in seen_regions:
            continue
        lines = [(line['number'], visible.get(line['number'], '')) for line in paragraph['lines']]
        # Wholly quoted/code/example paragraphs do not establish orientation.
        prose = [(number, text) for number, text in lines if text.strip(' \t\r[]')]
        if not prose:
            continue
        seen_regions.add(heading_index)
        text = '\n'.join(value for _, value in lines).strip()
        first_sentence = re.split(r'[。！？!?]', text, maxsplit=1)[0]
        empty_prompt = GENERIC_PROMPT.fullmatch(first_sentence.strip()) is not None
        itinerary = (ROADMAP_PREFIX.match(first_sentence) is not None
                     and TOPIC_LIST.search(first_sentence) is not None
                     and ROADMAP_ACTION.search(first_sentence) is not None)
        if empty_prompt or itinerary:
            number, first_line = prose[0]
            col = len(first_line) - len(first_line.lstrip()) + 1
            issues.append(_issue(document, 'L138', number, col))
    return issues


def check(document: dict, selected: set[str]) -> list[dict]:
    visible = _visible_lines(document)
    issues = []
    if 'L137' in selected:
        issues.extend(_assurances(document, visible))
    if 'L138' in selected:
        issues.extend(_openings(document, visible))
    return issues
