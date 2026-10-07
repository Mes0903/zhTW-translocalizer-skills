"""Domain predicates with shared byte-oriented analysis."""
from lintlib.byte_patterns import T, get, set_, truth, first, unpack, call, length, method, string, ipairs
from lintlib.clauses import FULLWIDTH_QUOTE_CLOSERS, SENTENCE_SPACING_CLOSERS, SENTENCE_SPACING_FOLLOWING_PUNCTUATION, SENTENCE_SPACING_PUNCTUATION, add_issue, ascii_token_at, boundary_kind, cjk_internal_space_col, col_in_markdown_link_hidden_span, core, forbids_cjk_cjk_space, fullwidth_parentheses_spacing_col, fullwidth_quote_spacing_col, gap_has_halfwidth_space, halfwidth_parenthetical_in_cjk_context_col, has_inline_final_conjunction, internal_consecutive_space_col, is_ascii_alnum, is_ascii_token_char, is_code_like_ascii_parenthetical, is_markdown_image_line, is_unmasked_char, label_edge_kind, markdown_link_spans, needs_cjk_ascii_space, next_nonspace_item, previous_nonspace_item, prose_lines, punctuation_spacing_lines, should_skip_cjk_ascii_spacing_boundary, strip_terminal_fullwidth_punctuation, terminal_continuation_punctuation_col, text_after_last_plain, text_between_items, title_mark_spacing_col, visible_text_lines

def check_L021(document=None, issues=None, rule=None, *_ignored):
    for _iteration_10001 in first(call(ipairs, document.lines)):
        _, line = unpack([_iteration_10001], 2)
        if ((((not truth(line.is_blank) and (not truth(line.is_code))) and (not truth(line.is_tag))) and (not truth(line.is_heading))) and (not truth(line.is_table))) and (not truth(line.is_blockquote)):
            stripped = first(call(core.trim, line.masked_text))
            if first(method(stripped, b'match', b'^<')) == None:
                count = first(call(core.count_substring, line.masked_text, '；'.encode('utf-8'))) + first(call(core.count_substring, line.masked_text, b';'))
                if count >= 2:
                    pos = _condition_10003 if truth((_condition_10003 := (_condition_10002 if truth((_condition_10002 := first(method(line.masked_text, b'find', '；'.encode('utf-8'), 1, True)))) else first(method(line.masked_text, b'find', b';', 1, True))))) else 1
                    call(add_issue, issues, document, rule, line.number, pos)
                elif count == 1 and first(call(core.visible_length, stripped)) <= 70:
                    pos__2, token = unpack([], 2)
                    if truth(first(method(line.masked_text, b'find', '；'.encode('utf-8'), 1, True))):
                        pos__2 = first(method(line.masked_text, b'find', '；'.encode('utf-8'), 1, True))
                        token = '；'.encode('utf-8')
                    elif truth(first(method(line.masked_text, b'find', b';', 1, True))):
                        pos__2 = first(method(line.masked_text, b'find', b';', 1, True))
                        token = b';'
                    if truth(pos__2) and truth(token):
                        before = first(call(core.trim, method(first(method(line.masked_text, b'sub', 1, pos__2 - 1)), b'gsub', b'^[-*+]%s+', b'')))
                        after = first(call(core.trim, method(line.masked_text, b'sub', pos__2 + length(token))))
                        if first(call(core.visible_length, before)) >= 6 and first(call(core.visible_length, after)) >= 6:
                            call(add_issue, issues, document, rule, line.number, pos__2)

def check_L023(document=None, issues=None, rule=None, *_ignored):
    for _iteration_10004 in first(call(ipairs, call(prose_lines, document))):
        _, line = unpack([_iteration_10004], 2)
        search_from = 1
        while True:
            open_pos = first(method(line.masked_text, b'find', b'"', search_from, True))
            if not truth(open_pos):
                break
            close_pos = first(method(line.masked_text, b'find', b'"', open_pos + 1, True))
            if not truth(close_pos):
                break
            content = first(method(line.masked_text, b'sub', open_pos + 1, close_pos - 1))
            if truth(first(call(core.contains_cjk, content))):
                call(add_issue, issues, document, rule, line.number, open_pos)
                break
            search_from = close_pos + 1

