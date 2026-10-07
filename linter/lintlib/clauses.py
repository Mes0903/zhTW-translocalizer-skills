"""Document classification, glossary forms and byte locations."""
from lintlib.lexicons import load_lexicon
from lintlib.byte_patterns import T, get, set_, truth, first, unpack, call, ret, concat, length, method, string, table, utf8, math, ipairs, tostring
from lintlib.document_views import M as core
M = T([])
SIMPLIFIED_ONLY_CHARACTERS = load_lexicon('SIMPLIFIED_ONLY_CHARACTERS')

def build_simplified_set(*_ignored):
    set = T([])
    for _iteration_1 in first(call(ipairs, SIMPLIFIED_ONLY_CHARACTERS)):
        _, char = unpack([_iteration_1], 2)
        set_(set, first(call(utf8.codepoint, char)), True)
    return set
SIMPLIFIED_CHARS = first(call(build_simplified_set))
is_reference_heading_line = None
bibliography_url_subbullet_is_pure_url = None

def add_issue(issues=None, document=None, rule=None, line=None, col=None, message=None, *_ignored):
    line_text = b''
    if truth(document.lines) and truth(get(document.lines, line)):
        line_text = _condition_2 if truth((_condition_2 := get(document.lines, line).text)) else b''
    call(table.insert, issues, T([(b'path', document.path), (b'lint_id', rule.id), (b'line', line), (b'col', first(call(core.byte_to_char_col, line_text, _condition_3 if truth((_condition_3 := col)) else 1))), (b'message', _condition_4 if truth((_condition_4 := message)) else rule.warning_message), (b'severity', b'warning')]))

def add_file_issue(issues=None, document=None, rule=None, message=None, *_ignored):
    call(add_issue, issues, document, rule, 1, 1, message)

def prose_lines(document=None, *_ignored):
    lines = T([])
    in_references = False
    for _iteration_5 in first(call(ipairs, document.lines)):
        _, line = unpack([_iteration_5], 2)
        if truth(is_reference_heading_line) and truth(first(call(is_reference_heading_line, line))):
            in_references = True
        elif truth(line.is_heading) and truth(in_references):
            in_references = False
        is_reference_explanation = False
        if ((((truth(in_references) and truth(line.is_list)) and (not truth(line.is_code))) and (not truth(line.is_tag))) and (not truth(line.is_table))) and (not truth(line.is_blockquote)):
            subbody = first(method(line.text, b'match', b'^%s%s+%-%s+(.+)$'))
            if ((truth(subbody) and truth(bibliography_url_subbullet_is_pure_url)) and (not truth(first(call(bibliography_url_subbullet_is_pure_url, subbody))))) and truth(first(call(core.contains_cjk, _condition_6 if truth((_condition_6 := line.masked_text)) else subbody))):
                is_reference_explanation = True
        if truth(is_reference_explanation) or ((((((not truth(line.is_blank) and (not truth(line.is_code))) and (not truth(line.is_tag))) and (not truth(line.is_heading))) and (not truth(line.is_list))) and (not truth(line.is_table))) and (not truth(line.is_blockquote))):
            call(table.insert, lines, line)
    return lines

def is_markdown_image_line(line=None, *_ignored):
    stripped = _condition_8 if truth((_condition_8 := line.stripped)) else first(call(core.trim, _condition_7 if truth((_condition_7 := line.text)) else b''))
    return first(method(stripped, b'match', b'^!%[')) != None

def is_top_level_code_fence(line=None, *_ignored):
    return line.list_indent == 0 if truth((_condition_9 := line.is_fence)) else _condition_9

def parse_custom_container_marker(text=None, *_ignored):
    indent, marker, rest = unpack([method(text, b'match', b'^(%s*)(:::+)(.*)$')], 3)
    if not truth(marker):
        return None
    trimmed_rest = first(call(core.trim, rest))
    label = None
    label_tail = b''
    if trimmed_rest != b'':
        label = first(method(trimmed_rest, b'match', b'^([%w_%-]+)'))
        if truth(label):
            label_tail = first(method(trimmed_rest, b'sub', length(label) + 1))
            lowercase_label, attached_title = unpack([method(label, b'match', b'^([a-z][a-z0-9_%-]*)([A-Z].*)$')], 2)
            if truth(lowercase_label) and truth(attached_title):
                label = lowercase_label
                label_tail = concat(attached_title, label_tail)
        else:
            label_tail = trimmed_rest
    return T([(b'indent', indent), (b'marker', marker), (b'marker_len', length(marker)), (b'rest', rest), (b'trimmed_rest', trimmed_rest), (b'label', label), (b'label_tail', label_tail), (b'has_space_after_marker', first(method(rest, b'match', b'^%s+%S')) != None), (b'is_closing', trimmed_rest == b'')])

def is_top_level_custom_container_marker(info=None, *_ignored):
    return length(info.indent) == 0 if truth((_condition_10 := info)) else _condition_10

def is_custom_container_opening_line(line=None, *_ignored):
    if not truth(line):
        return False
    info = first(call(parse_custom_container_marker, line.text))
    return not truth(info.is_closing) if truth((_condition_11 := (info != None))) else _condition_11

def is_custom_container_closing_line(line=None, *_ignored):
    if not truth(line):
        return False
    info = first(call(parse_custom_container_marker, line.text))
    return info.is_closing if truth((_condition_12 := (info != None))) else _condition_12
SENTENCE_SPACING_PUNCTUATION = load_lexicon('SENTENCE_SPACING_PUNCTUATION')
SENTENCE_SPACING_CLOSERS = load_lexicon('SENTENCE_SPACING_CLOSERS')
SENTENCE_SPACING_FOLLOWING_PUNCTUATION = load_lexicon('SENTENCE_SPACING_FOLLOWING_PUNCTUATION')
TITLE_MARK_OPENERS = load_lexicon('TITLE_MARK_OPENERS')
TITLE_MARK_CLOSERS = load_lexicon('TITLE_MARK_CLOSERS')
FULLWIDTH_QUOTE_OPENERS = load_lexicon('FULLWIDTH_QUOTE_OPENERS')
FULLWIDTH_QUOTE_CLOSERS = load_lexicon('FULLWIDTH_QUOTE_CLOSERS')
TERMINAL_CONTINUATION_PUNCTUATION = load_lexicon('TERMINAL_CONTINUATION_PUNCTUATION')
TERMINAL_PUNCTUATION_CLOSERS = load_lexicon('TERMINAL_PUNCTUATION_CLOSERS')

def punctuation_spacing_lines(document=None, *_ignored):
    lines = T([])
    for _iteration_13 in first(call(ipairs, document.lines)):
        _, line = unpack([_iteration_13], 2)
        if (((((not truth(line.is_blank) and (not truth(line.is_code))) and (not truth(line.is_tag))) and (not truth(line.is_directive))) and (not truth(line.is_heading))) and (not truth(line.is_table))) and (not truth(line.is_blockquote)):
            call(table.insert, lines, line)
    return lines

def bilingual_order_lines(document=None, *_ignored):
    lines = T([])
    for _iteration_14 in first(call(ipairs, document.lines)):
        _, line = unpack([_iteration_14], 2)
        if (((not truth(line.is_blank) and (not truth(line.is_code))) and (not truth(line.is_tag))) and (not truth(line.is_directive))) and (not truth(line.is_table)):
            call(table.insert, lines, line)
    return lines

def visible_text_lines(document=None, *_ignored):
    lines = T([])
    for _iteration_15 in first(call(ipairs, document.lines)):
        _, line = unpack([_iteration_15], 2)
        if ((not truth(line.is_blank) and (not truth(line.is_code))) and (not truth(line.is_tag))) and (not truth(line.is_directive)):
            call(table.insert, lines, line)
    return lines

def is_unmasked_char(line=None, item=None, *_ignored):
    return first(method(line.masked_text, b'sub', item.pos, item.pos + length(item.char) - 1)) == item.char

def is_original_char(line=None, item=None, *_ignored):
    return first(method(line.text, b'sub', item.pos, item.pos + length(item.char) - 1)) == item.char

def is_halfwidth_space_item(item=None, *_ignored):
    return first(_condition_16 if truth((_condition_16 := (item.char == b' '))) else item.char == b'\t') if truth((_condition_17 := item)) else _condition_17

def is_ascii_letter(cp=None, *_ignored):
    return _condition_20 if truth((_condition_20 := first(cp <= first(call(string.byte, b'Z')) if truth((_condition_18 := (cp >= first(call(string.byte, b'A'))))) else _condition_18))) else first(cp <= first(call(string.byte, b'z')) if truth((_condition_19 := (cp >= first(call(string.byte, b'a'))))) else _condition_19)

def is_ascii_digit(cp=None, *_ignored):
    return cp <= first(call(string.byte, b'9')) if truth((_condition_21 := (cp >= first(call(string.byte, b'0'))))) else _condition_21

def is_ascii_alnum(cp=None, *_ignored):
    return _condition_22 if truth((_condition_22 := first(call(is_ascii_letter, cp)))) else first(call(is_ascii_digit, cp))

def is_ascii_token_char(item=None, *_ignored):
    if not truth(item) or item.cp > 127:
        return False
    if truth(first(call(is_ascii_alnum, item.cp))):
        return True
    return _condition_31 if truth((_condition_31 := (_condition_30 if truth((_condition_30 := (_condition_29 if truth((_condition_29 := (_condition_28 if truth((_condition_28 := (_condition_27 if truth((_condition_27 := (_condition_26 if truth((_condition_26 := (_condition_25 if truth((_condition_25 := (_condition_24 if truth((_condition_24 := (_condition_23 if truth((_condition_23 := (item.char == b'.'))) else item.char == b'_'))) else item.char == b'-'))) else item.char == b'/'))) else item.char == b'\\'))) else item.char == b':'))) else item.char == b'+'))) else item.char == b'#'))) else item.char == b'@'))) else item.char == b'%'

