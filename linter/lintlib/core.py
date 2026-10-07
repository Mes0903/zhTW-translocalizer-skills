"""Public document views and character locations.

The byte predicates keep their historical UTF-8 windows. Callers receive normal
Python strings, lists and dicts; reported columns count Unicode code points.
"""
from pathlib import Path
from . import document_views as views
from .byte_patterns import B, first, to_native


def byte_to_char_col(text: str, byte_col: int) -> int:
    return first(views.byte_to_char_col(B(text),byte_col))


def mask_inline_code(raw: bytes) -> bytes:
    return first(views.mask_inline_code(raw))


def load_glossary_context(path: Path, skill_root: Path) -> dict:
    return to_native(views.load_glossary_context(B(str(path)), B(str(skill_root))))


def build_document(path: Path, raw: bytes, skill_root: Path) -> dict:
    raw.decode('utf-8')
    document = to_native(views.build_document(B(str(path)),raw))
    for key in ('lines','paragraphs'):
        if not document[key]:
            document[key] = []
    document.setdefault('first_paragraph',None)
    document['repo_root'] = str(skill_root)
    document['glossary'] = load_glossary_context(path,skill_root)
    return document