def check_L024(document=None, issues=None, rule=None, *_ignored):
    targets = T([(first(call(string.byte, b',')), True), (first(call(string.byte, b';')), True), (first(call(string.byte, b':')), True)])
    for _iteration_10005 in first(call(ipairs, call(prose_lines, document))):
        _, line = unpack([_iteration_10005], 2)
        codepoints = first(call(core.codepoints, line.masked_text))
        for _iteration_10006 in first(call(ipairs, codepoints)):
            index, item = unpack([_iteration_10006], 2)
            if truth(get(targets, item.cp)):
                prev_item = first(call(core.previous_nonspace, codepoints, index))
                next_item = first(call(core.next_nonspace, codepoints, index))
                surrounded_by_cjk = first(call(core.is_cjk, next_item.cp)) if truth((_condition_10009 := (first(call(core.is_cjk, prev_item.cp)) if truth((_condition_10008 := (next_item if truth((_condition_10007 := prev_item)) else _condition_10007))) else _condition_10008))) else _condition_10009
                colon_after_cjk = not truth(next_item) if truth((_condition_10012 := (first(call(core.is_cjk, prev_item.cp)) if truth((_condition_10011 := (prev_item if truth((_condition_10010 := (item.cp == first(call(string.byte, b':'))))) else _condition_10010))) else _condition_10011))) else _condition_10012
                if truth(surrounded_by_cjk) or truth(colon_after_cjk):
                    call(add_issue, issues, document, rule, line.number, item.pos)
                    break

def check_L025(document=None, issues=None, rule=None, *_ignored):
    for _iteration_10013 in first(call(ipairs, call(prose_lines, document))):
        _, line = unpack([_iteration_10013], 2)
        codepoints = first(call(core.codepoints, line.masked_text))
        link_spans = first(call(markdown_link_spans, line.masked_text))
        for _iteration_10014 in first(call(ipairs, codepoints)):
            index, item = unpack([_iteration_10014], 2)
            if truth(first(call(col_in_markdown_link_hidden_span, link_spans, item.pos))):
                pass
            elif item.cp == first(call(string.byte, b'(')):
                prev_item = get(codepoints, index - 1)
                if truth(prev_item) and truth(first(call(core.is_cjk, prev_item.cp))):
                    call(add_issue, issues, document, rule, line.number, item.pos)
                    break
            elif item.cp == first(call(string.byte, b')')):
                next_item = get(codepoints, index + 1)
                if truth(next_item) and truth(first(call(core.is_cjk, next_item.cp))):
                    call(add_issue, issues, document, rule, line.number, item.pos)
                    break

def check_L026(document=None, issues=None, rule=None, *_ignored):
    for _iteration_10015 in first(call(ipairs, call(prose_lines, document))):
        _, line = unpack([_iteration_10015], 2)
        if not truth(first(call(is_markdown_image_line, line))) and (not truth(first(call(core.contains_cjk, line.masked_text)))):
            bilingual_cols = T([])
            for _iteration_10016 in first(call(ipairs, call(core.extract_bilingual_pairs, line.masked_text))):
                ___2, pair = unpack([_iteration_10016], 2)
                set_(bilingual_cols, pair.col, True)
            search_from = 1
            while True:
                open_pos = first(method(line.masked_text, b'find', '（'.encode('utf-8'), search_from, True))
                if not truth(open_pos):
                    break
                close_pos = first(method(line.masked_text, b'find', '）'.encode('utf-8'), open_pos + 3, True))
                if not truth(close_pos):
                    break
                content = first(method(line.masked_text, b'sub', open_pos + 3, close_pos - 1))
                if truth(first(call(is_code_like_ascii_parenthetical, content))) and (not truth(get(bilingual_cols, open_pos))):
                    call(add_issue, issues, document, rule, line.number, open_pos)
                    break
                search_from = close_pos + 3