def ascii_token_at(codepoints=None, index=None, *_ignored):
    start_index = index
    end_index = index
    while start_index > 1 and truth(first(call(is_ascii_token_char, get(codepoints, start_index - 1)))):
        start_index = start_index - 1
    while end_index < length(codepoints) and truth(first(call(is_ascii_token_char, get(codepoints, end_index + 1)))):
        end_index = end_index + 1
    parts = T([])
    _start_32, _stop_33, _step_34 = (start_index, end_index, 1)
    for cursor in range(int(_start_32), int(_stop_33) + (1 if _step_34 > 0 else -1), int(_step_34)):
        call(table.insert, parts, get(codepoints, cursor).char)
    return ret(start_index, end_index, call(table.concat, parts))

def is_codeish_ascii_token(token=None, *_ignored):
    return _condition_39 if truth((_condition_39 := (_condition_38 if truth((_condition_38 := (_condition_37 if truth((_condition_37 := (_condition_36 if truth((_condition_36 := (_condition_35 if truth((_condition_35 := (first(method(token, b'find', b'://', 1, True)) != None))) else first(method(token, b'find', b'/', 1, True)) != None))) else first(method(token, b'find', b'\\', 1, True)) != None))) else first(method(token, b'find', b'@', 1, True)) != None))) else first(method(token, b'find', b'_', 1, True)) != None))) else first(method(token, b'find', b'::', 1, True)) != None

def token_has_ascii_alnum(token=None, *_ignored):
    return first(method(token, b'find', b'[%w]')) != None

def should_skip_cjk_ascii_spacing_boundary(codepoints=None, ascii_index=None, cjk_index=None, *_ignored):
    _, ___2, token = unpack([call(ascii_token_at, codepoints, ascii_index)], 3)
    if token == b'' or not truth(first(call(token_has_ascii_alnum, token))):
        return True
    if truth(first(call(is_codeish_ascii_token, token))):
        return True
    return False

def markdown_link_spans(text=None, *_ignored):
    spans = T([])
    search_from = 1
    while True:
        open_col = first(method(text, b'find', b'%[', search_from))
        if not truth(open_col):
            break
        if open_col > 1 and first(method(text, b'sub', open_col - 1, open_col - 1)) == b'!':
            search_from = open_col + 1
        else:
            bracket_depth = 1
            cursor = open_col + 1
            close_col = None
            while cursor <= length(text):
                char = first(method(text, b'sub', cursor, cursor))
                if char == b'[':
                    bracket_depth = bracket_depth + 1
                elif char == b']':
                    bracket_depth = bracket_depth - 1
                    if bracket_depth == 0:
                        close_col = cursor
                        break
                cursor = cursor + 1
            if not truth(close_col):
                break
            if first(method(text, b'sub', close_col + 1, close_col + 1)) == b'(':
                paren_depth = 1
                cursor = close_col + 2
                end_col = None
                while cursor <= length(text):
                    char__2 = first(method(text, b'sub', cursor, cursor))
                    if char__2 == b'(':
                        paren_depth = paren_depth + 1
                    elif char__2 == b')':
                        paren_depth = paren_depth - 1
                        if paren_depth == 0:
                            end_col = cursor
                            break
                    cursor = cursor + 1
                if not truth(end_col):
                    break
                call(table.insert, spans, T([(b'start_col', open_col), (b'end_col', end_col), (b'hidden_start_col', close_col + 1), (b'url_start_col', close_col + 2), (b'url_end_col', end_col - 1), (b'url', first(method(text, b'sub', close_col + 2, end_col - 1))), (b'label', first(method(text, b'sub', open_col + 1, close_col - 1)))]))
                search_from = end_col + 1
            else:
                search_from = close_col + 1
    return spans

def col_in_markdown_link_hidden_span(spans=None, col=None, *_ignored):
    for _iteration_40 in first(call(ipairs, spans)):
        _, span = unpack([_iteration_40], 2)
        if (truth(span.hidden_start_col) and col >= span.hidden_start_col) and col <= span.end_col:
            return True
    return False

def inline_math_spans(text=None, *_ignored):
    spans = T([])
    cursor = 1
    while cursor <= length(text):
        start_col = first(method(text, b'find', b'$', cursor, True))
        if not truth(start_col):
            break
        if first(method(text, b'sub', start_col, start_col + 1)) == b'$$':
            cursor = start_col + 2
        elif start_col > 1 and first(method(text, b'sub', start_col - 1, start_col - 1)) == b'\\':
            cursor = start_col + 1
        else:
            end_col = first(method(text, b'find', b'$', start_col + 1, True))
            while (truth(end_col) and end_col > 1) and first(method(text, b'sub', end_col - 1, end_col - 1)) == b'\\':
                end_col = first(method(text, b'find', b'$', end_col + 1, True))
            if not truth(end_col):
                break
            call(table.insert, spans, T([(b'start_col', start_col), (b'end_col', end_col)]))
            cursor = end_col + 1
    return spans

def inline_code_spans(text=None, *_ignored):
    spans = T([])
    cursor = 1
    while cursor <= length(text):
        start_col = first(method(text, b'find', b'`', cursor, True))
        if not truth(start_col):
            break
        end_col = first(method(text, b'find', b'`', start_col + 1, True))
        if not truth(end_col):
            break
        call(table.insert, spans, T([(b'start_col', start_col), (b'end_col', end_col)]))
        cursor = end_col + 1
    return spans

def col_in_spans(spans=None, col=None, *_ignored):
    for _iteration_41 in first(call(ipairs, spans)):
        _, span = unpack([_iteration_41], 2)
        if col >= span.start_col and col <= span.end_col:
            return True
    return False

def find_matching_halfwidth_parenthesis(text=None, open_pos=None, *_ignored):
    depth = 1
    cursor = open_pos + 1
    while cursor <= length(text):
        char = first(method(text, b'sub', cursor, cursor))
        if char == b'(':
            depth = depth + 1
        elif char == b')':
            depth = depth - 1
            if depth == 0:
                return cursor
        cursor = cursor + 1
    return None

def ascii_word_count(text=None, *_ignored):
    count = 0
    for _iteration_42 in first(method(text, b'gmatch', b'%a[%a%-]*')):
        _, = unpack([_iteration_42], 1)
        count = count + 1
    return count

def is_ascii_parenthetical_prose(text=None, *_ignored):
    content = first(call(core.trim, text))
    if (content == b'' or truth(first(call(core.contains_non_ascii, content)))) or not truth(first(method(content, b'find', b'%a'))):
        return False
    if first(call(ascii_word_count, content)) < 2:
        return False
    if truth(first(method(content, b'find', b'[,;:%[%]{}<>=+*/\\|_]'))):
        return False
    if (truth(first(method(content, b'find', b'%d'))) or truth(first(method(content, b'find', b'https?://')))) or truth(first(method(content, b'find', b'%S+%.%S+'))):
        return False
    return True

def is_code_like_ascii_parenthetical(text=None, *_ignored):
    content = first(call(core.trim, text))
    if content == b'' or truth(first(call(core.contains_non_ascii, content))):
        return False
    if truth(first(call(is_ascii_parenthetical_prose, content))):
        return False
    if truth(first(method(content, b'find', b'[%s]'))):
        return False
    return first(method(content, b'find', b'[%d_%+%-%*%/%=<>:%[%]{}%.]')) != None

def ascii_char_before(text=None, pos=None, *_ignored):
    if pos <= 1:
        return None
    return method(text, b'sub', pos - 1, pos - 1)

def is_ascii_identifier_char(char=None, *_ignored):
    return first(method(char, b'match', b'[%w_]')) != None if truth((_condition_43 := (char != None))) else _condition_43

def is_function_call_parentheses(text=None, open_pos=None, content=None, *_ignored):
    prev_char = first(call(ascii_char_before, text, open_pos))
    if not truth(first(call(is_ascii_identifier_char, prev_char))):
        return False
    trimmed = first(call(core.trim, content))
    if trimmed == b'':
        return True
    if truth(first(method(trimmed, b'find', b'[,=]'))):
        return True
    if truth(first(method(trimmed, b'find', b'^[_%a][_%w%.:]*$'))):
        return True
    return False

def is_halfwidth_parenthetical_allowed_in_cjk_context(text=None, open_pos=None, content=None, *_ignored):
    trimmed = first(call(core.trim, content))
    if trimmed == b'':
        return True
    is_standalone_url = not truth(first(method(trimmed, b'find', b'%s'))) if truth((_condition_46 := first(_condition_45 if truth((_condition_45 := (_condition_44 if truth((_condition_44 := first(method(trimmed, b'find', b'^https://')))) else first(method(trimmed, b'find', b'^http://'))))) else first(method(trimmed, b'find', b'^www%.'))))) else _condition_46
    if truth(is_standalone_url):
        return True
    return call(is_function_call_parentheses, text, open_pos, content)

def halfwidth_parenthetical_in_cjk_context_col(line=None, has_cjk_context=None, *_ignored):
    if not truth(has_cjk_context):
        return None
    link_spans = first(call(markdown_link_spans, line.masked_text))
    math_spans = first(call(inline_math_spans, line.masked_text))
    search_from = 1
    while True:
        open_pos = first(method(line.masked_text, b'find', b'(', search_from, True))
        if not truth(open_pos):
            break
        if truth(first(call(col_in_markdown_link_hidden_span, link_spans, open_pos))) or truth(first(call(col_in_spans, math_spans, open_pos))):
            search_from = open_pos + 1
        else:
            close_pos = first(call(find_matching_halfwidth_parenthesis, line.masked_text, open_pos))
            if not truth(close_pos):
                break
            if not truth(first(call(col_in_markdown_link_hidden_span, link_spans, close_pos))) and (not truth(first(call(col_in_spans, math_spans, close_pos)))):
                content = first(method(line.masked_text, b'sub', open_pos + 1, close_pos - 1))
                if not truth(first(call(is_halfwidth_parenthetical_allowed_in_cjk_context, line.masked_text, open_pos, content))):
                    return open_pos
            search_from = close_pos + 1
    return None

