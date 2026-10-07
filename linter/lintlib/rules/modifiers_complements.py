"""Domain predicates with shared byte-oriented analysis."""
from lintlib.byte_patterns import T, truth, first, unpack, call, concat, length, method, ipairs
from lintlib.clauses import ABSTRACT_EVENT_NOUNS, DEGREE_MARKERS, DESCRIPTION_OBJECTS, DURATION_OR_COUNT_MARKERS, EVENT_NOMINALIZATION_TAIL_MARKERS, HIGH_RISK_MISSING_COMPLEMENT_DE, HIGH_RISK_MISSING_DE_PHRASES, HIGH_RISK_MISSING_DI_PHRASES, OVERLOADED_POSTVERBAL_VERBS, add_issue, core, find_dense_de_chain_col, has_any_plain, prose_lines, starts_with_any

def check_L008(document=None, issues=None, rule=None, *_ignored):
    for _iteration_10001 in first(call(ipairs, call(prose_lines, document))):
        _, line = unpack([_iteration_10001], 2)
        col = first(call(find_dense_de_chain_col, line.masked_text))
        if truth(col):
            call(add_issue, issues, document, rule, line.number, col)

def check_L012(document=None, issues=None, rule=None, *_ignored):
    patterns = T([(None, '的很'.encode('utf-8')), (None, '地流程'.encode('utf-8')), (None, '地方法'.encode('utf-8')), (None, '地測試'.encode('utf-8')), (None, '得流程'.encode('utf-8')), (None, '得方法'.encode('utf-8')), (None, '得測試'.encode('utf-8'))])

    def should_ignore(pattern=None, text=None, col=None, *_ignored):
        if pattern == '的很'.encode('utf-8'):
            prev = first(method(text, b'sub', col - length('真'.encode('utf-8')), col - 1))
            return prev == '真'.encode('utf-8')
        if pattern == '地測試'.encode('utf-8'):
            prev__2 = first(method(text, b'sub', col - length('可靠'.encode('utf-8')), col - 1))
            return prev__2 == '可靠'.encode('utf-8')
        return False
    for _iteration_10002 in first(call(ipairs, call(prose_lines, document))):
        _, line = unpack([_iteration_10002], 2)
        reported = False
        for _iteration_10003 in first(call(ipairs, patterns)):
            ___2, pattern = unpack([_iteration_10003], 2)
            search_from = 1
            while not truth(reported):
                col = first(method(line.masked_text, b'find', pattern, search_from, True))
                if not truth(col):
                    break
                if not truth(first(call(should_ignore, pattern, line.masked_text, col))):
                    call(add_issue, issues, document, rule, line.number, col)
                    reported = True
                    break
                search_from = col + length(pattern)
            if truth(reported):
                break

def check_L114(document=None, issues=None, rule=None, *_ignored):
    for _iteration_10008 in first(call(ipairs, call(prose_lines, document))):
        _, line = unpack([_iteration_10008], 2)
        for _iteration_10009 in first(call(ipairs, DESCRIPTION_OBJECTS)):
            ___2, object = unpack([_iteration_10009], 2)
            for _iteration_10010 in first(call(ipairs, DEGREE_MARKERS)):
                ___3, degree = unpack([_iteration_10010], 2)
                pattern = concat('得'.encode('utf-8'), concat(object, degree))
                col = first(method(line.masked_text, b'find', pattern, 1, True))
                if truth(col):
                    call(add_issue, issues, document, rule, line.number, col)
                    break