def check_L027(document=None, issues=None, rule=None, *_ignored):
    for _iteration_10017 in first(call(ipairs, call(prose_lines, document))):
        _, line = unpack([_iteration_10017], 2)
        if truth(first(method(line.masked_text, b'find', '。%s*$'.encode('utf-8')))):
            call(add_issue, issues, document, rule, line.number, length(line.text))

def check_L028(document=None, issues=None, rule=None, *_ignored):
    dash_patterns = T([(None, '─'.encode('utf-8')), (None, '—'.encode('utf-8')), (None, '–'.encode('utf-8'))])
    for _iteration_10018 in first(call(ipairs, document.lines)):
        _, line = unpack([_iteration_10018], 2)
        if (not truth(line.is_code) and (not truth(line.is_blockquote))) and (not truth(line.is_table)):
            for _iteration_10019 in first(call(ipairs, dash_patterns)):
                ___2, pattern = unpack([_iteration_10019], 2)
                search_from = 1
                while True:
                    col = first(method(line.masked_text, b'find', pattern, search_from, True))
                    if not truth(col):
                        break
                    call(add_issue, issues, document, rule, line.number, col)
                    search_from = col + length(pattern)

def check_L029(document=None, issues=None, rule=None, *_ignored):
    for _iteration_10020 in first(call(ipairs, call(prose_lines, document))):
        _, line = unpack([_iteration_10020], 2)
        if first(call(core.count_substring, line.masked_text, '、'.encode('utf-8'))) >= 2:
            masked_text = first(call(strip_terminal_fullwidth_punctuation, line.masked_text))
            original_text = first(call(strip_terminal_fullwidth_punctuation, line.text))
            suffix = first(call(text_after_last_plain, masked_text, '、'.encode('utf-8')))
            original_suffix = first(call(text_after_last_plain, original_text, '、'.encode('utf-8')))
            has_final_conjunction = _condition_10023 if truth((_condition_10023 := first(call(has_inline_final_conjunction, _condition_10021 if truth((_condition_10021 := suffix)) else b'')))) else first(call(has_inline_final_conjunction, _condition_10022 if truth((_condition_10022 := original_suffix)) else b''))
            if truth(suffix) and (not truth(has_final_conjunction)):
                col = _condition_10024 if truth((_condition_10024 := first(method(line.masked_text, b'find', '、'.encode('utf-8'), 1, True)))) else 1
                call(add_issue, issues, document, rule, line.number, col)

def check_L037(document=None, issues=None, rule=None, *_ignored):
    for _iteration_10025 in first(call(ipairs, call(punctuation_spacing_lines, document))):
        _, line = unpack([_iteration_10025], 2)
        if not truth(first(call(is_markdown_image_line, line))):
            codepoints = first(call(core.codepoints, line.text))
            for _iteration_10026 in first(call(ipairs, codepoints)):
                index, item = unpack([_iteration_10026], 2)
                if truth(get(SENTENCE_SPACING_PUNCTUATION, item.char)) and truth(first(call(is_unmasked_char, line, item))):
                    immediate_next = get(codepoints, index + 1)
                    if not (truth(immediate_next) and truth(get(FULLWIDTH_QUOTE_CLOSERS, immediate_next.char))):
                        cursor = index + 1
                        while truth(get(codepoints, cursor)) and truth(get(SENTENCE_SPACING_CLOSERS, get(codepoints, cursor).char)):
                            cursor = cursor + 1
                        next_item = get(codepoints, cursor)
                        if (truth(next_item) and next_item.char != b' ') and (not truth(get(SENTENCE_SPACING_FOLLOWING_PUNCTUATION, next_item.char))):
                            call(add_issue, issues, document, rule, line.number, item.pos)

