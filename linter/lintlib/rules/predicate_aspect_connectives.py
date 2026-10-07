"""Domain predicates with shared byte-oriented analysis."""
from lintlib.byte_patterns import T, truth, first, unpack, call, concat, length, method, ipairs
from lintlib.clauses import CLAUSE_BOUNDARIES, COMPLETION_EVENT_VERBS, CONTROL_MODALS, COUNT_PREFIXES, GENERIC_YOU_VERBS, NONAGENTIVE_SUBJECTS, add_issue, clause_window, contains_definite_marker, core, find_any_in_lines, find_final_clause, find_nearby_prefix_before, find_next_plain, has_any_plain, is_clause_start_before, is_lexical_le, is_noncode_text_line, is_temporal_subordinate_clause, previous_utf8_char, prose_lines

def check_L113(document=None, issues=None, rule=None, *_ignored):
    patterns = T([(None, '把[^。；，\n]-是'.encode('utf-8')), (None, '被[^。；，\n]-是'.encode('utf-8'))])
    for _iteration_10001 in first(call(ipairs, call(prose_lines, document))):
        _, line = unpack([_iteration_10001], 2)
        for _iteration_10002 in first(call(ipairs, patterns)):
            ___2, pattern = unpack([_iteration_10002], 2)
            col = first(method(line.masked_text, b'find', pattern))
            if truth(col):
                call(add_issue, issues, document, rule, line.number, col)
                break

def check_L126(document=None, issues=None, rule=None, *_ignored):
    patterns = T([(None, '因此所以'.encode('utf-8')), (None, '因此，但'.encode('utf-8')), (None, '然而但是'.encode('utf-8')), (None, '但是然而'.encode('utf-8')), (None, '此外同時'.encode('utf-8')), (None, '同時此外'.encode('utf-8'))])
    for _iteration_10003 in first(call(ipairs, call(prose_lines, document))):
        _, line = unpack([_iteration_10003], 2)
        for _iteration_10004 in first(call(ipairs, patterns)):
            ___2, pattern = unpack([_iteration_10004], 2)
            col = first(method(line.masked_text, b'find', pattern, 1, True))
            if truth(col):
                call(add_issue, issues, document, rule, line.number, col)
                break

def check_L125(document=None, issues=None, rule=None, *_ignored):
    groups = T([(None, T([(b'openers', T([(None, '雖然'.encode('utf-8'))])), (b'closers', T([(None, '但'.encode('utf-8')), (None, '但是'.encode('utf-8')), (None, '不過'.encode('utf-8')), (None, '仍然'.encode('utf-8')), (None, '仍'.encode('utf-8')), (None, '卻'.encode('utf-8'))]))])), (None, T([(b'openers', T([(None, '不但'.encode('utf-8')), (None, '不僅'.encode('utf-8')), (None, '不只'.encode('utf-8'))])), (b'closers', T([(None, '而且'.encode('utf-8')), (None, '還'.encode('utf-8')), (None, '也'.encode('utf-8'))]))]))])
    for _iteration_10005 in first(call(ipairs, document.paragraphs)):
        _, paragraph = unpack([_iteration_10005], 2)
        text = paragraph.text
        if not truth(first(method(text, b'find', '：%s*$'.encode('utf-8')))):
            for _iteration_10006 in first(call(ipairs, groups)):
                ___2, group = unpack([_iteration_10006], 2)
                line_number, col = unpack([call(find_any_in_lines, paragraph.lines, group.openers)], 2)
                if truth(line_number) and (not truth(first(call(has_any_plain, text, group.closers)))):
                    call(add_issue, issues, document, rule, line_number, col)
                    break

def check_L127(document=None, issues=None, rule=None, *_ignored):
    openers = T([(None, '快要'.encode('utf-8')), (None, '就要'.encode('utf-8'))])
    for _iteration_10007 in first(call(ipairs, document.lines)):
        _, line = unpack([_iteration_10007], 2)
        if truth(first(call(is_noncode_text_line, line))):
            for _iteration_10008 in first(call(ipairs, openers)):
                ___2, opener = unpack([_iteration_10008], 2)
                search_from = 1
                while True:
                    col = first(method(line.masked_text, b'find', opener, search_from, True))
                    if not truth(col):
                        break
                    boundary = first(call(find_next_plain, line.masked_text, CLAUSE_BOUNDARIES, col + length(opener)))
                    clause = _condition_10010 if truth((_condition_10010 := (first(method(line.masked_text, b'sub', col, boundary - 1)) if truth((_condition_10009 := boundary)) else _condition_10009))) else first(method(line.masked_text, b'sub', col))
                    if (not truth(first(method(clause, b'find', '了'.encode('utf-8'), 1, True))) and (not truth(first(call(is_temporal_subordinate_clause, clause))))) and (not truth(first(call(has_any_plain, clause, T([(None, '就要主動'.encode('utf-8')), (None, '就要直接'.encode('utf-8')), (None, '就要先'.encode('utf-8')), (None, '就要再'.encode('utf-8')), (None, '就要立即'.encode('utf-8')), (None, '就要立刻'.encode('utf-8'))]))))):
                        call(add_issue, issues, document, rule, line.number, col)
                        break
                    search_from = col + length(opener)

