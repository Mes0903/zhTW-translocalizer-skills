"""Original rule identities, selection policy, and module dispatch."""
import importlib
import json
from functools import lru_cache
from pathlib import Path

PROFILES = {
    'spec': {'L017', 'L027', 'L002', 'L130'},
    'glossary': {'L044', 'L045', 'L046', 'L022'},
    'meta': {'L017', 'L018', 'L130'},
    'final': set(),
    'default': set(),
}
SKILL_ROOT = Path(__file__).resolve().parents[2]

@lru_cache(maxsize=4)
def load_catalog(root: Path = SKILL_ROOT) -> dict[str, dict]:
    rows = json.loads((root / 'linter/data/rule-map.json').read_text(encoding='utf-8'))['rules']
    catalog = {row['id']: row for row in rows}
    if len(catalog) != len(rows):
        raise ValueError('duplicate lint id in rule-map.json')
    return catalog

def select_rule_ids(catalog: dict, selected: set[str] | None, excluded: set[str], profile: str = 'default') -> set[str]:
    if profile not in PROFILES:
        raise ValueError(f'unknown profile: {profile} (available: spec, glossary, meta, final, default)')
    implemented = {key for key, rule in catalog.items() if rule['implemented']}
    for lint_id in sorted((selected or set()) | excluded):
        if lint_id not in implemented:
            raise ValueError(f'unknown lint id: {lint_id}')
    base = selected if selected is not None else {key for key, rule in catalog.items() if rule['enabled_by_default']}
    return base - excluded - PROFILES[profile]

def run_rules(document: dict, selected: set[str]) -> list[dict]:
    catalog = load_catalog()
    owners = sorted({catalog[key]['module'] for key in selected})
    warnings = []
    for owner in owners:
        module = importlib.import_module(f'lintlib.rules.{owner}')
        warnings.extend(module.check(document, selected))
    return sorted(warnings, key=lambda warning: (warning['line'], warning['col'], warning['lint_id']))