def check_L038(document=None, issues=None, rule=None, *_ignored):
    for _iteration_10027 in first(call(ipairs, call(punctuation_spacing_lines, document))):
        _, line = unpack([_iteration_10027], 2)
        if not truth(first(call(is_markdown_image_line, line))):
            codepoints = first(call(core.codepoints, line.masked_text))
            _start_10028, _stop_10029, _step_10030 = (1, length(codepoints) - 1, 1)
            for index in range(int(_start_10028), int(_stop_10029) + (1 if _step_10030 > 0 else -1), int(_step_10030)):
                left = get(codepoints, index)
                right = get(codepoints, index + 1)
                if truth(first(call(core.is_cjk, left.cp))) and truth(first(call(is_ascii_alnum, right.cp))):
                    if not truth(first(call(should_skip_cjk_ascii_spacing_boundary, codepoints, index + 1, index))):
                        call(add_issue, issues, document, rule, line.number, right.pos)
                elif truth(first(call(is_ascii_token_char, left))) and truth(first(call(core.is_cjk, right.cp))):
                    ___2, token_end = unpack([call(ascii_token_at, codepoints, index)], 2)
                    if token_end == index and (not truth(first(call(should_skip_cjk_ascii_spacing_boundary, codepoints, index, index + 1)))):
                        call(add_issue, issues, document, rule, line.number, right.pos)

def check_L040(document=None, issues=None, rule=None, *_ignored):
    for _iteration_10031 in first(call(ipairs, call(punctuation_spacing_lines, document))):
        _, line = unpack([_iteration_10031], 2)
        if not truth(first(call(is_markdown_image_line, line))):
            codepoints = first(call(core.codepoints, line.masked_text))
            for _iteration_10032 in first(call(ipairs, call(markdown_link_spans, line.masked_text))):
                ___2, span = unpack([_iteration_10032], 2)
                first_label_kind = first(call(label_edge_kind, span.label, False))
                last_label_kind = first(call(label_edge_kind, span.label, True))
                prev_item = first(call(previous_nonspace_item, codepoints, span.start_col))
                next_item = first(call(next_nonspace_item, codepoints, span.end_col))
                if truth(prev_item) and truth(first_label_kind):
                    prev_kind = first(call(boundary_kind, prev_item))
                    gap = first(call(text_between_items, line.masked_text, prev_item, span.start_col))
                    has_space = first(call(gap_has_halfwidth_space, gap))
                    if truth(first(call(needs_cjk_ascii_space, prev_kind, first_label_kind))) and (not truth(has_space)):
                        call(add_issue, issues, document, rule, line.number, span.start_col)
                    elif truth(first(call(forbids_cjk_cjk_space, prev_kind, first_label_kind))) and truth(has_space):
                        call(add_issue, issues, document, rule, line.number, span.start_col)
                if truth(next_item) and truth(last_label_kind):
                    next_kind = first(call(boundary_kind, next_item))
                    gap__2 = first(method(line.masked_text, b'sub', span.end_col + 1, next_item.pos - 1))
                    has_space__2 = first(call(gap_has_halfwidth_space, gap__2))
                    if truth(first(call(needs_cjk_ascii_space, last_label_kind, next_kind))) and (not truth(has_space__2)):
                        call(add_issue, issues, document, rule, line.number, span.end_col)
                    elif truth(first(call(forbids_cjk_cjk_space, last_label_kind, next_kind))) and truth(has_space__2):
                        call(add_issue, issues, document, rule, line.number, span.end_col)

