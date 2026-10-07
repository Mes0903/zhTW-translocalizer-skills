"""Lossless raw JSON and grouped diagnostics for people reading the report."""
from collections import OrderedDict
import json

PROBLEMS = {
    'L001': 'paragraph-wrap', 'L002': 'paragraph-wrap',
    'L011': 'ba-result', 'L107': 'ba-result',
    'L105': 'event-nominalization', 'L108': 'event-nominalization',
}
TITLES = {
    'paragraph-wrap': '段落換行',
    'ba-result': '把字句的結果或終點',
    'event-nominalization': '事件名物化與壓縮',
}

def group_findings(warnings: list[dict], catalog: dict) -> list[dict]:
    groups = OrderedDict()
    for warning in warnings:
        problem = PROBLEMS.get(warning['lint_id'], warning['lint_id'])
        anchor = (warning['path'], warning['line'], warning['col'], problem)
        if anchor not in groups:
            groups[anchor] = {key: warning[key] for key in ('path','line','col')}
            groups[anchor].update(problem=problem, reasons=[])
        rule = catalog[warning['lint_id']]
        groups[anchor]['reasons'].append({'warning':warning, 'status':rule['status'], 'owner_spec':rule['owner_spec']})
    return list(groups.values())

def render_json(warnings: list[dict], paths: list[str]) -> str:
    return json.dumps({'warnings':warnings,'summary':{'warning_count':len(warnings),'files':paths}},ensure_ascii=False, separators=(',',':')) + '\n'

def render_text(findings: list[dict]) -> str:
    lines = []
    for finding in findings:
        anchor = f"{finding['path']}:{finding['line']}:{finding['col']}"
        lines.append(f"{anchor} {TITLES.get(finding['problem'],finding['problem'])}")
        for reason in finding['reasons']:
            warning = reason['warning']
            lines.append(f"  [{warning['lint_id']}] {warning['message']} ({reason['status']}; {reason['owner_spec']})")
    hits = sum(len(finding['reasons']) for finding in findings)
    return '\n'.join(lines) + f'\n\n{len(findings)} problem(s), {hits} warning(s)\n'

def _escape(value) -> str:
    return str(value).replace('\\','\\\\').replace('|',r'\|').replace('\n','<br>')

def render_markdown(findings: list[dict], paths: list[str]) -> str:
    hits = sum(len(finding['reasons']) for finding in findings)
    lines = ['# Lint Report','','| Metric | Count |','| --- | ---: |',f'| Files scanned | {len(paths)} |',f'| Problems | {len(findings)} |',f'| Rule hits | {hits} |','','## Detailed Warnings','']
    if not findings:
        return '\n'.join(lines+['No warnings.',''])
    for finding in findings:
        lines.extend([f"### {_escape(finding['path'])} L{finding['line']}:C{finding['col']} — {_escape(TITLES.get(finding['problem'],finding['problem']))}",'','| Rule | Status | Source | Reason |','| --- | --- | --- | --- |'])
        for reason in finding['reasons']:
            warning = reason['warning']
            lines.append(f"| `{warning['lint_id']}` | {_escape(reason['status'])} | {_escape(reason['owner_spec'])} | {_escape(warning['message'])} |")
        lines.append('')
    return '\n'.join(lines)