def check_L115(document=None, issues=None, rule=None, *_ignored):
    complements = T([(None, '清楚'.encode('utf-8')), (None, '完整'.encode('utf-8')), (None, '明白'.encode('utf-8')), (None, '完成'.encode('utf-8')), (None, '完'.encode('utf-8')), (None, '好'.encode('utf-8'))])
    for _iteration_10011 in first(call(ipairs, call(prose_lines, document))):
        _, line = unpack([_iteration_10011], 2)
        if not truth(first(method(line.masked_text, b'find', '得'.encode('utf-8'), 1, True))):
            for _iteration_10012 in first(call(ipairs, OVERLOADED_POSTVERBAL_VERBS)):
                ___2, verb = unpack([_iteration_10012], 2)
                col = first(method(line.masked_text, b'find', verb, 1, True))
                if (truth(col) and truth(first(call(has_any_plain, line.masked_text, DURATION_OR_COUNT_MARKERS)))) and truth(first(call(has_any_plain, line.masked_text, complements))):
                    call(add_issue, issues, document, rule, line.number, col)
                    break

def check_L122(document=None, issues=None, rule=None, *_ignored):
    for _iteration_10013 in first(call(ipairs, call(prose_lines, document))):
        _, line = unpack([_iteration_10013], 2)
        for _iteration_10014 in first(call(ipairs, HIGH_RISK_MISSING_DE_PHRASES)):
            ___2, phrase = unpack([_iteration_10014], 2)
            col = first(method(line.masked_text, b'find', phrase, 1, True))
            if truth(col):
                call(add_issue, issues, document, rule, line.number, col)
                break

def check_L123(document=None, issues=None, rule=None, *_ignored):
    for _iteration_10015 in first(call(ipairs, call(prose_lines, document))):
        _, line = unpack([_iteration_10015], 2)
        for _iteration_10016 in first(call(ipairs, HIGH_RISK_MISSING_DI_PHRASES)):
            ___2, phrase = unpack([_iteration_10016], 2)
            col = first(method(line.masked_text, b'find', phrase, 1, True))
            if truth(col):
                call(add_issue, issues, document, rule, line.number, col)
                break

def check_L124(document=None, issues=None, rule=None, *_ignored):
    for _iteration_10017 in first(call(ipairs, call(prose_lines, document))):
        _, line = unpack([_iteration_10017], 2)
        for _iteration_10018 in first(call(ipairs, HIGH_RISK_MISSING_COMPLEMENT_DE)):
            ___2, phrase = unpack([_iteration_10018], 2)
            col = first(method(line.masked_text, b'find', phrase, 1, True))
            if truth(col):
                call(add_issue, issues, document, rule, line.number, col)
                break
from lintlib.rules import run_checks
CHECKS = {'L008': check_L008, 'L012': check_L012, 'L114': check_L114, 'L115': check_L115, 'L122': check_L122, 'L123': check_L123, 'L124': check_L124}

def event_nominalization_candidates(line):
    """Original noun order, first occurrence per noun, 18-byte left window."""
    from lintlib.byte_patterns import B
    text = line.masked_text
    de_count = text.count(B('的'))
    for _, noun in ipairs(ABSTRACT_EVENT_NOUNS):
        pattern = B('的') + noun
        position = text.find(pattern)
        if position < 0:
            continue
        tail = core.trim(text[position + len(pattern):])
        if starts_with_any(tail, EVENT_NOMINALIZATION_TAIL_MARKERS):
            yield (position + 1, de_count >= 2 and B('的') in text[max(0, position - 18):position])

def check(document: dict, selected: set[str]) -> list[dict]:
    from lintlib.byte_patterns import from_native
    from lintlib.rules import make_warning
    warnings = run_checks(document, selected, CHECKS)
    if selected & {'L105', 'L108'}:
        for _, line in ipairs(prose_lines(from_native(document))):
            remaining = selected & {'L105', 'L108'}
            for byte_col, has_previous_de in event_nominalization_candidates(line):
                if 'L108' in remaining:
                    warnings.append(make_warning(document, 'L108', line.number, byte_col))
                    remaining.remove('L108')
                if 'L105' in remaining and has_previous_de:
                    warnings.append(make_warning(document, 'L105', line.number, byte_col))
                    remaining.remove('L105')
                if not remaining:
                    break
    return warnings