def check_L041(document=None, issues=None, rule=None, *_ignored):
    for _iteration_10033 in first(call(ipairs, call(punctuation_spacing_lines, document))):
        _, line = unpack([_iteration_10033], 2)
        if not truth(first(call(is_markdown_image_line, line))):
            codepoints = first(call(core.codepoints, line.text))
            for _iteration_10034 in first(call(ipairs, codepoints)):
                index, item = unpack([_iteration_10034], 2)
                if item.char == '，'.encode('utf-8') and truth(first(call(is_unmasked_char, line, item))):
                    prev_item = get(codepoints, index - 1)
                    next_item = get(codepoints, index + 1)
                    if truth(prev_item) and prev_item.char == b' ' or (truth(next_item) and next_item.char == b' '):
                        call(add_issue, issues, document, rule, line.number, item.pos)

def check_L043(document=None, issues=None, rule=None, *_ignored):
    for _iteration_10035 in first(call(ipairs, call(punctuation_spacing_lines, document))):
        _, line = unpack([_iteration_10035], 2)
        if not truth(first(call(is_markdown_image_line, line))):
            col = first(call(terminal_continuation_punctuation_col, line))
            if truth(col):
                call(add_issue, issues, document, rule, line.number, col)

def check_L044(document=None, issues=None, rule=None, *_ignored):
    checked_lines = T([])
    for _iteration_10036 in first(call(ipairs, document.paragraphs)):
        _, paragraph = unpack([_iteration_10036], 2)
        paragraph_has_cjk = False
        for _iteration_10037 in first(call(ipairs, paragraph.lines)):
            ___2, line = unpack([_iteration_10037], 2)
            if truth(first(call(core.contains_cjk, line.masked_text))):
                paragraph_has_cjk = True
                break
        if truth(paragraph_has_cjk):
            for _iteration_10038 in first(call(ipairs, paragraph.lines)):
                ___3, line__2 = unpack([_iteration_10038], 2)
                set_(checked_lines, line__2.number, True)
                if not truth(line__2.is_table) and (not truth(first(call(is_markdown_image_line, line__2)))):
                    col = first(call(halfwidth_parenthetical_in_cjk_context_col, line__2, True))
                    if truth(col):
                        call(add_issue, issues, document, rule, line__2.number, col)
    for _iteration_10039 in first(call(ipairs, call(visible_text_lines, document))):
        ___4, line__3 = unpack([_iteration_10039], 2)
        if ((not truth(get(checked_lines, line__3.number)) and (not truth(line__3.is_table))) and (not truth(first(call(is_markdown_image_line, line__3))))) and truth(first(call(core.contains_cjk, line__3.masked_text))):
            col__2 = first(call(halfwidth_parenthetical_in_cjk_context_col, line__3, True))
            if truth(col__2):
                call(add_issue, issues, document, rule, line__3.number, col__2)

def check_L045(document=None, issues=None, rule=None, *_ignored):
    for _iteration_10040 in first(call(ipairs, document.lines)):
        _, line = unpack([_iteration_10040], 2)
        if ((((not truth(line.is_blank) and (not truth(line.is_code))) and (not truth(line.is_tag))) and (not truth(line.is_directive))) and (not truth(line.is_table))) and (not truth(first(call(is_markdown_image_line, line)))):
            col = first(call(fullwidth_parentheses_spacing_col, line))
            if truth(col):
                call(add_issue, issues, document, rule, line.number, col)

def check_L047(document=None, issues=None, rule=None, *_ignored):
    for _iteration_10041 in first(call(ipairs, call(visible_text_lines, document))):
        _, line = unpack([_iteration_10041], 2)
        if not truth(first(call(is_markdown_image_line, line))):
            col = first(call(cjk_internal_space_col, line))
            if truth(col):
                call(add_issue, issues, document, rule, line.number, col)

def check_L048(document=None, issues=None, rule=None, *_ignored):
    for _iteration_10042 in first(call(ipairs, call(visible_text_lines, document))):
        _, line = unpack([_iteration_10042], 2)
        if not truth(line.is_table) and (not truth(first(call(is_markdown_image_line, line)))):
            col = first(call(title_mark_spacing_col, line))
            if truth(col):
                call(add_issue, issues, document, rule, line.number, col)