def fullwidth_parentheses_spacing_col(line=None, *_ignored):
    if not truth(first(call(core.contains_cjk, line.masked_text))):
        return None
    codepoints = first(call(core.codepoints, line.masked_text))
    for _iteration_47 in first(call(ipairs, codepoints)):
        index, item = unpack([_iteration_47], 2)
        if truth(first(call(is_unmasked_char, line, item))):
            if item.char == '（'.encode('utf-8'):
                prev_item = get(codepoints, index - 1)
                prev_nonspace = first(call(core.previous_nonspace, codepoints, index))
                if ((truth(prev_item) and prev_item.char == b' ') and first(method(line.text, b'sub', prev_item.pos, prev_item.pos)) == b' ') and (not (truth(prev_nonspace) and truth(get(SENTENCE_SPACING_PUNCTUATION, prev_nonspace.char)))):
                    return prev_item.pos
            elif item.char == '）'.encode('utf-8'):
                prev_item__2 = get(codepoints, index - 1)
                next_item = get(codepoints, index + 1)
                if ((truth(next_item) and next_item.char == b' ') and first(method(line.text, b'sub', next_item.pos, next_item.pos)) == b' ') and (not (truth(prev_item__2) and truth(get(SENTENCE_SPACING_PUNCTUATION, prev_item__2.char)))):
                    return next_item.pos
    return None

def cjk_internal_space_col(line=None, *_ignored):
    link_spans = first(call(markdown_link_spans, line.masked_text))
    math_spans = first(call(inline_math_spans, line.masked_text))
    codepoints = first(call(core.codepoints, line.masked_text))

    def is_hidden_or_math(item=None, *_ignored):
        return _condition_48 if truth((_condition_48 := first(call(col_in_markdown_link_hidden_span, link_spans, item.pos)))) else first(call(col_in_spans, math_spans, item.pos))
    _start_49, _stop_50, _step_51 = (1, length(codepoints) - 2, 1)
    for index in range(int(_start_49), int(_stop_50) + (1 if _step_51 > 0 else -1), int(_step_51)):
        left = get(codepoints, index)
        if truth(first(call(core.is_cjk, left.cp))) and (not truth(first(call(is_hidden_or_math, left)))):
            cursor = index + 1
            first_space = None
            valid_gap = False
            while cursor <= length(codepoints) and truth(first(call(is_halfwidth_space_item, get(codepoints, cursor)))):
                space = get(codepoints, cursor)
                if truth(first(call(is_hidden_or_math, space))) or not truth(first(call(is_original_char, line, space))):
                    valid_gap = False
                    first_space = None
                    break
                first_space = _condition_52 if truth((_condition_52 := first_space)) else space
                valid_gap = True
                cursor = cursor + 1
            right = get(codepoints, cursor)
            if ((truth(valid_gap) and truth(right)) and truth(first(call(core.is_cjk, right.cp)))) and (not truth(first(call(is_hidden_or_math, right)))):
                return first_space.pos
    return None

def terminal_continuation_punctuation_col(line=None, *_ignored):
    if not truth(first(call(core.contains_cjk, line.masked_text))):
        return None
    link_spans = first(call(markdown_link_spans, line.masked_text))
    codepoints = first(call(core.codepoints, line.text))
    _start_53, _stop_54, _step_55 = (length(codepoints), 1, -1)
    for index in range(int(_start_53), int(_stop_54) + (1 if _step_55 > 0 else -1), int(_step_55)):
        item = get(codepoints, index)
        if truth(first(method(item.char, b'match', b'%s'))):
            pass
        elif truth(first(call(col_in_markdown_link_hidden_span, link_spans, item.pos))):
            pass
        elif not truth(first(call(is_unmasked_char, line, item))):
            return None
        elif truth(get(TERMINAL_PUNCTUATION_CLOSERS, item.char)):
            pass
        elif truth(get(TERMINAL_CONTINUATION_PUNCTUATION, item.char)):
            return item.pos
        else:
            return None
    return None
TRACKING_QUERY_PARAMS = load_lexicon('TRACKING_QUERY_PARAMS')

def is_tracking_query_param(name=None, *_ignored):
    lowered = first(method(first(call(tostring, _condition_56 if truth((_condition_56 := name)) else b'')), b'lower'))
    return _condition_57 if truth((_condition_57 := (first(method(lowered, b'match', b'^utm_')) != None))) else get(TRACKING_QUERY_PARAMS, lowered) == True

def markdown_link_url_has_tracking_param(url=None, *_ignored):
    without_fragment = _condition_59 if truth((_condition_59 := first(method(first(call(tostring, _condition_58 if truth((_condition_58 := url)) else b'')), b'match', b'^([^#]*)')))) else b''
    query = first(method(without_fragment, b'match', b'%?(.+)$'))
    if not truth(query):
        return False
    for _iteration_60 in first(method(query, b'gmatch', b'[^&;]+')):
        raw_param, = unpack([_iteration_60], 1)
        name = _condition_61 if truth((_condition_61 := first(method(raw_param, b'match', b'^([^=]*)')))) else b''
        if truth(first(call(is_tracking_query_param, name))):
            return True
    return False

def boundary_kind(item=None, *_ignored):
    if not truth(item):
        return None
    if truth(first(call(core.is_cjk, item.cp))):
        return b'cjk'
    if truth(first(call(is_ascii_token_char, item))) and truth(first(call(token_has_ascii_alnum, item.char))):
        return b'ascii'
    if item.char == b'+' or item.char == b'#':
        return b'ascii'
    return None

def label_edge_kind(label=None, from_end=None, *_ignored):
    codepoints = first(call(core.codepoints, label))
    start_index = _condition_63 if truth((_condition_63 := (length(codepoints) if truth((_condition_62 := from_end)) else _condition_62))) else 1
    end_index = _condition_65 if truth((_condition_65 := (1 if truth((_condition_64 := from_end)) else _condition_64))) else length(codepoints)
    step = _condition_67 if truth((_condition_67 := (-1 if truth((_condition_66 := from_end)) else _condition_66))) else 1
    _start_68, _stop_69, _step_70 = (start_index, end_index, step)
    for index in range(int(_start_68), int(_stop_69) + (1 if _step_70 > 0 else -1), int(_step_70)):
        kind = first(call(boundary_kind, get(codepoints, index)))
        if truth(kind):
            return kind
    return None

def previous_nonspace_item(codepoints=None, before_col=None, *_ignored):
    _start_71, _stop_72, _step_73 = (length(codepoints), 1, -1)
    for index in range(int(_start_71), int(_stop_72) + (1 if _step_73 > 0 else -1), int(_step_73)):
        item = get(codepoints, index)
        if item.pos < before_col and (not truth(first(method(item.char, b'match', b'%s')))):
            return item
    return None

def next_nonspace_item(codepoints=None, after_col=None, *_ignored):
    for _iteration_74 in first(call(ipairs, codepoints)):
        _, item = unpack([_iteration_74], 2)
        if item.pos > after_col and (not truth(first(method(item.char, b'match', b'%s')))):
            return item
    return None

def text_between_items(text=None, left_item=None, right_col=None, *_ignored):
    if not truth(left_item):
        return b''
    return method(text, b'sub', left_item.pos + length(left_item.char), right_col - 1)

def gap_has_halfwidth_space(text=None, *_ignored):
    return first(method(text, b'find', b' ', 1, True)) != None

def needs_cjk_ascii_space(left_kind=None, right_kind=None, *_ignored):
    return _condition_77 if truth((_condition_77 := first(right_kind == b'ascii' if truth((_condition_75 := (left_kind == b'cjk'))) else _condition_75))) else first(right_kind == b'cjk' if truth((_condition_76 := (left_kind == b'ascii'))) else _condition_76)

def forbids_cjk_cjk_space(left_kind=None, right_kind=None, *_ignored):
    return right_kind == b'cjk' if truth((_condition_78 := (left_kind == b'cjk'))) else _condition_78

def title_mark_label_edge(label=None, from_end=None, *_ignored):
    codepoints = first(call(core.codepoints, label))
    start_index = _condition_80 if truth((_condition_80 := (length(codepoints) if truth((_condition_79 := from_end)) else _condition_79))) else 1
    end_index = _condition_82 if truth((_condition_82 := (1 if truth((_condition_81 := from_end)) else _condition_81))) else length(codepoints)
    step = _condition_84 if truth((_condition_84 := (-1 if truth((_condition_83 := from_end)) else _condition_83))) else 1
    _start_85, _stop_86, _step_87 = (start_index, end_index, step)
    for index in range(int(_start_85), int(_stop_86) + (1 if _step_87 > 0 else -1), int(_step_87)):
        item = get(codepoints, index)
        if not truth(first(method(item.char, b'match', b'%s'))):
            return item.char
    return None

def is_markdown_prefix_before_col(text=None, col=None, *_ignored):
    before = first(call(core.trim, method(text, b'sub', 1, col - 1)))
    return _condition_90 if truth((_condition_90 := (_condition_89 if truth((_condition_89 := (_condition_88 if truth((_condition_88 := (first(method(before, b'match', b'^#+$')) != None))) else first(method(before, b'match', b'^[-*+]$')) != None))) else first(method(before, b'match', b'^%d+%.$')) != None))) else before == b'>'

