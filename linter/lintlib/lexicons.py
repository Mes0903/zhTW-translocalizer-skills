"""The single runtime owner of preserved domain dictionaries."""
from functools import lru_cache
import json
from pathlib import Path
from .byte_patterns import from_native

@lru_cache(maxsize=1)
def _entries():
    path = Path(__file__).resolve().parents[2] / 'linter/data/lexicons.json'
    return json.loads(path.read_text(encoding='utf-8'))['lexicons']

@lru_cache(maxsize=None)
def load_lexicon(name: str):
    return from_native(_entries()[name]['values'])