def check_L049(document=None, issues=None, rule=None, *_ignored):
    targets = T([(first(call(string.byte, b'!')), True), (first(call(string.byte, b'?')), True)])
    for _iteration_10043 in first(call(ipairs, call(prose_lines, document))):
        _, line = unpack([_iteration_10043], 2)
        codepoints = first(call(core.codepoints, line.masked_text))
        for _iteration_10044 in first(call(ipairs, codepoints)):
            index, item = unpack([_iteration_10044], 2)
            if truth(get(targets, item.cp)):
                prev_item = first(call(core.previous_nonspace, codepoints, index))
                next_item = first(call(core.next_nonspace, codepoints, index))
                prev_is_cjk = first(call(core.is_cjk, prev_item.cp)) if truth((_condition_10045 := prev_item)) else _condition_10045
                next_is_cjk = first(call(core.is_cjk, next_item.cp)) if truth((_condition_10046 := next_item)) else _condition_10046
                surrounded_by_cjk = next_is_cjk if truth((_condition_10047 := prev_is_cjk)) else _condition_10047
                terminal_after_cjk = not truth(next_item) if truth((_condition_10048 := prev_is_cjk)) else _condition_10048
                if truth(surrounded_by_cjk) or truth(terminal_after_cjk):
                    call(add_issue, issues, document, rule, line.number, item.pos)
                    break

def check_L050(document=None, issues=None, rule=None, *_ignored):
    open_quote = '“'.encode('utf-8')
    close_quote = '”'.encode('utf-8')
    for _iteration_10049 in first(call(ipairs, call(prose_lines, document))):
        _, line = unpack([_iteration_10049], 2)
        search_from = 1
        while True:
            open_pos = first(method(line.masked_text, b'find', open_quote, search_from, True))
            if not truth(open_pos):
                break
            close_pos = first(method(line.masked_text, b'find', close_quote, open_pos + length(open_quote), True))
            if not truth(close_pos):
                break
            content = first(method(line.masked_text, b'sub', open_pos + length(open_quote), close_pos - 1))
            if truth(first(call(core.contains_cjk, content))):
                call(add_issue, issues, document, rule, line.number, open_pos)
                break
            search_from = close_pos + length(close_quote)

def check_L051(document=None, issues=None, rule=None, *_ignored):
    for _iteration_10050 in first(call(ipairs, call(visible_text_lines, document))):
        _, line = unpack([_iteration_10050], 2)
        if not truth(first(call(is_markdown_image_line, line))):
            col = first(call(fullwidth_quote_spacing_col, line))
            if truth(col):
                call(add_issue, issues, document, rule, line.number, col)

def check_L052(document=None, issues=None, rule=None, *_ignored):
    for _iteration_10051 in first(call(ipairs, call(visible_text_lines, document))):
        _, line = unpack([_iteration_10051], 2)
        if (not truth(line.is_table) and (not truth(line.is_blockquote))) and (not truth(first(call(is_markdown_image_line, line)))):
            col = first(call(internal_consecutive_space_col, line))
            if truth(col):
                call(add_issue, issues, document, rule, line.number, col)
from lintlib.rules import run_checks

def check(document: dict, selected: set[str]) -> list[dict]:
    return run_checks(document, selected, CHECKS)
CHECKS = {'L021': check_L021, 'L023': check_L023, 'L024': check_L024, 'L025': check_L025, 'L026': check_L026, 'L027': check_L027, 'L028': check_L028, 'L029': check_L029, 'L037': check_L037, 'L038': check_L038, 'L040': check_L040, 'L041': check_L041, 'L043': check_L043, 'L044': check_L044, 'L045': check_L045, 'L047': check_L047, 'L048': check_L048, 'L049': check_L049, 'L050': check_L050, 'L051': check_L051, 'L052': check_L052}
