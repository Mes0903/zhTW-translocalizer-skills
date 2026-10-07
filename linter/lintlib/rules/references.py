"""Domain predicates with shared byte-oriented analysis."""
from lintlib.byte_patterns import T, get, set_, truth, first, unpack, call, length, method, string, ipairs
from lintlib.clauses import add_file_issue, add_issue, bibliography_explanation_subbullets, bibliography_has_url, bibliography_section_lines, bibliography_url_subbullet_is_pure_url, core, formal_citation_links, has_reference_heading, is_markdown_image_line, is_unmasked_char, markdown_link_spans, markdown_link_url_has_tracking_param, punctuation_spacing_lines

def check_L015(document=None, issues=None, rule=None, *_ignored):
    citations = first(call(formal_citation_links, _condition_10001 if truth((_condition_10001 := document.prose_text)) else document.text))
    has_heading = first(call(has_reference_heading, document))
    entries = first(call(bibliography_section_lines, document))
    has_anchor = False
    for _iteration_10002 in first(call(ipairs, entries)):
        _, entry = unpack([_iteration_10002], 2)
        if truth(entry.anchor_id):
            has_anchor = True
            break
    if length(citations) > 0 and (not truth(has_heading)) or (length(citations) > 0 and (not truth(has_anchor))):
        call(add_file_issue, issues, document, rule)

def check_L016(document=None, issues=None, rule=None, *_ignored):
    citations = first(call(formal_citation_links, _condition_10003 if truth((_condition_10003 := document.prose_text)) else document.text))
    entries = first(call(bibliography_section_lines, document))
    anchor_to_label = T([])
    label_to_anchor = T([])
    for _iteration_10004 in first(call(ipairs, entries)):
        _, entry = unpack([_iteration_10004], 2)
        if truth(entry.anchor_id):
            if truth(get(anchor_to_label, entry.anchor_id)):
                call(add_file_issue, issues, document, rule)
                return None
            if truth(get(label_to_anchor, entry.label)) and get(label_to_anchor, entry.label) != entry.anchor_id:
                call(add_file_issue, issues, document, rule)
                return None
            set_(anchor_to_label, entry.anchor_id, entry.label)
            set_(label_to_anchor, entry.label, entry.anchor_id)
    for _iteration_10005 in first(call(ipairs, citations)):
        ___2, citation = unpack([_iteration_10005], 2)
        entry_label = get(anchor_to_label, citation.target)
        if not truth(entry_label) or entry_label != citation.label:
            call(add_file_issue, issues, document, rule)
            return None

def check_L042(document=None, issues=None, rule=None, *_ignored):
    for _iteration_10006 in first(call(ipairs, call(punctuation_spacing_lines, document))):
        _, line = unpack([_iteration_10006], 2)
        if not truth(first(call(is_markdown_image_line, line))):
            for _iteration_10007 in first(call(ipairs, call(markdown_link_spans, line.masked_text))):
                ___2, span = unpack([_iteration_10007], 2)
                if truth(first(call(markdown_link_url_has_tracking_param, span.url))):
                    call(add_issue, issues, document, rule, line.number, span.url_start_col)

def check_L055(document=None, issues=None, rule=None, *_ignored):
    entries, subbullets = unpack([call(bibliography_section_lines, document)], 2)
    for _iteration_10008 in first(call(ipairs, entries)):
        _, item = unpack([_iteration_10008], 2)
        if (truth(first(call(core.contains_cjk, item.body))) or truth(first(call(bibliography_has_url, item.body)))) or truth(first(method(item.body, b'match', b'%[[^%]]+%]%([^%)]+%)'))):
            call(add_issue, issues, document, rule, item.line.number, 1)
    for _iteration_10009 in first(call(ipairs, subbullets)):
        ___2, item__2 = unpack([_iteration_10009], 2)
        if truth(first(call(bibliography_has_url, item__2.body))) and (not truth(first(call(bibliography_url_subbullet_is_pure_url, item__2.body)))):
            call(add_issue, issues, document, rule, item__2.line.number, 1)