def check_L128(document=None, issues=None, rule=None, *_ignored):
    for _iteration_10011 in first(call(ipairs, document.lines)):
        _, line = unpack([_iteration_10011], 2)
        if truth(first(call(is_noncode_text_line, line))):
            for _iteration_10012 in first(call(ipairs, COMPLETION_EVENT_VERBS)):
                ___2, verb = unpack([_iteration_10012], 2)
                pattern = concat('不'.encode('utf-8'), concat(verb, '了'.encode('utf-8')))
                search_from = 1
                while True:
                    col = first(method(line.masked_text, b'find', pattern, search_from, True))
                    if not truth(col):
                        break
                    end_pos = col + length(pattern) - 1
                    boundary = first(call(find_next_plain, line.masked_text, CLAUSE_BOUNDARIES, end_pos + 1))
                    clause = _condition_10014 if truth((_condition_10014 := (first(method(line.masked_text, b'sub', col, boundary - 1)) if truth((_condition_10013 := boundary)) else _condition_10013))) else first(method(line.masked_text, b'sub', col))
                    tail = first(call(core.trim, method(clause, b'sub', length(pattern) + 1)))
                    if first(call(core.visible_length, tail)) >= 2:
                        call(add_issue, issues, document, rule, line.number, col)
                        break
                    search_from = col + length(pattern)

def check_L120(document=None, issues=None, rule=None, *_ignored):
    for _iteration_10015 in first(call(ipairs, document.lines)):
        _, line = unpack([_iteration_10015], 2)
        if truth(first(call(is_noncode_text_line, line))):
            for _iteration_10016 in first(call(ipairs, GENERIC_YOU_VERBS)):
                ___2, verb = unpack([_iteration_10016], 2)
                pattern = concat('有'.encode('utf-8'), verb)
                search_from = 1
                while True:
                    col = first(method(line.masked_text, b'find', pattern, search_from, True))
                    if not truth(col):
                        break
                    prev_char = first(call(previous_utf8_char, line.masked_text, col))
                    if (prev_char != '沒'.encode('utf-8') and prev_char != '没'.encode('utf-8')) and prev_char != '所'.encode('utf-8'):
                        call(add_issue, issues, document, rule, line.number, col)
                        break
                    search_from = col + length(pattern)

def check_L013(document=None, issues=None, rule=None, *_ignored):
    suspicious_prefixes = T([(None, '每天'.encode('utf-8')), (None, '通常'.encode('utf-8')), (None, '一般'.encode('utf-8')), (None, '常常'.encode('utf-8')), (None, '慣常'.encode('utf-8')), (None, '定義上'.encode('utf-8')), (None, '代表'.encode('utf-8')), (None, '屬於'.encode('utf-8')), (None, '負責'.encode('utf-8')), (None, '用來'.encode('utf-8'))])
    state_change_signals = T([(None, '快要'.encode('utf-8')), (None, '就要'.encode('utf-8')), (None, '已經'.encode('utf-8')), (None, '曾'.encode('utf-8')), (None, '剛'.encode('utf-8')), (None, '沒有'.encode('utf-8')), (None, '沒'.encode('utf-8')), (None, '終於'.encode('utf-8')), (None, '總算'.encode('utf-8')), (None, '才'.encode('utf-8')), (None, '現在'.encode('utf-8')), (None, '如今'.encode('utf-8')), (None, '從此'.encode('utf-8')), (None, '最近'.encode('utf-8')), (None, '愈來愈'.encode('utf-8')), (None, '越來越'.encode('utf-8')), (None, '變得'.encode('utf-8')), (None, '變成'.encode('utf-8')), (None, '開始'.encode('utf-8')), (None, '更'.encode('utf-8'))])
    for _iteration_10017 in first(call(ipairs, call(prose_lines, document))):
        _, line = unpack([_iteration_10017], 2)
        if not truth(first(call(has_any_plain, line.masked_text, state_change_signals))):
            search_from = 1
            while True:
                col = first(method(line.masked_text, b'find', '了'.encode('utf-8'), search_from, True))
                if not truth(col):
                    break
                if not truth(first(call(is_lexical_le, line.masked_text, col))):
                    prefix_col = first(call(find_nearby_prefix_before, line.masked_text, col, suspicious_prefixes, 12))
                    if truth(prefix_col):
                        call(add_issue, issues, document, rule, line.number, col)
                        break
                search_from = col + length('了'.encode('utf-8'))

def check_L103(document=None, issues=None, rule=None, *_ignored):
    for _iteration_10018 in first(call(ipairs, call(prose_lines, document))):
        _, line = unpack([_iteration_10018], 2)
        for _iteration_10019 in first(call(ipairs, T([(None, '是有'.encode('utf-8')), (None, '有是'.encode('utf-8'))]))):
            ___2, pattern = unpack([_iteration_10019], 2)
            col = first(method(line.masked_text, b'find', pattern, 1, True))
            prev_char = _condition_10021 if truth((_condition_10021 := (first(call(previous_utf8_char, line.masked_text, col)) if truth((_condition_10020 := col)) else _condition_10020))) else None
            if truth(col) and (not (pattern == '是有'.encode('utf-8') and prev_char == '還'.encode('utf-8'))):
                call(add_issue, issues, document, rule, line.number, col)
                break

