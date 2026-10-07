"""Domain predicates with shared byte-oriented analysis."""
from lintlib.byte_patterns import T, truth, first, unpack, call, concat, length, method, ipairs
from lintlib.clauses import BARE_BA_VERBS, REPEATED_SUBJECT_HEADS, SHOU_BARE_EVENT_VERBS, add_issue, clause_window, core, count_plain_occurrences, has_any_plain, has_result_marker, prose_lines, split_strong_sentences, starts_with_any, starts_with_count_phrase, starts_with_temporal_count_phrase

def check_L009(document=None, issues=None, rule=None, *_ignored):
    for _iteration_10001 in first(call(ipairs, call(prose_lines, document))):
        _, line = unpack([_iteration_10001], 2)
        for _iteration_10002 in first(call(ipairs, call(split_strong_sentences, line.masked_text))):
            ___2, segment = unpack([_iteration_10002], 2)
            for _iteration_10003 in first(call(ipairs, REPEATED_SUBJECT_HEADS)):
                ___3, head = unpack([_iteration_10003], 2)
                escaped = first(call(core.escape_pattern, head))
                pattern = concat(escaped, concat('.-[，；]'.encode('utf-8'), escaped))
                col = first(method(segment.text, b'find', pattern))
                if truth(col):
                    call(add_issue, issues, document, rule, line.number, segment.start_pos + col - 1)
                    break

def check_L010(document=None, issues=None, rule=None, *_ignored):
    for _iteration_10004 in first(call(ipairs, call(prose_lines, document))):
        _, line = unpack([_iteration_10004], 2)
        for _iteration_10005 in first(call(ipairs, call(split_strong_sentences, line.masked_text))):
            ___2, segment = unpack([_iteration_10005], 2)
            if first(call(core.count_substring, segment.text, '被'.encode('utf-8'))) >= 2:
                col = _condition_10006 if truth((_condition_10006 := first(method(segment.text, b'find', '被'.encode('utf-8'), 1, True)))) else 1
                call(add_issue, issues, document, rule, line.number, segment.start_pos + col - 1)
                break

def check_L101(document=None, issues=None, rule=None, *_ignored):
    for _iteration_10008 in first(call(ipairs, call(prose_lines, document))):
        _, line = unpack([_iteration_10008], 2)
        trimmed = first(call(core.trim, line.masked_text))
        comma = _condition_10009 if truth((_condition_10009 := first(method(trimmed, b'find', '，'.encode('utf-8'), 1, True)))) else first(method(trimmed, b'find', b',', 1, True))
        if ((truth(comma) and comma <= 24) and truth(first(call(starts_with_count_phrase, trimmed)))) and (not truth(first(call(starts_with_temporal_count_phrase, trimmed)))):
            call(add_issue, issues, document, rule, line.number, call(core.first_nonspace_col, line.text))

def check_L102(document=None, issues=None, rule=None, *_ignored):
    pronouns = T([(None, '他們'.encode('utf-8')), (None, '她們'.encode('utf-8')), (None, '它們'.encode('utf-8')), (None, '他'.encode('utf-8')), (None, '她'.encode('utf-8')), (None, '它'.encode('utf-8'))])
    for _iteration_10010 in first(call(ipairs, call(prose_lines, document))):
        _, line = unpack([_iteration_10010], 2)
        self_pos = first(method(line.masked_text, b'find', '自己'.encode('utf-8'), 1, True))
        if truth(self_pos):
            prefix = first(method(line.masked_text, b'sub', 1, self_pos - 1))
            count = first(call(count_plain_occurrences, prefix, pronouns))
            if count >= 2 or (count >= 1 and truth(first(method(prefix, b'find', '被'.encode('utf-8'), 1, True)))):
                call(add_issue, issues, document, rule, line.number, self_pos)

def check_L106(document=None, issues=None, rule=None, *_ignored):
    indefinite_markers = T([(None, '一個'.encode('utf-8')), (None, '一些'.encode('utf-8')), (None, '某個'.encode('utf-8')), (None, '某種'.encode('utf-8')), (None, '很多'.encode('utf-8')), (None, '不少'.encode('utf-8')), (None, '幾個'.encode('utf-8')), (None, '數個'.encode('utf-8')), (None, '任何'.encode('utf-8'))])
    for _iteration_10011 in first(call(ipairs, call(prose_lines, document))):
        _, line = unpack([_iteration_10011], 2)
        col = first(method(line.masked_text, b'find', '把'.encode('utf-8'), 1, True))
        if truth(col):
            rest = first(call(core.trim, method(line.masked_text, b'sub', col + length('把'.encode('utf-8')))))
            if truth(first(call(starts_with_count_phrase, rest))) or truth(first(call(starts_with_any, rest, indefinite_markers))):
                call(add_issue, issues, document, rule, line.number, col)