def fullwidth_quote_spacing_col(line=None, *_ignored):
    link_spans = first(call(markdown_link_spans, line.masked_text))
    math_spans = first(call(inline_math_spans, line.masked_text))
    code_spans = first(call(inline_code_spans, line.text))
    codepoints = first(call(core.codepoints, line.text))

    def is_hidden_or_math_or_code(item=None, *_ignored):
        return _condition_92 if truth((_condition_92 := (_condition_91 if truth((_condition_91 := first(call(col_in_markdown_link_hidden_span, link_spans, item.pos)))) else first(call(col_in_spans, math_spans, item.pos))))) else first(call(col_in_spans, code_spans, item.pos))
    for _iteration_93 in first(call(ipairs, codepoints)):
        index, item = unpack([_iteration_93], 2)
        if (truth(get(FULLWIDTH_QUOTE_OPENERS, item.char)) or truth(get(FULLWIDTH_QUOTE_CLOSERS, item.char))) and (not truth(first(call(is_hidden_or_math_or_code, item)))):
            prev_item = get(codepoints, index - 1)
            next_item = get(codepoints, index + 1)
            if truth(get(FULLWIDTH_QUOTE_OPENERS, item.char)):
                if (truth(first(call(is_halfwidth_space_item, prev_item))) and truth(first(call(is_original_char, line, prev_item)))) and (not truth(first(call(is_markdown_prefix_before_col, line.text, prev_item.pos)))):
                    prev_nonspace = first(call(core.previous_nonspace, codepoints, index))
                    if truth(prev_nonspace):
                        return prev_item.pos
                if truth(first(call(is_halfwidth_space_item, next_item))) and truth(first(call(is_original_char, line, next_item))):
                    return next_item.pos
            elif truth(get(FULLWIDTH_QUOTE_CLOSERS, item.char)):
                if truth(first(call(is_halfwidth_space_item, prev_item))) and truth(first(call(is_original_char, line, prev_item))):
                    return prev_item.pos
                if truth(first(call(is_halfwidth_space_item, next_item))) and truth(first(call(is_original_char, line, next_item))):
                    next_nonspace = first(call(core.next_nonspace, codepoints, index))
                    if truth(next_nonspace):
                        return next_item.pos
    return None

def title_mark_direct_spacing_col(line=None, *_ignored):
    codepoints = first(call(core.codepoints, line.masked_text))
    for _iteration_94 in first(call(ipairs, codepoints)):
        index, item = unpack([_iteration_94], 2)
        if truth(get(TITLE_MARK_OPENERS, item.char)) and truth(first(call(is_unmasked_char, line, item))):
            prev_item = get(codepoints, index - 1)
            next_item = get(codepoints, index + 1)
            if (truth(first(call(is_halfwidth_space_item, prev_item))) and truth(first(call(is_original_char, line, prev_item)))) and (not truth(first(call(is_markdown_prefix_before_col, line.masked_text, prev_item.pos)))):
                return prev_item.pos
            if truth(first(call(is_halfwidth_space_item, next_item))) and truth(first(call(is_original_char, line, next_item))):
                return next_item.pos
        elif truth(get(TITLE_MARK_CLOSERS, item.char)) and truth(first(call(is_unmasked_char, line, item))):
            prev_item__2 = get(codepoints, index - 1)
            next_item__2 = get(codepoints, index + 1)
            if truth(first(call(is_halfwidth_space_item, prev_item__2))) and truth(first(call(is_original_char, line, prev_item__2))):
                return prev_item__2.pos
            if truth(first(call(is_halfwidth_space_item, next_item__2))) and truth(first(call(is_original_char, line, next_item__2))):
                next_nonspace = first(call(core.next_nonspace, codepoints, index))
                if truth(next_nonspace):
                    return next_item__2.pos
    return None

def title_mark_markdown_link_edge_spacing_col(line=None, *_ignored):
    codepoints = first(call(core.codepoints, line.masked_text))
    for _iteration_95 in first(call(ipairs, call(markdown_link_spans, line.masked_text))):
        _, span = unpack([_iteration_95], 2)
        first_label_char = first(call(title_mark_label_edge, span.label, False))
        if truth(get(TITLE_MARK_OPENERS, first_label_char)):
            prev_item = first(call(previous_nonspace_item, codepoints, span.start_col))
            if truth(prev_item):
                gap = first(call(text_between_items, line.masked_text, prev_item, span.start_col))
                if truth(first(call(gap_has_halfwidth_space, gap))) and (not truth(first(call(is_markdown_prefix_before_col, line.masked_text, span.start_col)))):
                    return span.start_col
        last_label_char = first(call(title_mark_label_edge, span.label, True))
        if truth(get(TITLE_MARK_CLOSERS, last_label_char)):
            next_item = first(call(next_nonspace_item, codepoints, span.end_col))
            if truth(next_item):
                gap__2 = first(method(line.masked_text, b'sub', span.end_col + 1, next_item.pos - 1))
                if truth(first(call(gap_has_halfwidth_space, gap__2))):
                    return span.end_col
    return None

def title_mark_spacing_col(line=None, *_ignored):
    return _condition_96 if truth((_condition_96 := first(call(title_mark_direct_spacing_col, line)))) else first(call(title_mark_markdown_link_edge_spacing_col, line))

def internal_consecutive_space_col(line=None, *_ignored):
    link_spans = first(call(markdown_link_spans, line.masked_text))
    math_spans = first(call(inline_math_spans, line.masked_text))
    code_spans = first(call(inline_code_spans, line.text))
    codepoints = first(call(core.codepoints, line.text))

    def is_hidden_or_math_or_code(item=None, *_ignored):
        return _condition_98 if truth((_condition_98 := (_condition_97 if truth((_condition_97 := first(call(col_in_markdown_link_hidden_span, link_spans, item.pos)))) else first(call(col_in_spans, math_spans, item.pos))))) else first(call(col_in_spans, code_spans, item.pos))
    _start_99, _stop_100, _step_101 = (1, length(codepoints) - 1, 1)
    for index in range(int(_start_99), int(_stop_100) + (1 if _step_101 > 0 else -1), int(_step_101)):
        first__2 = get(codepoints, index)
        second = get(codepoints, index + 1)
        if ((((first__2.char == b' ' and second.char == b' ') and truth(first(call(is_original_char, line, first__2)))) and truth(first(call(is_original_char, line, second)))) and (not truth(first(call(is_hidden_or_math_or_code, first__2))))) and (not truth(first(call(is_hidden_or_math_or_code, second)))):
            prev_nonspace = first(call(core.previous_nonspace, codepoints, index))
            next_nonspace = first(call(core.next_nonspace, codepoints, index + 1))
            if truth(prev_nonspace) and truth(next_nonspace):
                return first__2.pos
    return None

def _callback_102(line=None, *_ignored):
    return first(_condition_104 if truth((_condition_104 := first(method(line.stripped, b'match', '^##%s+引用文獻$'.encode('utf-8'))))) else first(method(line.stripped, b'match', b'^##%s+References$'))) if truth((_condition_105 := (line.is_heading if truth((_condition_103 := line)) else _condition_103))) else _condition_105
is_reference_heading_line = _callback_102

def has_reference_heading(document=None, *_ignored):
    for _iteration_106 in first(call(ipairs, document.lines)):
        _, line = unpack([_iteration_106], 2)
        if truth(first(call(is_reference_heading_line, line))):
            return True
    return False
BIBLIOGRAPHY_URL_LEADS = load_lexicon('BIBLIOGRAPHY_URL_LEADS')

def parse_reference_entry_line(text=None, *_ignored):
    anchor_id, label, body = unpack([method(text, b'match', b'^%- %s*<a id="([^"]+)">%[([^%]]+)%]</a>%s*:?[ \t]*(.+)$')], 3)
    if truth(anchor_id):
        return T([(b'anchor_id', anchor_id), (b'label', label), (b'body', body)])
    _assignment_107 = unpack([method(text, b'match', b'^%- %s*%[([^%]]+)%]%s*:?[ \t]*(.+)$')], 2)
    label = _assignment_107[0]
    body = _assignment_107[1]
    if truth(label):
        return T([(b'anchor_id', None), (b'label', label), (b'body', body)])
    return None

def bibliography_section_lines(document=None, *_ignored):
    entries = T([])
    subbullets = T([])
    in_references = False
    for _iteration_108 in first(call(ipairs, document.lines)):
        _, line = unpack([_iteration_108], 2)
        if truth(first(call(is_reference_heading_line, line))):
            in_references = True
        elif truth(line.is_heading) and truth(in_references):
            in_references = False
        elif (((truth(in_references) and (not truth(line.is_code))) and (not truth(line.is_tag))) and (not truth(line.is_table))) and (not truth(line.is_blockquote)):
            entry = first(call(parse_reference_entry_line, line.text))
            if truth(entry):
                set_(entry, b'line', line)
                call(table.insert, entries, entry)
            subbody = first(method(line.text, b'match', b'^%s%s+%-%s+(.+)$'))
            if truth(subbody):
                call(table.insert, subbullets, T([(b'line', line), (b'body', subbody)]))
    return ret(entries, subbullets)

def bibliography_has_url(text=None, *_ignored):
    return _condition_110 if truth((_condition_110 := (_condition_109 if truth((_condition_109 := (first(method(text, b'match', b'https?://')) != None))) else first(method(text, b'match', b'ftp://')) != None))) else first(method(text, b'match', b'www%.')) != None

def _callback_111(text=None, *_ignored):
    trimmed = first(method(first(call(core.trim, text)), b'gsub', b'\\~', b'~'))
    for _iteration_112 in first(call(ipairs, BIBLIOGRAPHY_URL_LEADS)):
        _, lead = unpack([_iteration_112], 2)
        if first(method(trimmed, b'sub', 1, length(lead))) == lead:
            return False
    if truth(first(call(core.contains_cjk, trimmed))):
        return False
    compact = first(method(trimmed, b'gsub', b'%s+', b''))
    return _condition_114 if truth((_condition_114 := (_condition_113 if truth((_condition_113 := (first(method(compact, b'match', b'^(https?://%S+)$')) != None))) else first(method(compact, b'match', b'^(ftp://%S+)$')) != None))) else first(method(compact, b'match', b'^(www%.%S+)$')) != None
bibliography_url_subbullet_is_pure_url = _callback_111

def bibliography_explanation_subbullets(document=None, *_ignored):
    _, subbullets = unpack([call(bibliography_section_lines, document)], 2)
    explanation_lines = T([])
    for _iteration_115 in first(call(ipairs, subbullets)):
        ___2, item = unpack([_iteration_115], 2)
        if not truth(first(call(bibliography_url_subbullet_is_pure_url, item.body))) and truth(first(call(core.contains_cjk, _condition_116 if truth((_condition_116 := item.line.masked_text)) else item.body))):
            call(table.insert, explanation_lines, item)
    return explanation_lines

def formal_citation_links(text=None, *_ignored):
    links = T([])
    for _iteration_118 in first(method(first(call(tostring, _condition_117 if truth((_condition_117 := text)) else b'')), b'gmatch', b'<sup>(.-)</sup>')):
        sup_body, = unpack([_iteration_118], 1)
        for _iteration_119 in first(method(sup_body, b'gmatch', b'%[%[([^%]]+)%]%]%(%#([^)]+)%)')):
            label, target = unpack([_iteration_119], 2)
            call(table.insert, links, T([(b'label', label), (b'target', target)]))
    return links
