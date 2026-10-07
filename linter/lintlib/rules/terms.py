"""Domain predicates with shared byte-oriented analysis."""
from lintlib.byte_patterns import T, get, set_, truth, first, unpack, call, concat, length, method, table, pairs, ipairs, next_
from lintlib.clauses import PREFERRED_TAIWAN_TERMS, SIMPLIFIED_CHARS, WORKSPACE_JARGON, add_issue, bilingual_order_lines, core, find_bare_english_drift_col, has_expansion_signal, is_descriptive_chinese_parenthetical, is_markdown_image_line, is_noncode_text_line, is_term_like_chinese, is_write_back_term_usage, matches_glossary_preferred_form, parenthetical_content_at, preferred_term_message, prose_lines, should_track_bare_english_drift_anchor, should_warn_preferred_term, span_overlaps, visible_text_lines

def check_L022(document=None, issues=None, rule=None, *_ignored):
    for _iteration_10001 in first(call(ipairs, document.lines)):
        _, line = unpack([_iteration_10001], 2)
        if ((not truth(line.is_blank) and (not truth(line.is_code))) and (not truth(line.is_tag))) and (not truth(line.is_directive)):
            for _iteration_10002 in first(call(ipairs, call(core.codepoints, line.masked_text))):
                ___2, item = unpack([_iteration_10002], 2)
                if truth(get(SIMPLIFIED_CHARS, item.cp)):
                    call(add_issue, issues, document, rule, line.number, item.pos)
                    break

def check_L030(document=None, issues=None, rule=None, *_ignored):
    seen = T([])
    for _iteration_10003 in first(call(ipairs, document.lines)):
        _, line = unpack([_iteration_10003], 2)
        if not truth(line.is_code):
            for _iteration_10004 in first(call(ipairs, call(core.extract_bilingual_pairs, line.masked_text))):
                ___2, pair = unpack([_iteration_10004], 2)
                if truth(first(call(is_term_like_chinese, pair.chinese))):
                    english = first(call(core.normalize_english_term, pair.english))
                    chinese = first(call(core.normalize_chinese_term, pair.chinese))
                    key = concat(english, concat(b'||', chinese))
                    if truth(get(seen, key)):
                        call(add_issue, issues, document, rule, line.number, pair.col)
                    else:
                        set_(seen, key, True)

def check_L031(document=None, issues=None, rule=None, *_ignored):
    seen = T([])
    for _iteration_10005 in first(call(ipairs, document.lines)):
        _, line = unpack([_iteration_10005], 2)
        if not truth(line.is_code) and (not truth(line.is_table)):
            for _iteration_10006 in first(call(ipairs, call(core.extract_bilingual_pairs, line.masked_text))):
                ___2, pair = unpack([_iteration_10006], 2)
                if truth(first(call(is_term_like_chinese, pair.chinese))):
                    english = first(call(core.normalize_english_term, pair.english))
                    chinese = first(call(core.normalize_chinese_term, pair.chinese))
                    previous = get(seen, english)
                    if truth(previous) and previous != chinese:
                        call(add_issue, issues, document, rule, line.number, pair.col)
                    else:
                        set_(seen, english, chinese)

def check_L033(document=None, issues=None, rule=None, *_ignored):
    seen = T([])
    lines = first(call(prose_lines, document))
    for _iteration_10007 in first(call(ipairs, lines)):
        index, line = unpack([_iteration_10007], 2)
        next_line = get(lines, index + 1)
        combined = concat(line.text, concat(b' ', first(_condition_10009 if truth((_condition_10009 := (next_line.text if truth((_condition_10008 := next_line)) else _condition_10008))) else b'')))
        for _iteration_10010 in first(call(ipairs, WORKSPACE_JARGON)):
            _, jargon = unpack([_iteration_10010], 2)
            col = first(method(line.masked_text, b'find', jargon, 1, True))
            if truth(col) and (not truth(get(seen, jargon))):
                set_(seen, jargon, True)
                if not truth(first(call(has_expansion_signal, combined))):
                    call(add_issue, issues, document, rule, line.number, col)

def check_L032(document=None, issues=None, rule=None, *_ignored):
    glossary = _condition_10011 if truth((_condition_10011 := document.glossary)) else T([])
    if first(call(next_, glossary)) == None:
        return None
    for _iteration_10012 in first(call(ipairs, document.lines)):
        _, line = unpack([_iteration_10012], 2)
        if not truth(line.is_code) and (not truth(line.is_table)):
            for _iteration_10013 in first(call(ipairs, call(core.extract_bilingual_pairs, line.masked_text))):
                ___2, pair = unpack([_iteration_10013], 2)
                if truth(first(call(is_term_like_chinese, pair.chinese))):
                    english = first(call(core.normalize_english_term, pair.english))
                    chinese = first(call(core.normalize_chinese_term, pair.chinese))
                    entry = get(glossary, english)
                    if (truth(entry) and chinese != b'') and (not truth(first(call(matches_glossary_preferred_form, entry, chinese)))):
                        call(add_issue, issues, document, rule, line.number, pair.col)

