# zhTW Translocalizer Skill

Standalone AgentSkill for Taiwan Traditional Chinese translation, rewriting, review, and linting workflows.

Install this directory as a skill root, keeping `SKILL.md`, `references/`, and `linter/` together. The linter requires Python 3.10 or later and uses the standard library.

```bash
python3 linter/lint.py --list-rules
python3 linter/lint.py --format markdown --profile final article.md
```

Start with [SKILL.md](SKILL.md). CLI usage and topic navigation are in [linter/README.md](linter/README.md). Runtime rule metadata, dictionaries, and rule guidance are in `linter/data/` and `linter/catalog/`.

Writing guidance and paragraph examples are included in [references/output_style.md](references/output_style.md). Read them through the workflow alongside grammar and task sources. User-specified references and accepted neighboring passages support continuation.