WORKSPACE_JARGON = load_lexicon('WORKSPACE_JARGON')
INTERNAL_CONTROL_LABELS = load_lexicon('INTERNAL_CONTROL_LABELS')
INTERNAL_CONTROL_LABELS_CASE_INSENSITIVE = load_lexicon('INTERNAL_CONTROL_LABELS_CASE_INSENSITIVE')
HUIXIE_TERM_SUFFIXES = load_lexicon('HUIXIE_TERM_SUFFIXES')
HUIXIE_TERM_PREFIXES = load_lexicon('HUIXIE_TERM_PREFIXES')
ABSTRACT_TAXONOMY_TERMS = load_lexicon('ABSTRACT_TAXONOMY_TERMS')
CLAUSE_BOUNDARIES = load_lexicon('CLAUSE_BOUNDARIES')
COMPLETION_EVENT_VERBS = load_lexicon('COMPLETION_EVENT_VERBS')
GENERIC_YOU_VERBS = load_lexicon('GENERIC_YOU_VERBS')
COUNT_PREFIXES = load_lexicon('COUNT_PREFIXES')
COUNT_CLASSIFIERS = load_lexicon('COUNT_CLASSIFIERS')
REPEATED_SUBJECT_HEADS = load_lexicon('REPEATED_SUBJECT_HEADS')
BA_RESULT_MARKERS = load_lexicon('BA_RESULT_MARKERS')
BARE_BA_VERBS = load_lexicon('BARE_BA_VERBS')
ABSTRACT_EVENT_NOUNS = load_lexicon('ABSTRACT_EVENT_NOUNS')
DEFINITE_MARKERS = load_lexicon('DEFINITE_MARKERS')
NONAGENTIVE_SUBJECTS = load_lexicon('NONAGENTIVE_SUBJECTS')
CONTROL_MODALS = load_lexicon('CONTROL_MODALS')
HIGH_RISK_MISSING_DE_PHRASES = load_lexicon('HIGH_RISK_MISSING_DE_PHRASES')
HIGH_RISK_MISSING_DI_PHRASES = load_lexicon('HIGH_RISK_MISSING_DI_PHRASES')
HIGH_RISK_MISSING_COMPLEMENT_DE = load_lexicon('HIGH_RISK_MISSING_COMPLEMENT_DE')
SHOU_BARE_EVENT_VERBS = load_lexicon('SHOU_BARE_EVENT_VERBS')
DESCRIPTION_OBJECTS = load_lexicon('DESCRIPTION_OBJECTS')
DEGREE_MARKERS = load_lexicon('DEGREE_MARKERS')
OVERLOADED_POSTVERBAL_VERBS = load_lexicon('OVERLOADED_POSTVERBAL_VERBS')
DURATION_OR_COUNT_MARKERS = load_lexicon('DURATION_OR_COUNT_MARKERS')
EVENT_NOMINALIZATION_TAIL_MARKERS = load_lexicon('EVENT_NOMINALIZATION_TAIL_MARKERS')
GLOSSARY_PREFIX_FALLBACK_MARKERS = load_lexicon('GLOSSARY_PREFIX_FALLBACK_MARKERS')

def matches_glossary_preferred_form(entry=None, chinese=None, *_ignored):
    if not truth(entry) or chinese == b'':
        return False
    if truth(get(entry.preferred_set, chinese)):
        return True
    for _iteration_120 in first(call(ipairs, GLOSSARY_PREFIX_FALLBACK_MARKERS)):
        _, marker = unpack([_iteration_120], 2)
        search_from = 1
        while True:
            found = first(method(chinese, b'find', marker, search_from, True))
            if not truth(found):
                break
            before = first(call(core.trim, method(chinese, b'sub', 1, found - 1)))
            after = first(call(core.trim, method(chinese, b'sub', found + length(marker))))
            if (first(call(core.visible_length, before)) >= 2 and first(call(core.visible_length, after)) >= 2) and truth(get(entry.preferred_set, after)):
                return True
            search_from = found + length(marker)
    return False

def has_expansion_signal(text=None, *_ignored):
    patterns = T([(None, '指的是'.encode('utf-8')), (None, '也就是'.encode('utf-8')), (None, '例如'.encode('utf-8')), (None, '會'.encode('utf-8')), (None, '用來'.encode('utf-8')), (None, '控制'.encode('utf-8')), (None, '代表'.encode('utf-8')), (None, '實際'.encode('utf-8')), (None, '屬於'.encode('utf-8')), (None, '檔案'.encode('utf-8')), (None, '路徑'.encode('utf-8')), (None, b'rule'), (None, b'references/'), (None, b'working/'), (None, b'assets/')])
    for _iteration_121 in first(call(ipairs, patterns)):
        _, pattern = unpack([_iteration_121], 2)
        if truth(first(method(text, b'find', pattern, 1, True))):
            return True
    return False

def count_term_hits(text=None, terms=None, *_ignored):
    count = 0
    for _iteration_122 in first(call(ipairs, terms)):
        _, term = unpack([_iteration_122], 2)
        if truth(first(method(text, b'find', term, 1, True))):
            count = count + 1
    return count

def has_concrete_anchor(text=None, *_ignored):
    if ((truth(first(method(text, b'find', b'`', 1, True))) or truth(first(method(text, b'find', b'L%d%d%d')))) or truth(first(method(text, b'find', b'[%w_./-]+%.md')))) or truth(first(method(text, b'find', b'[%w_./-]+%.lua'))):
        return True
    patterns = T([(None, '例如'.encode('utf-8')), (None, '像是'.encode('utf-8')), (None, '比如'.encode('utf-8')), (None, '會'.encode('utf-8')), (None, '用來'.encode('utf-8')), (None, '改成'.encode('utf-8')), (None, '改寫'.encode('utf-8')), (None, '移除'.encode('utf-8')), (None, '加入'.encode('utf-8')), (None, '補上'.encode('utf-8')), (None, '更新'.encode('utf-8')), (None, '寫回'.encode('utf-8')), (None, '實作'.encode('utf-8')), (None, '檢查'.encode('utf-8')), (None, '驗證'.encode('utf-8')), (None, '對齊'.encode('utf-8')), (None, b'references/'), (None, b'working/')])
    for _iteration_123 in first(call(ipairs, patterns)):
        _, pattern = unpack([_iteration_123], 2)
        if truth(first(method(text, b'find', pattern, 1, True))):
            return True
    return False

def has_any_plain(text=None, patterns=None, *_ignored):
    for _iteration_124 in first(call(ipairs, patterns)):
        _, pattern = unpack([_iteration_124], 2)
        if truth(first(method(text, b'find', pattern, 1, True))):
            return True
    return False

def find_internal_control_label_col(line=None, *_ignored):
    text = _condition_126 if truth((_condition_126 := (_condition_125 if truth((_condition_125 := line.masked_text)) else line.text))) else b''
    for _iteration_127 in first(call(ipairs, INTERNAL_CONTROL_LABELS)):
        _, term = unpack([_iteration_127], 2)
        col = first(method(text, b'find', term, 1, True))
        if truth(col):
            return col
    lowered = first(method(text, b'lower'))
    for _iteration_128 in first(call(ipairs, INTERNAL_CONTROL_LABELS_CASE_INSENSITIVE)):
        ___2, term__2 = unpack([_iteration_128], 2)
        col__2 = first(method(lowered, b'find', term__2, 1, True))
        if truth(col__2):
            return col__2
    return None

def find_any_in_lines(lines=None, patterns=None, *_ignored):
    for _iteration_129 in first(call(ipairs, lines)):
        _, line = unpack([_iteration_129], 2)
        for _iteration_130 in first(call(ipairs, patterns)):
            ___2, pattern = unpack([_iteration_130], 2)
            col = first(method(line.masked_text, b'find', pattern, 1, True))
            if truth(col):
                return ret(line.number, col)
    return ret(None, None)

def find_next_plain(text=None, patterns=None, start_pos=None, *_ignored):
    earliest = None
    for _iteration_131 in first(call(ipairs, patterns)):
        _, pattern = unpack([_iteration_131], 2)
        pos = first(method(text, b'find', pattern, start_pos, True))
        if truth(pos) and (not truth(earliest) or pos < earliest):
            earliest = pos
    return earliest

def is_noncode_text_line(line=None, *_ignored):
    return not truth(line.is_blockquote) if truth((_condition_135 := (not truth(line.is_table) if truth((_condition_134 := (not truth(line.is_heading) if truth((_condition_133 := (not truth(line.is_code) if truth((_condition_132 := (not truth(line.is_blank)))) else _condition_132))) else _condition_133))) else _condition_134))) else _condition_135

def is_temporal_subordinate_clause(text=None, *_ignored):
    patterns = T([(None, '的時候'.encode('utf-8')), (None, '時候'.encode('utf-8')), (None, '之前'.encode('utf-8')), (None, '以後'.encode('utf-8')), (None, '之際'.encode('utf-8')), (None, '之時'.encode('utf-8')), (None, '時'.encode('utf-8'))])
    return call(has_any_plain, text, patterns)

def previous_utf8_char(text=None, byte_pos=None, *_ignored):
    prev_start = first(call(utf8.offset, text, -1, byte_pos))
    if not truth(prev_start):
        return None
    return method(text, b'sub', prev_start, byte_pos - 1)

def starts_with_count_phrase(text=None, *_ignored):
    trimmed = first(call(core.trim, text))
    digits = first(method(trimmed, b'match', b'^(%d+)'))
    if truth(digits):
        rest = first(method(trimmed, b'sub', length(digits) + 1))
        for _iteration_136 in first(call(ipairs, COUNT_CLASSIFIERS)):
            _, classifier = unpack([_iteration_136], 2)
            if first(method(rest, b'find', classifier, 1, True)) == 1:
                return True
    for _iteration_137 in first(call(ipairs, COUNT_PREFIXES)):
        ___2, prefix = unpack([_iteration_137], 2)
        if first(method(trimmed, b'find', prefix, 1, True)) == 1:
            rest__2 = first(method(trimmed, b'sub', length(prefix) + 1))
            for _iteration_138 in first(call(ipairs, COUNT_CLASSIFIERS)):
                ___3, classifier__2 = unpack([_iteration_138], 2)
                if first(method(rest__2, b'find', classifier__2, 1, True)) == 1:
                    return True
    return False