def check_L035(document=None, issues=None, rule=None, *_ignored):
    for _iteration_10014 in first(call(ipairs, document.lines)):
        _, line = unpack([_iteration_10014], 2)
        if truth(first(call(is_noncode_text_line, line))):
            search_from = 1
            while True:
                col = first(method(line.masked_text, b'find', '回寫'.encode('utf-8'), search_from, True))
                if not truth(col):
                    break
                if not truth(first(call(is_write_back_term_usage, line.masked_text, col))):
                    call(add_issue, issues, document, rule, line.number, col)
                    break
                search_from = col + length('回寫'.encode('utf-8'))

def check_L046(document=None, issues=None, rule=None, *_ignored):
    for _iteration_10015 in first(call(ipairs, call(bilingual_order_lines, document))):
        _, line = unpack([_iteration_10015], 2)
        if not truth(first(call(is_markdown_image_line, line))):
            for _iteration_10016 in first(call(ipairs, call(core.extract_bilingual_pairs, line.masked_text))):
                ___2, pair = unpack([_iteration_10016], 2)
                raw_inner = _condition_10017 if truth((_condition_10017 := first(call(parenthetical_content_at, line.text, pair.col)))) else pair.inner
                if ((truth(first(call(core.contains_ascii_letter, pair.outer))) and (not truth(first(method(pair.outer, b'find', b'%d'))))) and truth(first(call(is_term_like_chinese, pair.inner)))) and (not truth(first(call(is_descriptive_chinese_parenthetical, raw_inner)))):
                    call(add_issue, issues, document, rule, line.number, pair.col)

def check_L053(document=None, issues=None, rule=None, *_ignored):
    for _iteration_10018 in first(call(ipairs, call(visible_text_lines, document))):
        _, line = unpack([_iteration_10018], 2)
        if not truth(first(call(is_markdown_image_line, line))):
            reported_spans = T([])
            for _iteration_10019 in first(call(ipairs, PREFERRED_TAIWAN_TERMS)):
                ___2, entry = unpack([_iteration_10019], 2)
                search_from = 1
                while True:
                    col = first(method(line.masked_text, b'find', entry.term, search_from, True))
                    if not truth(col):
                        break
                    end_col = col + length(entry.term) - 1
                    if not truth(first(call(span_overlaps, reported_spans, col, end_col))) and truth(first(call(should_warn_preferred_term, entry, line.masked_text, col))):
                        call(add_issue, issues, document, rule, line.number, col, call(preferred_term_message, entry))
                        call(table.insert, reported_spans, T([(b'start_col', col), (b'end_col', end_col)]))
                    search_from = col + length(entry.term)

def check_L054(document=None, issues=None, rule=None, *_ignored):
    anchors = T([])
    for _iteration_10020 in first(call(ipairs, document.lines)):
        _, line = unpack([_iteration_10020], 2)
        if not truth(line.is_code) and (not truth(line.is_table)):
            for _iteration_10021 in first(call(ipairs, call(core.extract_bilingual_pairs, line.masked_text))):
                ___2, pair = unpack([_iteration_10021], 2)
                raw_inner = _condition_10022 if truth((_condition_10022 := first(call(parenthetical_content_at, line.text, pair.col)))) else pair.inner
                if (pair.outer == pair.chinese and truth(first(call(is_term_like_chinese, pair.chinese)))) and (not truth(first(method(raw_inner, b'find', b'`', 1, True)))):
                    raw_english = first(call(core.trim, pair.english))
                    english_key = first(call(core.normalize_english_term, raw_english))
                    if truth(first(call(should_track_bare_english_drift_anchor, raw_english, english_key))) and (not truth(get(anchors, english_key))):
                        set_(anchors, english_key, T([(b'line', line.number), (b'col', pair.col)]))
    if first(call(next_, anchors)) == None:
        return None
    for _iteration_10023 in first(call(ipairs, document.lines)):
        ___3, line__2 = unpack([_iteration_10023], 2)
        if ((((not truth(line__2.is_blank) and (not truth(line__2.is_code))) and (not truth(line__2.is_tag))) and (not truth(line__2.is_directive))) and (not truth(line__2.is_table))) and (not truth(line__2.is_heading)):
            for _iteration_10024 in first(call(pairs, anchors)):
                english_key__2, anchor = unpack([_iteration_10024], 2)
                if line__2.number > anchor.line:
                    col = first(call(find_bare_english_drift_col, line__2, english_key__2))
                    if truth(col):
                        call(add_issue, issues, document, rule, line__2.number, col)
                        break
from lintlib.rules import run_checks

def check(document: dict, selected: set[str]) -> list[dict]:
    return run_checks(document, selected, CHECKS)
CHECKS = {'L022': check_L022, 'L030': check_L030, 'L031': check_L031, 'L033': check_L033, 'L032': check_L032, 'L035': check_L035, 'L046': check_L046, 'L053': check_L053, 'L054': check_L054}