def check_L112(document=None, issues=None, rule=None, *_ignored):
    for _iteration_10022 in first(call(ipairs, call(prose_lines, document))):
        _, line = unpack([_iteration_10022], 2)
        search_from = 1
        while True:
            col = first(method(line.masked_text, b'find', '有'.encode('utf-8'), search_from, True))
            if not truth(col):
                break
            prev_char = first(call(previous_utf8_char, line.masked_text, col))
            clause = first(call(clause_window, line.masked_text, col + length('有'.encode('utf-8'))))
            if ((not truth(prev_char) or ((prev_char != '沒'.encode('utf-8') and prev_char != '没'.encode('utf-8')) and prev_char != '擁'.encode('utf-8'))) and truth(first(call(is_clause_start_before, line.masked_text, col)))) and truth(first(call(contains_definite_marker, clause))):
                call(add_issue, issues, document, rule, line.number, col)
                break
            search_from = col + length('有'.encode('utf-8'))

def check_L121(document=None, issues=None, rule=None, *_ignored):
    for _iteration_10023 in first(call(ipairs, call(prose_lines, document))):
        _, line = unpack([_iteration_10023], 2)
        for _iteration_10024 in first(call(ipairs, NONAGENTIVE_SUBJECTS)):
            ___2, subject = unpack([_iteration_10024], 2)
            subject_col = first(method(line.masked_text, b'find', subject, 1, True))
            if truth(subject_col):
                clause = first(call(clause_window, line.masked_text, subject_col))
                for _iteration_10025 in first(call(ipairs, CONTROL_MODALS)):
                    ___3, modal = unpack([_iteration_10025], 2)
                    modal_col = first(method(clause, b'find', modal, 1, True))
                    if truth(modal_col) and modal_col <= 18:
                        call(add_issue, issues, document, rule, line.number, subject_col)
                        break

def check_L129(document=None, issues=None, rule=None, *_ignored):
    event_count_classifiers = T([(None, '次'.encode('utf-8')), (None, '遍'.encode('utf-8')), (None, '回'.encode('utf-8')), (None, '輪'.encode('utf-8')), (None, '天'.encode('utf-8')), (None, '月'.encode('utf-8')), (None, '年'.encode('utf-8')), (None, '分鐘'.encode('utf-8')), (None, '小時'.encode('utf-8'))])
    for _iteration_10026 in first(call(ipairs, call(prose_lines, document))):
        _, line = unpack([_iteration_10026], 2)
        trimmed = first(call(core.trim, line.masked_text))
        if ((first(method(trimmed, b'sub', -length('了'.encode('utf-8')))) == '了'.encode('utf-8') or first(method(trimmed, b'sub', -length('了。'.encode('utf-8')))) == '了。'.encode('utf-8')) or first(method(trimmed, b'sub', -length('了！'.encode('utf-8')))) == '了！'.encode('utf-8')) or first(method(trimmed, b'sub', -length('了？'.encode('utf-8')))) == '了？'.encode('utf-8'):
            clause, clause_start = unpack([call(find_final_clause, line.masked_text)], 2)
            for _iteration_10027 in first(call(ipairs, event_count_classifiers)):
                ___2, classifier = unpack([_iteration_10027], 2)
                digit_col = first(method(clause, b'find', concat(b'%d+', classifier)))
                if truth(digit_col) and (not truth(first(method(first(method(clause, b'sub', 1, digit_col - 1)), b'find', '了'.encode('utf-8'), 1, True)))):
                    call(add_issue, issues, document, rule, line.number, clause_start + digit_col - 1)
                    break
                for _iteration_10028 in first(call(ipairs, COUNT_PREFIXES)):
                    ___3, prefix = unpack([_iteration_10028], 2)
                    phrase = concat(prefix, classifier)
                    col = first(method(clause, b'find', phrase, 1, True))
                    if truth(col):
                        absolute_col = clause_start + col - 1
                        prev_char = first(call(previous_utf8_char, line.masked_text, absolute_col))
                        if prev_char != '第'.encode('utf-8') and (not truth(first(method(first(method(clause, b'sub', 1, col - 1)), b'find', '了'.encode('utf-8'), 1, True)))):
                            call(add_issue, issues, document, rule, line.number, absolute_col)
                            break
from lintlib.rules import run_checks

def check(document: dict, selected: set[str]) -> list[dict]:
    return run_checks(document, selected, CHECKS)
CHECKS = {'L113': check_L113, 'L126': check_L126, 'L125': check_L125, 'L127': check_L127, 'L128': check_L128, 'L120': check_L120, 'L013': check_L013, 'L103': check_L103, 'L112': check_L112, 'L121': check_L121, 'L129': check_L129}