def starts_with_temporal_count_phrase(text=None, *_ignored):
    trimmed = first(call(core.trim, text))
    temporal_classifiers = T([(None, '年'.encode('utf-8')), (None, '月'.encode('utf-8')), (None, '天'.encode('utf-8')), (None, '分鐘'.encode('utf-8')), (None, '小時'.encode('utf-8'))])
    temporal_suffixes = T([(None, '前'.encode('utf-8')), (None, '後'.encode('utf-8')), (None, '內'.encode('utf-8')), (None, '來'.encode('utf-8'))])

    def has_temporal_suffix(text_after_classifier=None, *_ignored):
        for _iteration_139 in first(call(ipairs, temporal_suffixes)):
            _, suffix = unpack([_iteration_139], 2)
            if first(method(text_after_classifier, b'find', suffix, 1, True)) == 1:
                return True
        return False
    digits = first(method(trimmed, b'match', b'^(%d+)'))
    if truth(digits):
        rest = first(method(trimmed, b'sub', length(digits) + 1))
        for _iteration_140 in first(call(ipairs, temporal_classifiers)):
            _, classifier = unpack([_iteration_140], 2)
            if first(method(rest, b'find', classifier, 1, True)) == 1:
                after = first(method(rest, b'sub', length(classifier) + 1))
                if truth(first(call(has_temporal_suffix, after))):
                    return True
    for _iteration_141 in first(call(ipairs, COUNT_PREFIXES)):
        ___2, prefix = unpack([_iteration_141], 2)
        if first(method(trimmed, b'find', prefix, 1, True)) == 1:
            rest__2 = first(method(trimmed, b'sub', length(prefix) + 1))
            for _iteration_142 in first(call(ipairs, temporal_classifiers)):
                ___3, classifier__2 = unpack([_iteration_142], 2)
                if first(method(rest__2, b'find', classifier__2, 1, True)) == 1:
                    after__2 = first(method(rest__2, b'sub', length(classifier__2) + 1))
                    if truth(first(call(has_temporal_suffix, after__2))):
                        return True
    return False

def has_count_phrase(text=None, *_ignored):
    for _iteration_143 in first(call(ipairs, COUNT_CLASSIFIERS)):
        _, classifier = unpack([_iteration_143], 2)
        if truth(first(method(text, b'find', concat(b'%d+', classifier)))):
            return True
        for _iteration_144 in first(call(ipairs, COUNT_PREFIXES)):
            ___2, prefix = unpack([_iteration_144], 2)
            if truth(first(method(text, b'find', concat(prefix, classifier), 1, True))):
                return True
    return False

def clause_window(text=None, start_pos=None, *_ignored):
    boundary = first(call(find_next_plain, text, CLAUSE_BOUNDARIES, start_pos))
    return _condition_146 if truth((_condition_146 := (first(method(text, b'sub', start_pos, boundary - 1)) if truth((_condition_145 := boundary)) else _condition_145))) else first(method(text, b'sub', start_pos))

def has_result_marker(text=None, *_ignored):
    return call(has_any_plain, text, BA_RESULT_MARKERS)

def count_plain_occurrences(text=None, needles=None, *_ignored):
    count = 0
    for _iteration_147 in first(call(ipairs, needles)):
        _, needle = unpack([_iteration_147], 2)
        count = count + first(call(core.count_substring, text, needle))
    return count
split_strong_sentences = None

def count_strong_sentences(text=None, *_ignored):
    count = 0
    for _iteration_148 in first(call(ipairs, call(split_strong_sentences, text))):
        _, segment = unpack([_iteration_148], 2)
        if first(call(core.visible_length, call(core.trim, segment.text))) >= 12:
            count = count + 1
    return count

def has_nearby_plain(text=None, needle=None, byte_pos=None, max_window=None, *_ignored):
    start_pos = first(call(math.max, 1, byte_pos - max_window))
    return first(method(first(method(text, b'sub', start_pos, byte_pos - 1)), b'find', needle, 1, True)) != None

def trimmed_tail(text=None, byte_pos=None, *_ignored):
    return call(core.trim, method(text, b'sub', byte_pos))

def strip_terminal_fullwidth_punctuation(text=None, *_ignored):
    trimmed = first(call(core.trim, text))
    for _iteration_149 in first(call(ipairs, T([(None, '。'.encode('utf-8')), (None, '；'.encode('utf-8')), (None, '：'.encode('utf-8'))]))):
        _, marker = unpack([_iteration_149], 2)
        if first(method(trimmed, b'sub', -length(marker))) == marker:
            return call(core.trim, method(trimmed, b'sub', 1, length(trimmed) - length(marker)))
    return trimmed

def text_after_last_plain(text=None, marker=None, *_ignored):
    last_pos = None
    search_from = 1
    while True:
        pos = first(method(text, b'find', marker, search_from, True))
        if not truth(pos):
            break
        last_pos = pos
        search_from = pos + length(marker)
    if not truth(last_pos):
        return None
    return method(text, b'sub', last_pos + length(marker))

def has_inline_final_conjunction(text=None, *_ignored):
    trimmed = first(call(core.trim, text))
    if trimmed == b'':
        return False
    for _iteration_150 in first(call(ipairs, T([(None, '與'.encode('utf-8')), (None, '及'.encode('utf-8')), (None, '或'.encode('utf-8'))]))):
        _, marker = unpack([_iteration_150], 2)
        search_from = 1
        while True:
            pos = first(method(trimmed, b'find', marker, search_from, True))
            if not truth(pos):
                break
            before = first(call(core.trim, method(trimmed, b'sub', 1, pos - 1)))
            after = first(call(core.trim, method(trimmed, b'sub', pos + length(marker))))
            if before != b'' and after != b'':
                return True
            search_from = pos + length(marker)
    return False

def find_bare_english_drift_col(line=None, english_lower=None, *_ignored):
    text = line.masked_text
    text_lower = first(method(text, b'lower'))
    codepoints_cache = None
    search_from = 1
    while True:
        match_start, match_end = unpack([method(text_lower, b'find', english_lower, search_from, True)], 2)
        if not truth(match_start):
            return None
        left_char = _condition_152 if truth((_condition_152 := (first(method(text, b'sub', match_start - 1, match_start - 1)) if truth((_condition_151 := (match_start > 1))) else _condition_151))) else b''
        right_char = first(method(text, b'sub', match_end + 1, match_end + 1))
        word_bounded = not truth(first(method(right_char, b'match', b'[%w_]'))) if truth((_condition_153 := (not truth(first(method(left_char, b'match', b'[%w_]')))))) else _condition_153
        in_bilingual = False
        if truth(word_bounded):
            if match_start >= 4 and first(method(text, b'sub', match_start - 3, match_start - 1)) == '（'.encode('utf-8'):
                in_bilingual = True
            elif first(method(text, b'sub', match_end + 1, match_end + 3)) == '）'.encode('utf-8'):
                in_bilingual = True
        if truth(word_bounded) and (not truth(in_bilingual)):
            codepoints_cache = _condition_154 if truth((_condition_154 := codepoints_cache)) else first(call(core.codepoints, text))
            start_idx = None
            for _iteration_155 in first(call(ipairs, codepoints_cache)):
                i, item = unpack([_iteration_155], 2)
                if item.pos == match_start:
                    start_idx = i
                    break
                elif item.pos > match_start:
                    break
            if truth(start_idx):
                end_idx = start_idx
                while end_idx <= length(codepoints_cache) and get(codepoints_cache, end_idx).pos <= match_end:
                    end_idx = end_idx + 1
                end_idx = end_idx - 1
                left_neighbor = first(call(core.previous_nonspace, codepoints_cache, start_idx))
                right_neighbor = first(call(core.next_nonspace, codepoints_cache, end_idx))
                has_cjk_neighbor = _condition_158 if truth((_condition_158 := first(first(call(core.is_cjk, left_neighbor.cp)) if truth((_condition_156 := left_neighbor)) else _condition_156))) else first(first(call(core.is_cjk, right_neighbor.cp)) if truth((_condition_157 := right_neighbor)) else _condition_157)
                if truth(has_cjk_neighbor):
                    return match_start
        search_from = match_end + 1

def should_track_bare_english_drift_anchor(raw_english=None, english_key=None, *_ignored):
    trimmed = first(call(core.trim, call(tostring, _condition_159 if truth((_condition_159 := raw_english)) else b'')))
    if english_key == b'' or length(english_key) < 3:
        return False
    if not truth(first(method(trimmed, b'find', b'%a'))):
        return False
    if ((((truth(first(method(trimmed, b'find', b'://', 1, True))) or truth(first(method(trimmed, b'find', b'/', 1, True)))) or truth(first(method(trimmed, b'find', b'\\', 1, True)))) or truth(first(method(trimmed, b'find', b'@', 1, True)))) or truth(first(method(trimmed, b'find', b'::', 1, True)))) or truth(first(method(trimmed, b'find', b'_', 1, True))):
        return False
    if truth(first(method(trimmed, b'match', b'^[A-Z][A-Z0-9%-]*$'))):
        return False
    return True

def is_term_like_chinese(text=None, *_ignored):
    normalized = first(call(core.normalize_chinese_term, text))
    if normalized == b'':
        return False
    if first(call(core.visible_length, normalized)) > 10:
        return False
    blockers = T([(None, '的'.encode('utf-8')), (None, '最終'.encode('utf-8')), (None, '重點'.encode('utf-8')), (None, '正常情況'.encode('utf-8')), (None, '這個'.encode('utf-8')), (None, '那個'.encode('utf-8')), (None, '前面'.encode('utf-8')), (None, '後面'.encode('utf-8')), (None, '如果'.encode('utf-8')), (None, '除了'.encode('utf-8')), (None, '因此'.encode('utf-8')), (None, '所以'.encode('utf-8')), (None, '但是'.encode('utf-8')), (None, '不過'.encode('utf-8'))])
    return not truth(first(call(has_any_plain, normalized, blockers)))

