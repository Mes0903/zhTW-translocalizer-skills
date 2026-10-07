#!/usr/bin/env python3
"""CLI for the Taiwan Traditional Chinese linter."""
import argparse
from pathlib import Path
import sys
from lintlib.registry import load_catalog, select_rule_ids, run_rules, PROFILES
from lintlib.report import group_findings, render_json, render_text, render_markdown

SKILL_ROOT = Path(__file__).resolve().parent.parent

class Parser(argparse.ArgumentParser):
    def error(self, message):
        raise ValueError(message)

def _ids(value: str) -> set[str]:
    if not value:
        raise ValueError('rule selector requires a comma-separated value')
    return {item.strip() for item in value.split(',') if item.strip()}

def main(argv: list[str] | None = None) -> int:
    parser = Parser(description=__doc__)
    parser.add_argument('--format',default='text',choices=['text','json','markdown'])
    parser.add_argument('--rules',type=_ids)
    parser.add_argument('--exclude',type=_ids,default=set())
    parser.add_argument('--profile',default='default',metavar='{spec,glossary,meta,final,default}')
    parser.add_argument('--list-rules',action='store_true')
    parser.add_argument('--fail-on-warning',action='store_true')
    parser.add_argument('paths',nargs='*')
    try:
        options = parser.parse_args(argv)
        catalog = load_catalog(SKILL_ROOT)
        if options.list_rules:
            for rule in sorted(catalog.values(), key=lambda rule: rule['implementation']['start_line'] if rule['implemented'] else 10000):
                if rule['implemented']:
                    mode = 'enabled' if rule['enabled_by_default'] else 'disabled-by-default'
                    print(f"{rule['id']}\t{rule['status']}\t{mode}\t{rule['summary']}")
            return 0
        if not options.paths:
            raise ValueError('at least one input file is required')
        selected = select_rule_ids(catalog,options.rules,options.exclude,options.profile)
        from lintlib.core import build_document
        warnings = []
        for path in options.paths:
            raw = Path(path).read_bytes()
            try:
                raw.decode('utf-8')
            except UnicodeDecodeError as error:
                raise ValueError(f'{path}: invalid UTF-8 at byte {error.start+1}') from error
            document = build_document(Path(path),raw,SKILL_ROOT)
            document['path'] = path
            warnings.extend(run_rules(document,selected))
        if options.format == 'json':
            output = render_json(warnings,options.paths)
        else:
            findings = group_findings(warnings,catalog)
            output = render_text(findings) if options.format == 'text' else render_markdown(findings,options.paths)
        sys.stdout.write(output)
        return 1 if options.fail_on_warning and warnings else 0
    except (ValueError,OSError) as error:
        print(f'error: {error}',file=sys.stderr)
        return 1

if __name__ == '__main__':
    sys.exit(main())
