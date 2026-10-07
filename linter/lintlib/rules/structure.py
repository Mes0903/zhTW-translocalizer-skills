"""Domain predicates with shared byte-oriented analysis."""
from lintlib.byte_patterns import T, get, truth, first, unpack, call, length, method, ipairs
from lintlib.clauses import add_issue, core, find_internal_control_label_col, is_custom_container_closing_line, is_custom_container_opening_line, is_markdown_image_line, is_top_level_code_fence, is_top_level_custom_container_marker, parse_custom_container_marker, visible_text_lines

def check_L003(document=None, issues=None, rule=None, *_ignored):
    _start_10004, _stop_10005, _step_10006 = (1, length(document.lines) - 1, 1)
    for index in range(int(_start_10004), int(_stop_10005) + (1 if _step_10006 > 0 else -1), int(_step_10006)):
        line = get(document.lines, index)
        next_line = get(document.lines, index + 1)
        if (((not truth(line.is_code) and (not truth(line.is_list))) and truth(first(method(line.stripped, b'find', '：$'.encode('utf-8'))))) and truth(next_line.is_list)) and next_line.list_indent == 0:
            call(add_issue, issues, document, rule, line.number, length(line.text))

def check_L004(document=None, issues=None, rule=None, *_ignored):
    for _iteration_10007 in first(call(ipairs, document.lines)):
        index, line = unpack([_iteration_10007], 2)
        if truth(line.is_blank):
            prev_line = get(document.lines, index - 1)
            next_line = get(document.lines, index + 1)
            if ((truth(prev_line) and truth(next_line)) and truth(prev_line.is_list)) and truth(next_line.is_list):
                allow_spacious_long_items = first(_condition_10009 if truth((_condition_10009 := (first(call(core.visible_length, prev_line.text)) >= 60))) else first(call(core.visible_length, next_line.text)) >= 60) if truth((_condition_10010 := (next_line.list_indent == 0 if truth((_condition_10008 := (prev_line.list_indent == 0))) else _condition_10008))) else _condition_10010
                if not truth(allow_spacious_long_items):
                    call(add_issue, issues, document, rule, line.number, 1)

def check_L005(document=None, issues=None, rule=None, *_ignored):
    patterns = T([(None, b'<style'), (None, b'style='), (None, b'<div'), (None, b'</div>'), (None, b'<span'), (None, b'</span>'), (None, b'<font'), (None, b'</font>'), (None, b'<center'), (None, b'</center>'), (None, b'class=')])
    for _iteration_10011 in first(call(ipairs, document.lines)):
        _, line = unpack([_iteration_10011], 2)
        if not truth(line.is_code):
            lowered = first(method(line.masked_text, b'lower'))
            for _iteration_10012 in first(call(ipairs, patterns)):
                ___2, pattern = unpack([_iteration_10012], 2)
                col = first(method(lowered, b'find', pattern, 1, True))
                if truth(col):
                    call(add_issue, issues, document, rule, line.number, col)
                    break

def check_L006(document=None, issues=None, rule=None, *_ignored):
    patterns = T([(None, b'_page_%d+'), (None, b'page_%d+%.png'), (None, b'^Page%s+%d+$'), (None, '^第?%d+頁$'.encode('utf-8'))])
    for _iteration_10013 in first(call(ipairs, document.lines)):
        _, line = unpack([_iteration_10013], 2)
        if not truth(line.is_code) and (not truth(first(call(is_markdown_image_line, line)))):
            for _iteration_10014 in first(call(ipairs, patterns)):
                ___2, pattern = unpack([_iteration_10014], 2)
                col = first(method(line.masked_text, b'find', pattern))
                if truth(col):
                    call(add_issue, issues, document, rule, line.number, col)
                    break

def check_L017(document=None, issues=None, rule=None, *_ignored):
    patterns = T([(None, '開工前檢查'.encode('utf-8')), (None, b'preflight'), (None, '自檢'.encode('utf-8')), (None, '驗證關卡'.encode('utf-8')), (None, b'TODO')])
    for _iteration_10015 in first(call(ipairs, document.lines)):
        _, line = unpack([_iteration_10015], 2)
        if not truth(line.is_code):
            for _iteration_10016 in first(call(ipairs, patterns)):
                ___2, pattern = unpack([_iteration_10016], 2)
                col = first(method(line.masked_text, b'find', pattern, 1, True))
                if truth(col) and ((truth(line.is_heading) or truth(first(method(line.masked_text, b'match', b'^%s*[-*]')))) or truth(first(method(line.masked_text, b'match', b'^%s*%d+%.')))):
                    call(add_issue, issues, document, rule, line.number, col)
                    break

def check_L018(document=None, issues=None, rule=None, *_ignored):
    pattern = '^%s*(使用者：|assistant:|user:|system:)'.encode('utf-8')
    for _iteration_10017 in first(call(ipairs, document.lines)):
        _, line = unpack([_iteration_10017], 2)
        if not truth(line.is_code) and truth(first(method(line.masked_text, b'match', pattern))):
            call(add_issue, issues, document, rule, line.number, call(core.first_nonspace_col, line.text))

def check_L019(document=None, issues=None, rule=None, *_ignored):
    patterns = T([(None, '^#+%s*原文%s*$'.encode('utf-8')), (None, b'^#+%s*source text%s*$'), (None, '^#+%s*譯文對照%s*$'.encode('utf-8')), (None, '^%s*原文：'.encode('utf-8')), (None, '^%s*譯文：'.encode('utf-8')), (None, '^%s*source：'.encode('utf-8')), (None, '^%s*translation：'.encode('utf-8'))])
    for _iteration_10018 in first(call(ipairs, document.lines)):
        _, line = unpack([_iteration_10018], 2)
        if not truth(line.is_code):
            lowered = first(method(line.masked_text, b'lower'))
            for _iteration_10019 in first(call(ipairs, patterns)):
                ___2, pattern = unpack([_iteration_10019], 2)
                if truth(first(method(lowered, b'match', pattern))):
                    call(add_issue, issues, document, rule, line.number, call(core.first_nonspace_col, line.text))
                    break