def _callback_160(text=None, *_ignored):
    segments = T([])
    start_pos = 1
    byte_pos = 1
    while byte_pos <= length(text):
        codepoint = first(call(utf8.codepoint, text, byte_pos))
        char = first(call(utf8.char, codepoint))
        if ((char == '。'.encode('utf-8') or char == '！'.encode('utf-8')) or char == '？'.encode('utf-8')) or char == '；'.encode('utf-8'):
            call(table.insert, segments, T([(b'text', first(method(text, b'sub', start_pos, byte_pos - 1))), (b'start_pos', start_pos)]))
            start_pos = byte_pos + length(char)
        byte_pos = byte_pos + length(char)
    if start_pos <= length(text):
        call(table.insert, segments, T([(b'text', first(method(text, b'sub', start_pos))), (b'start_pos', start_pos)]))
    return segments
split_strong_sentences = _callback_160

def next_utf8_char(text=None, byte_pos=None, *_ignored):
    next_start = first(call(utf8.offset, text, 2, byte_pos))
    if not truth(next_start):
        return None
    current_len = length(first(method(text, b'sub', byte_pos, next_start - 1)))
    char_start = byte_pos + current_len
    if char_start > length(text):
        return None
    after_start = first(call(utf8.offset, text, 2, char_start))
    if truth(after_start):
        return method(text, b'sub', char_start, after_start - 1)
    return method(text, b'sub', char_start)

def starts_with_any(text=None, patterns=None, *_ignored):
    for _iteration_161 in first(call(ipairs, patterns)):
        _, pattern = unpack([_iteration_161], 2)
        if first(method(text, b'find', pattern, 1, True)) == 1:
            return True
    return False

def ends_with_any(text=None, patterns=None, *_ignored):
    for _iteration_162 in first(call(ipairs, patterns)):
        _, pattern = unpack([_iteration_162], 2)
        if length(text) >= length(pattern) and first(method(text, b'sub', -length(pattern))) == pattern:
            return True
    return False
MEMORY_ALLOCATION_CONTEXT = load_lexicon('MEMORY_ALLOCATION_CONTEXT')
TONGGUO_PASS_OBJECTS = load_lexicon('TONGGUO_PASS_OBJECTS')
IT_CONTEXT_TERMS = load_lexicon('IT_CONTEXT_TERMS')
PROCESSOR_CORE_COUNT_PREFIXES = load_lexicon('PROCESSOR_CORE_COUNT_PREFIXES')
HARDWARE_DEVICE_CONTEXT = load_lexicon('HARDWARE_DEVICE_CONTEXT')
PROCESS_PROGRAMMING_CONTEXT = load_lexicon('PROCESS_PROGRAMMING_CONTEXT')
EXCEPTION_PROGRAMMING_CONTEXT = load_lexicon('EXCEPTION_PROGRAMMING_CONTEXT')
MEMORY_ADDRESS_CONTEXT = load_lexicon('MEMORY_ADDRESS_CONTEXT')

def has_case_insensitive_plain(text=None, patterns=None, *_ignored):
    lowered = first(method(first(call(tostring, _condition_163 if truth((_condition_163 := text)) else b'')), b'lower'))
    for _iteration_164 in first(call(ipairs, patterns)):
        _, pattern = unpack([_iteration_164], 2)
        if truth(first(method(lowered, b'find', method(first(call(tostring, pattern)), b'lower'), 1, True))):
            return True
    return False

def has_memory_allocation_context(text=None, *_ignored):
    return call(has_case_insensitive_plain, text, MEMORY_ALLOCATION_CONTEXT)

def is_tongguo_pass_usage(text=None, col=None, *_ignored):
    after = first(call(core.trim, method(text, b'sub', col + length('通過'.encode('utf-8')))))
    return call(starts_with_any, after, TONGGUO_PASS_OBJECTS)

def has_it_context(text=None, *_ignored):
    return call(has_case_insensitive_plain, text, IT_CONTEXT_TERMS)

def has_hardware_device_context(text=None, *_ignored):
    return call(has_case_insensitive_plain, text, HARDWARE_DEVICE_CONTEXT)

def has_process_programming_context(text=None, *_ignored):
    return call(has_case_insensitive_plain, text, PROCESS_PROGRAMMING_CONTEXT)

def has_exception_programming_context(text=None, *_ignored):
    return call(has_case_insensitive_plain, text, EXCEPTION_PROGRAMMING_CONTEXT)

def has_memory_address_context(text=None, *_ignored):
    return call(has_case_insensitive_plain, text, MEMORY_ADDRESS_CONTEXT)

def is_processor_core_count_usage(text=None, col=None, *_ignored):
    before = first(method(text, b'sub', 1, col - 1))
    if truth(first(method(before, b'match', b'%d+%s*$'))):
        return True
    trimmed_before = first(call(core.trim, before))
    for _iteration_165 in first(call(ipairs, PROCESSOR_CORE_COUNT_PREFIXES)):
        _, prefix = unpack([_iteration_165], 2)
        if length(trimmed_before) >= length(prefix) and first(method(trimmed_before, b'sub', -length(prefix))) == prefix:
            return True
    return False

def should_warn_preferred_term(entry=None, text=None, col=None, *_ignored):
    if entry.term == '當前'.encode('utf-8') and first(method(text, b'sub', col + length('當前'.encode('utf-8')), col + length('當前'.encode('utf-8')) + length('置'.encode('utf-8')) - 1)) == '置'.encode('utf-8'):
        return False
    if entry.term == '代碼'.encode('utf-8') and first(method(text, b'sub', call(math.max, 1, col - length('控制'.encode('utf-8'))), col - 1)) == '控制'.encode('utf-8'):
        return False
    if entry.context == b'memory_allocation':
        return call(has_memory_allocation_context, text)
    if entry.context == b'tongguo_via':
        return not truth(first(call(is_tongguo_pass_usage, text, col)))
    if entry.context == b'processor_core_count':
        return call(is_processor_core_count_usage, text, col)
    if entry.context == b'it':
        return call(has_it_context, text)
    if entry.context == b'hardware_device':
        return call(has_hardware_device_context, text)
    if entry.context == b'process_programming':
        return call(has_process_programming_context, text)
    if entry.context == b'exception_programming':
        return call(has_exception_programming_context, text)
    if entry.context == b'memory_address':
        return call(has_memory_address_context, text)
    return True
PREFERRED_TAIWAN_TERMS = load_lexicon('PREFERRED_TAIWAN_TERMS')

def preferred_term_message(entry=None, *_ignored):
    message = concat('「'.encode('utf-8'), concat(entry.term, concat('」建議改為「'.encode('utf-8'), concat(entry.preferred, '」'.encode('utf-8')))))
    if truth(entry.note):
        message = concat(message, concat('；'.encode('utf-8'), entry.note))
    return message

def span_overlaps(spans=None, start_col=None, end_col=None, *_ignored):
    for _iteration_166 in first(call(ipairs, spans)):
        _, span = unpack([_iteration_166], 2)
        if start_col <= span.end_col and end_col >= span.start_col:
            return True
    return False
DESCRIPTIVE_PARENTHETICAL_PREFIXES = load_lexicon('DESCRIPTIVE_PARENTHETICAL_PREFIXES')

def parenthetical_content_at(text=None, open_pos=None, *_ignored):
    close_pos = first(method(text, b'find', '）'.encode('utf-8'), open_pos + length('（'.encode('utf-8')), True))
    if not truth(close_pos):
        return None
    return method(text, b'sub', open_pos + length('（'.encode('utf-8')), close_pos - 1)

def is_descriptive_chinese_parenthetical(text=None, *_ignored):
    trimmed = first(call(core.trim, _condition_167 if truth((_condition_167 := text)) else b''))
    if trimmed == b'':
        return False
    if truth(first(method(trimmed, b'find', b'`', 1, True))) or truth(first(method(trimmed, b'find', '：'.encode('utf-8'), 1, True))):
        return True
    if truth(first(method(trimmed, b'find', b'%d'))) or truth(first(call(core.contains_ascii_letter, trimmed))):
        return True
    return call(starts_with_any, trimmed, DESCRIPTIVE_PARENTHETICAL_PREFIXES)

def is_write_back_term_usage(text=None, col=None, *_ignored):
    lowered = first(method(text, b'lower'))
    if (truth(first(method(lowered, b'find', b'write-back', 1, True))) or truth(first(method(lowered, b'find', b'write back', 1, True)))) or truth(first(method(lowered, b'find', b'write-through', 1, True))):
        return True
    after = first(call(core.trim, method(text, b'sub', col + length('回寫'.encode('utf-8')))))
    if truth(first(call(starts_with_any, after, HUIXIE_TERM_SUFFIXES))):
        return True
    before = first(method(first(call(core.trim, method(text, b'sub', 1, col - 1))), b'lower'))
    if truth(first(call(ends_with_any, before, HUIXIE_TERM_PREFIXES))):
        return True
    return False

def is_lexical_le(text=None, col=None, *_ignored):
    prev_char = first(call(previous_utf8_char, text, col))
    lexical_prev_chars = T([('為'.encode('utf-8'), True), ('除'.encode('utf-8'), True), ('罷'.encode('utf-8'), True), ('算'.encode('utf-8'), True), ('對'.encode('utf-8'), True), ('好'.encode('utf-8'), True), ('忘'.encode('utf-8'), True), ('得'.encode('utf-8'), True)])
    if truth(get(lexical_prev_chars, prev_char)):
        return True
    tail = first(method(text, b'sub', col))
    return call(starts_with_any, tail, T([(None, '了解'.encode('utf-8')), (None, '瞭解'.encode('utf-8')), (None, '了結'.encode('utf-8')), (None, '了然'.encode('utf-8')), (None, '了當'.encode('utf-8')), (None, '了不起'.encode('utf-8'))]))

