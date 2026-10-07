"""Domain predicates with shared byte-oriented analysis."""
from lintlib.byte_patterns import T, get, set_, truth, first, unpack, call, concat, length, method, table, ipairs
from lintlib.clauses import ABSTRACT_TAXONOMY_TERMS, add_issue, core, count_strong_sentences, count_term_hits, has_concrete_anchor, has_expansion_signal

def check_L007(document=None, issues=None, rule=None, *_ignored):
    reported = T([])

    def report(line_number=None, col=None, *_ignored):
        key = concat(line_number, concat(b':', col))
        if truth(get(reported, key)):
            return None
        set_(reported, key, True)
        call(add_issue, issues, document, rule, line_number, col)
    opener_bare_patterns = T([(None, '不是'.encode('utf-8')), (None, '所謂'.encode('utf-8')), (None, '這也意味著'.encode('utf-8'))])
    first__2 = document.first_paragraph
    if truth(first__2):
        opener = first(call(core.mask_inline_code, first__2.text))
        for _iteration_10001 in first(call(ipairs, opener_bare_patterns)):
            _, pattern = unpack([_iteration_10001], 2)
            col = first(method(opener, b'find', pattern, 1, True))
            if truth(col) and col <= 12:
                call(report, first__2.start_line, col)
                break
    pair_patterns = T([(None, T([(b'first', '不是'.encode('utf-8')), (b'second', '而是'.encode('utf-8'))])), (None, T([(b'first', '不是'.encode('utf-8')), (b'second', '其實'.encode('utf-8'))])), (None, T([(b'first', '不是'.encode('utf-8')), (b'second', '真正'.encode('utf-8'))])), (None, T([(b'first', '並非'.encode('utf-8')), (b'second', '而是'.encode('utf-8'))])), (None, T([(b'first', '並非'.encode('utf-8')), (b'second', '其實'.encode('utf-8'))])), (None, T([(b'first', '並非'.encode('utf-8')), (b'second', '真正'.encode('utf-8'))])), (None, T([(b'first', '所謂'.encode('utf-8')), (b'second', '就是'.encode('utf-8'))])), (None, T([(b'first', '可被'.encode('utf-8')), (b'second', '所'.encode('utf-8'))]))])
    standalone_patterns = T([(None, '這也意味著'.encode('utf-8')), (None, '被組織成'.encode('utf-8')), (None, '為目標來'.encode('utf-8')), (None, '一種常見方法'.encode('utf-8')), (None, '指令取回後'.encode('utf-8')), (None, '文獻中被提出'.encode('utf-8'))])
    for _iteration_10002 in first(call(ipairs, document.paragraphs)):
        ___2, paragraph = unpack([_iteration_10002], 2)
        masked_lines = T([])
        for _iteration_10003 in first(call(ipairs, paragraph.lines)):
            ___3, line = unpack([_iteration_10003], 2)
            call(table.insert, masked_lines, call(core.mask_inline_code, line.text))
        for _iteration_10004 in first(call(ipairs, pair_patterns)):
            ___4, pair = unpack([_iteration_10004], 2)
            for _iteration_10005 in first(call(ipairs, masked_lines)):
                i, masked = unpack([_iteration_10005], 2)
                search_from = 1
                while True:
                    first_col = first(method(masked, b'find', pair.first, search_from, True))
                    if not truth(first_col):
                        break
                    found_second = False
                    rest = first(method(masked, b'sub', first_col + length(pair.first)))
                    if truth(first(method(rest, b'find', pair.second, 1, True))):
                        found_second = True
                    else:
                        _start_10006, _stop_10007, _step_10008 = (i + 1, length(masked_lines), 1)
                        for j in range(int(_start_10006), int(_stop_10007) + (1 if _step_10008 > 0 else -1), int(_step_10008)):
                            if truth(first(method(get(masked_lines, j), b'find', pair.second, 1, True))):
                                found_second = True
                                break
                    if truth(found_second):
                        call(report, get(paragraph.lines, i).number, first_col)
                    search_from = first_col + length(pair.first)
        for _iteration_10009 in first(call(ipairs, standalone_patterns)):
            ___5, pattern__2 = unpack([_iteration_10009], 2)
            for _iteration_10010 in first(call(ipairs, masked_lines)):
                i__2, masked__2 = unpack([_iteration_10010], 2)
                search_from__2 = 1
                while True:
                    col__2 = first(method(masked__2, b'find', pattern__2, search_from__2, True))
                    if not truth(col__2):
                        break
                    call(report, get(paragraph.lines, i__2).number, col__2)
                    search_from__2 = col__2 + length(pattern__2)

def check_L020(document=None, issues=None, rule=None, *_ignored):
    for _iteration_10011 in first(call(ipairs, document.paragraphs)):
        _, paragraph = unpack([_iteration_10011], 2)
        sentence_count = first(call(count_strong_sentences, paragraph.text))
        semicolon_count = first(call(core.count_substring, paragraph.text, '；'.encode('utf-8'))) + first(call(core.count_substring, paragraph.text, b';'))
        if ((paragraph.line_count > 7 or paragraph.visible_length >= 520) or (paragraph.visible_length >= 280 and sentence_count >= 4)) or (paragraph.visible_length >= 180 and semicolon_count >= 2):
            call(add_issue, issues, document, rule, paragraph.start_line, 1)

def check_L034(document=None, issues=None, rule=None, *_ignored):
    for _iteration_10012 in first(call(ipairs, document.paragraphs)):
        _, paragraph = unpack([_iteration_10012], 2)
        text = paragraph.text
        if paragraph.visible_length >= 24:
            abstract_hits = first(call(count_term_hits, text, ABSTRACT_TAXONOMY_TERMS))
            if (abstract_hits >= 3 and (not truth(first(call(has_concrete_anchor, text))))) and (not truth(first(call(has_expansion_signal, text)))):
                call(add_issue, issues, document, rule, paragraph.start_line, 1)
from lintlib.rules import run_checks

def check(document: dict, selected: set[str]) -> list[dict]:
    return run_checks(document, selected, CHECKS)
CHECKS = {'L007': check_L007, 'L020': check_L020, 'L034': check_L034}