def check_L130(document=None, issues=None, rule=None, *_ignored):
    for _iteration_10020 in first(call(ipairs, call(visible_text_lines, document))):
        _, line = unpack([_iteration_10020], 2)
        col = first(call(find_internal_control_label_col, line))
        if truth(col):
            call(add_issue, issues, document, rule, line.number, col)

def check_L036(document=None, issues=None, rule=None, *_ignored):
    in_fence = False
    for _iteration_10021 in first(call(ipairs, document.lines)):
        index, line = unpack([_iteration_10021], 2)
        if truth(line.is_fence):
            if not truth(in_fence):
                if truth(first(call(is_top_level_code_fence, line))):
                    prev_line = get(document.lines, index - 1)
                    if (truth(prev_line) and (not truth(prev_line.is_blank))) and (not truth(first(call(is_custom_container_opening_line, prev_line)))):
                        call(add_issue, issues, document, rule, line.number, call(core.first_nonspace_col, line.text))
                in_fence = True
            else:
                if truth(first(call(is_top_level_code_fence, line))):
                    next_line = get(document.lines, index + 1)
                    if (truth(next_line) and (not truth(next_line.is_blank))) and (not truth(first(call(is_custom_container_closing_line, next_line)))):
                        call(add_issue, issues, document, rule, line.number, call(core.first_nonspace_col, line.text))
                in_fence = False

def check_L039(document=None, issues=None, rule=None, *_ignored):
    in_container = False
    for _iteration_10022 in first(call(ipairs, document.lines)):
        index, line = unpack([_iteration_10022], 2)
        if not truth(line.is_code):
            info = first(call(parse_custom_container_marker, line.text))
            if truth(info):
                if info.marker_len != 3:
                    call(add_issue, issues, document, rule, line.number, call(core.first_nonspace_col, line.text))
                if truth(info.is_closing):
                    if truth(in_container):
                        prev_line = get(document.lines, index - 1)
                        if truth(prev_line) and truth(prev_line.is_blank):
                            call(add_issue, issues, document, rule, line.number, call(core.first_nonspace_col, line.text))
                        if truth(first(call(is_top_level_custom_container_marker, info))):
                            next_line = get(document.lines, index + 1)
                            if truth(next_line) and (not truth(next_line.is_blank)):
                                call(add_issue, issues, document, rule, line.number, call(core.first_nonspace_col, line.text))
                        in_container = False
                else:
                    if (truth(info.has_space_after_marker) or not truth(info.label)) or first(call(core.trim, info.label_tail)) != b'':
                        call(add_issue, issues, document, rule, line.number, call(core.first_nonspace_col, line.text))
                    if truth(first(call(is_top_level_custom_container_marker, info))):
                        prev_line__2 = get(document.lines, index - 1)
                        if truth(prev_line__2) and (not truth(prev_line__2.is_blank)):
                            call(add_issue, issues, document, rule, line.number, call(core.first_nonspace_col, line.text))
                    next_line__2 = get(document.lines, index + 1)
                    if truth(next_line__2) and truth(next_line__2.is_blank):
                        call(add_issue, issues, document, rule, line.number, call(core.first_nonspace_col, line.text))
                    in_container = True
            elif truth(in_container) and truth(first(method(line.text, b'match', b':::%s*$'))):
                call(add_issue, issues, document, rule, line.number, _condition_10023 if truth((_condition_10023 := first(method(line.text, b'find', b':::', 1, True)))) else 1)

def check_L014(document=None, issues=None, rule=None, *_ignored):
    if document.text != b'' and first(method(document.text, b'sub', -1)) != b'\n':
        last_line = get(document.lines, length(document.lines))
        line_number = _condition_10025 if truth((_condition_10025 := (last_line.number if truth((_condition_10024 := last_line)) else _condition_10024))) else 1
        col = _condition_10027 if truth((_condition_10027 := (length(last_line.text) + 1 if truth((_condition_10026 := last_line)) else _condition_10026))) else 1
        call(add_issue, issues, document, rule, line_number, col)
from lintlib.rules import run_checks
CHECKS = {'L003': check_L003, 'L004': check_L004, 'L005': check_L005, 'L006': check_L006, 'L017': check_L017, 'L018': check_L018, 'L019': check_L019, 'L130': check_L130, 'L036': check_L036, 'L039': check_L039, 'L014': check_L014}

def paragraph_wrap_candidates(document):
    """One paragraph scan; visible lengths use the original raw text."""
    for paragraph in document['paragraphs']:
        short = sentences = 0
        for line in paragraph['lines']:
            raw = line['text'].encode('utf-8')
            short += 8 <= core.visible_length(raw) <= 60
            sentences += bool(core.is_sentence_like(raw))
        yield (paragraph, short, sentences)

def check(document: dict, selected: set[str]) -> list[dict]:
    from lintlib.rules import make_warning
    warnings = run_checks(document, selected, CHECKS)
    if selected & {'L001', 'L002'}:
        for paragraph, short, sentences in paragraph_wrap_candidates(document):
            count = paragraph['line_count']
            if 'L002' in selected and count >= 2:
                warnings.append(make_warning(document, 'L002', paragraph['start_line'], 1))
            if 'L001' in selected and count >= 3 and (short == count) and (sentences >= 2):
                warnings.append(make_warning(document, 'L001', paragraph['start_line'], 1))
    return warnings