def find_dense_de_chain_col(text=None, *_ignored):
    for _iteration_168 in first(call(ipairs, call(split_strong_sentences, text))):
        _, segment = unpack([_iteration_168], 2)
        positions = T([])
        search_from = 1
        while True:
            relative_col = first(method(segment.text, b'find', '的'.encode('utf-8'), search_from, True))
            if not truth(relative_col):
                break
            absolute_col = segment.start_pos + relative_col - 1
            if first(call(next_utf8_char, text, absolute_col)) != '是'.encode('utf-8'):
                call(table.insert, positions, relative_col)
            search_from = relative_col + length('的'.encode('utf-8'))
        _start_169, _stop_170, _step_171 = (1, length(positions) - 2, 1)
        for index in range(int(_start_169), int(_stop_170) + (1 if _step_171 > 0 else -1), int(_step_171)):
            first__2 = get(positions, index)
            third = get(positions, index + 2)
            window = first(method(segment.text, b'sub', first__2, third + length('的'.encode('utf-8')) - 1))
            if first(call(core.visible_length, window)) <= 15:
                return segment.start_pos + first__2 - 1
    return None

def find_nearby_prefix_before(text=None, byte_pos=None, prefixes=None, max_distance=None, *_ignored):
    last_boundary = 0
    for _iteration_172 in first(call(ipairs, CLAUSE_BOUNDARIES)):
        _, boundary = unpack([_iteration_172], 2)
        search_from = 1
        while True:
            found = first(method(text, b'find', boundary, search_from, True))
            if not truth(found) or found >= byte_pos:
                break
            if found > last_boundary:
                last_boundary = found
            search_from = found + length(boundary)
    clause_start = last_boundary + 1
    for _iteration_173 in first(call(ipairs, prefixes)):
        ___2, prefix = unpack([_iteration_173], 2)
        search_from__2 = clause_start
        while True:
            found__2 = first(method(text, b'find', prefix, search_from__2, True))
            if not truth(found__2) or found__2 >= byte_pos:
                break
            span = first(method(text, b'sub', found__2, byte_pos + length('了'.encode('utf-8')) - 1))
            if first(call(core.visible_length, span)) <= max_distance:
                return found__2
            search_from__2 = found__2 + length(prefix)
    return None

def find_final_clause(text=None, *_ignored):
    last_boundary = 0
    for _iteration_174 in first(call(ipairs, CLAUSE_BOUNDARIES)):
        _, boundary = unpack([_iteration_174], 2)
        search_from = 1
        while True:
            found = first(method(text, b'find', boundary, search_from, True))
            if not truth(found):
                break
            if found + length(boundary) - 1 < length(text) and found > last_boundary:
                last_boundary = found
            search_from = found + length(boundary)
    clause_start = last_boundary + 1
    return ret(method(text, b'sub', clause_start), clause_start)

def contains_definite_marker(text=None, *_ignored):
    return call(has_any_plain, text, DEFINITE_MARKERS)

def is_clause_start_before(text=None, byte_pos=None, *_ignored):
    prev_char = first(call(previous_utf8_char, text, byte_pos))
    if not truth(prev_char):
        return True
    return _condition_175 if truth((_condition_175 := (first(method(prev_char, b'match', b'%s')) != None))) else first(call(has_any_plain, prev_char, T([(None, '，'.encode('utf-8')), (None, '。'.encode('utf-8')), (None, '；'.encode('utf-8')), (None, '：'.encode('utf-8')), (None, b','), (None, b';'), (None, b'!'), (None, b'?'), (None, '（'.encode('utf-8')), (None, b'(')])))
RULES = None
__all__ = ['ABSTRACT_EVENT_NOUNS', 'ABSTRACT_TAXONOMY_TERMS', 'BARE_BA_VERBS', 'BA_RESULT_MARKERS', 'BIBLIOGRAPHY_URL_LEADS', 'CLAUSE_BOUNDARIES', 'COMPLETION_EVENT_VERBS', 'CONTROL_MODALS', 'COUNT_CLASSIFIERS', 'COUNT_PREFIXES', 'DEFINITE_MARKERS', 'DEGREE_MARKERS', 'DESCRIPTION_OBJECTS', 'DESCRIPTIVE_PARENTHETICAL_PREFIXES', 'DURATION_OR_COUNT_MARKERS', 'EVENT_NOMINALIZATION_TAIL_MARKERS', 'EXCEPTION_PROGRAMMING_CONTEXT', 'FULLWIDTH_QUOTE_CLOSERS', 'FULLWIDTH_QUOTE_OPENERS', 'GENERIC_YOU_VERBS', 'GLOSSARY_PREFIX_FALLBACK_MARKERS', 'HARDWARE_DEVICE_CONTEXT', 'HIGH_RISK_MISSING_COMPLEMENT_DE', 'HIGH_RISK_MISSING_DE_PHRASES', 'HIGH_RISK_MISSING_DI_PHRASES', 'HUIXIE_TERM_PREFIXES', 'HUIXIE_TERM_SUFFIXES', 'INTERNAL_CONTROL_LABELS', 'INTERNAL_CONTROL_LABELS_CASE_INSENSITIVE', 'IT_CONTEXT_TERMS', 'M', 'MEMORY_ADDRESS_CONTEXT', 'MEMORY_ALLOCATION_CONTEXT', 'NONAGENTIVE_SUBJECTS', 'OVERLOADED_POSTVERBAL_VERBS', 'PREFERRED_TAIWAN_TERMS', 'PROCESSOR_CORE_COUNT_PREFIXES', 'PROCESS_PROGRAMMING_CONTEXT', 'REPEATED_SUBJECT_HEADS', 'RULES', 'SENTENCE_SPACING_CLOSERS', 'SENTENCE_SPACING_FOLLOWING_PUNCTUATION', 'SENTENCE_SPACING_PUNCTUATION', 'SHOU_BARE_EVENT_VERBS', 'SIMPLIFIED_CHARS', 'SIMPLIFIED_ONLY_CHARACTERS', 'TERMINAL_CONTINUATION_PUNCTUATION', 'TERMINAL_PUNCTUATION_CLOSERS', 'TITLE_MARK_CLOSERS', 'TITLE_MARK_OPENERS', 'TONGGUO_PASS_OBJECTS', 'TRACKING_QUERY_PARAMS', 'WORKSPACE_JARGON', 'add_file_issue', 'add_issue', 'ascii_char_before', 'ascii_token_at', 'ascii_word_count', 'bibliography_explanation_subbullets', 'bibliography_has_url', 'bibliography_section_lines', 'bibliography_url_subbullet_is_pure_url', 'bilingual_order_lines', 'boundary_kind', 'build_simplified_set', 'cjk_internal_space_col', 'clause_window', 'col_in_markdown_link_hidden_span', 'col_in_spans', 'contains_definite_marker', 'core', 'count_plain_occurrences', 'count_strong_sentences', 'count_term_hits', 'ends_with_any', 'find_any_in_lines', 'find_bare_english_drift_col', 'find_dense_de_chain_col', 'find_final_clause', 'find_internal_control_label_col', 'find_matching_halfwidth_parenthesis', 'find_nearby_prefix_before', 'find_next_plain', 'forbids_cjk_cjk_space', 'formal_citation_links', 'fullwidth_parentheses_spacing_col', 'fullwidth_quote_spacing_col', 'gap_has_halfwidth_space', 'halfwidth_parenthetical_in_cjk_context_col', 'has_any_plain', 'has_case_insensitive_plain', 'has_concrete_anchor', 'has_count_phrase', 'has_exception_programming_context', 'has_expansion_signal', 'has_hardware_device_context', 'has_inline_final_conjunction', 'has_it_context', 'has_memory_address_context', 'has_memory_allocation_context', 'has_nearby_plain', 'has_process_programming_context', 'has_reference_heading', 'has_result_marker', 'inline_code_spans', 'inline_math_spans', 'internal_consecutive_space_col', 'is_ascii_alnum', 'is_ascii_digit', 'is_ascii_identifier_char', 'is_ascii_letter', 'is_ascii_parenthetical_prose', 'is_ascii_token_char', 'is_clause_start_before', 'is_code_like_ascii_parenthetical', 'is_codeish_ascii_token', 'is_custom_container_closing_line', 'is_custom_container_opening_line', 'is_descriptive_chinese_parenthetical', 'is_function_call_parentheses', 'is_halfwidth_parenthetical_allowed_in_cjk_context', 'is_halfwidth_space_item', 'is_lexical_le', 'is_markdown_image_line', 'is_markdown_prefix_before_col', 'is_noncode_text_line', 'is_original_char', 'is_processor_core_count_usage', 'is_reference_heading_line', 'is_temporal_subordinate_clause', 'is_term_like_chinese', 'is_tongguo_pass_usage', 'is_top_level_code_fence', 'is_top_level_custom_container_marker', 'is_tracking_query_param', 'is_unmasked_char', 'is_write_back_term_usage', 'label_edge_kind', 'markdown_link_spans', 'markdown_link_url_has_tracking_param', 'matches_glossary_preferred_form', 'needs_cjk_ascii_space', 'next_nonspace_item', 'next_utf8_char', 'parenthetical_content_at', 'parse_custom_container_marker', 'parse_reference_entry_line', 'preferred_term_message', 'previous_nonspace_item', 'previous_utf8_char', 'prose_lines', 'punctuation_spacing_lines', 'should_skip_cjk_ascii_spacing_boundary', 'should_track_bare_english_drift_anchor', 'should_warn_preferred_term', 'span_overlaps', 'split_strong_sentences', 'starts_with_any', 'starts_with_count_phrase', 'starts_with_temporal_count_phrase', 'strip_terminal_fullwidth_punctuation', 'terminal_continuation_punctuation_col', 'text_after_last_plain', 'text_between_items', 'title_mark_direct_spacing_col', 'title_mark_label_edge', 'title_mark_markdown_link_edge_spacing_col', 'title_mark_spacing_col', 'token_has_ascii_alnum', 'trimmed_tail', 'visible_text_lines']