def check_L056(document=None, issues=None, rule=None, *_ignored):
    entries = first(call(bibliography_section_lines, document))
    for _iteration_10010 in first(call(ipairs, entries)):
        _, item = unpack([_iteration_10010], 2)
        col = _condition_10011 if truth((_condition_10011 := first(method(item.line.text, b'find', b'%u%.%u')))) else first(method(item.line.text, b'find', b'%u%.%u%l'))
        if truth(col):
            call(add_issue, issues, document, rule, item.line.number, col)

def check_L057(document=None, issues=None, rule=None, *_ignored):
    entries = first(call(bibliography_section_lines, document))
    patterns = T([(None, b'%f[%a]Vol%.%d'), (None, b'%f[%a]No%.%d'), (None, b'%f[%a]p%.%d'), (None, b'%f[%a]pp%.%d')])
    for _iteration_10012 in first(call(ipairs, entries)):
        _, item = unpack([_iteration_10012], 2)
        for _iteration_10013 in first(call(ipairs, patterns)):
            ___2, pattern = unpack([_iteration_10013], 2)
            col = first(method(item.line.text, b'find', pattern))
            if truth(col):
                call(add_issue, issues, document, rule, item.line.number, col)
                break

def check_L058(document=None, issues=None, rule=None, *_ignored):
    entries = first(call(bibliography_section_lines, document))
    for _iteration_10014 in first(call(ipairs, entries)):
        _, item = unpack([_iteration_10014], 2)
        col = first(method(item.line.text, b'find', b"[%w%)]'%d%d"))
        if truth(col):
            call(add_issue, issues, document, rule, item.line.number, col)

def check_L059(document=None, issues=None, rule=None, *_ignored):
    entries = first(call(bibliography_section_lines, document))
    for _iteration_10015 in first(call(ipairs, entries)):
        _, item = unpack([_iteration_10015], 2)
        col = first(method(item.line.text, b'find', b"[%a%d]%s+'s%f[%A]"))
        if truth(col):
            call(add_issue, issues, document, rule, item.line.number, col)

def check_L060(document=None, issues=None, rule=None, *_ignored):
    entries = first(call(bibliography_section_lines, document))
    for _iteration_10016 in first(call(ipairs, entries)):
        _, item = unpack([_iteration_10016], 2)
        col = first(method(item.line.text, b'find', '[“”‘’]'.encode('utf-8')))
        if truth(col):
            call(add_issue, issues, document, rule, item.line.number, col)

def check_L061(document=None, issues=None, rule=None, *_ignored):
    explanation_lines = first(call(bibliography_explanation_subbullets, document))
    targets = T([(first(call(string.byte, b',')), True), (first(call(string.byte, b':')), True), (first(call(string.byte, b';')), True)])
    for _iteration_10017 in first(call(ipairs, explanation_lines)):
        _, item = unpack([_iteration_10017], 2)
        __skip_continue = False
        line = item.line
        codepoints = first(call(core.codepoints, line.masked_text))
        for _iteration_10018 in first(call(ipairs, codepoints)):
            index, point = unpack([_iteration_10018], 2)
            if truth(get(targets, point.cp)) and truth(first(call(is_unmasked_char, line, point))):
                prev_item = first(call(core.previous_nonspace, codepoints, index))
                next_item = first(call(core.next_nonspace, codepoints, index))
                touches_cjk = _condition_10021 if truth((_condition_10021 := first(first(call(core.is_cjk, prev_item.cp)) if truth((_condition_10019 := prev_item)) else _condition_10019))) else first(first(call(core.is_cjk, next_item.cp)) if truth((_condition_10020 := next_item)) else _condition_10020)
                if truth(touches_cjk):
                    call(add_issue, issues, document, rule, line.number, point.pos)
                    __skip_continue = True
                    break
        if truth(__skip_continue):
            continue
        last_item = first(call(core.last_nonspace_codepoint, codepoints))
        if (truth(last_item) and last_item.char == b'.') and truth(first(call(is_unmasked_char, line, last_item))):
            call(add_issue, issues, document, rule, line.number, last_item.pos)
from lintlib.rules import run_checks

def check(document: dict, selected: set[str]) -> list[dict]:
    return run_checks(document, selected, CHECKS)
CHECKS = {'L015': check_L015, 'L016': check_L016, 'L042': check_L042, 'L055': check_L055, 'L056': check_L056, 'L057': check_L057, 'L058': check_L058, 'L059': check_L059, 'L060': check_L060, 'L061': check_L061}