def check_L111(document=None, issues=None, rule=None, *_ignored):
    for _iteration_10013 in first(call(ipairs, call(prose_lines, document))):
        _, line = unpack([_iteration_10013], 2)
        for _iteration_10014 in first(call(ipairs, T([(None, '受'.encode('utf-8')), (None, '受到'.encode('utf-8'))]))):
            ___2, opener = unpack([_iteration_10014], 2)
            col = first(method(line.masked_text, b'find', opener, 1, True))
            if truth(col):
                clause = first(call(clause_window, line.masked_text, col + length(opener)))
                if truth(first(call(has_any_plain, clause, SHOU_BARE_EVENT_VERBS))):
                    call(add_issue, issues, document, rule, line.number, col)
                    break

def check_L116(document=None, issues=None, rule=None, *_ignored):
    patterns = T([(None, '他的'.encode('utf-8')), (None, '她的'.encode('utf-8')), (None, '它的'.encode('utf-8'))])
    for _iteration_10015 in first(call(ipairs, call(prose_lines, document))):
        _, line = unpack([_iteration_10015], 2)
        for _iteration_10016 in first(call(ipairs, T([(None, '他'.encode('utf-8')), (None, '她'.encode('utf-8')), (None, '它'.encode('utf-8'))]))):
            ___2, pronoun = unpack([_iteration_10016], 2)
            clause = line.masked_text
            if truth(first(method(clause, b'find', pronoun, 1, True))) and truth(first(method(clause, b'find', concat(pronoun, '的'.encode('utf-8')), 1, True))):
                first__2 = first(method(clause, b'find', pronoun, 1, True))
                second = first(method(clause, b'find', concat(pronoun, '的'.encode('utf-8')), first__2 + length(pronoun), True))
                if truth(second):
                    call(add_issue, issues, document, rule, line.number, first__2)
                    break

def check_L118(document=None, issues=None, rule=None, *_ignored):
    for _iteration_10017 in first(call(ipairs, call(prose_lines, document))):
        _, line = unpack([_iteration_10017], 2)
        bei_col = first(method(line.masked_text, b'find', '被'.encode('utf-8'), 1, True))
        self_col = first(method(line.masked_text, b'find', '自己'.encode('utf-8'), 1, True))
        if (truth(bei_col) and truth(self_col)) and self_col > bei_col:
            before = first(call(core.trim, method(line.masked_text, b'sub', 1, bei_col - 1)))
            middle = first(call(core.trim, method(line.masked_text, b'sub', bei_col + length('被'.encode('utf-8')), self_col - 1)))
            if first(call(core.visible_length, before)) >= 1 and first(call(core.visible_length, middle)) >= 1:
                call(add_issue, issues, document, rule, line.number, self_col)
from lintlib.rules import run_checks
CHECKS = {'L009': check_L009, 'L010': check_L010, 'L101': check_L101, 'L102': check_L102, 'L106': check_L106, 'L111': check_L111, 'L116': check_L116, 'L118': check_L118}

def ba_candidates(document):
    """First 把 in each eligible line, with one clause/result analysis."""
    from lintlib.byte_patterns import from_native, B
    for _, line in ipairs(prose_lines(from_native(document))):
        byte_col = line.masked_text.find(B('把')) + 1
        if byte_col:
            clause = clause_window(line.masked_text, byte_col)
            yield (line, byte_col, clause, has_any_plain(clause, BARE_BA_VERBS), has_result_marker(clause))

def check(document: dict, selected: set[str]) -> list[dict]:
    from lintlib.byte_patterns import B
    from lintlib.rules import make_warning
    warnings = run_checks(document, selected, CHECKS)
    if selected & {'L011', 'L107'}:
        for line, byte_col, clause, has_verb, has_result in ba_candidates(document):
            if not has_verb or has_result:
                continue
            if 'L107' in selected:
                warnings.append(make_warning(document, 'L107', line.number, byte_col))
            markers = ('把字句', '把字', '語義', '結構', '補語')
            if 'L011' in selected and core.visible_length(clause) <= 22 and (not any((B(marker) in clause for marker in markers))):
                warnings.append(make_warning(document, 'L011', line.number, byte_col))
    return warnings
