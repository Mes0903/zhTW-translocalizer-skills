"""Domain checks share document analysis and the original ID catalog."""
from lintlib.byte_patterns import T,from_native,to_native
from lintlib.registry import load_catalog
from lintlib.core import byte_to_char_col


def run_checks(document: dict, selected: set[str], checks: dict) -> list[dict]:
    byte_document = from_native(document)
    issues = T()
    catalog = load_catalog()
    for lint_id, check in checks.items():
        if lint_id in selected:
            row = catalog[lint_id]
            rule = from_native({'id':lint_id, 'warning_message':row['warning_message']})
            check(byte_document,issues,rule)
    return to_native(issues) if issues else []


def make_warning(document: dict, lint_id: str, line: int, byte_col: int) -> dict:
    return {'path':document['path'], 'line':line,
            'col':byte_to_char_col(document['lines'][line-1]['text'],byte_col),
            'lint_id':lint_id, 'message':load_catalog()[lint_id]['warning_message'],
            'severity':'warning'}
