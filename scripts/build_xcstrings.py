"""Builds Biliteral/Localization/Localizable.xcstrings from scripts/translations.py.

Usage: python3 scripts/build_xcstrings.py [path/to/DerivedData]
With a DerivedData path, also checks that every string the compiler extracted is translated.
"""
import glob, json, os, sys
sys.path.insert(0, os.path.dirname(__file__))
from translations import LANGS, PLURALS, UNTRANSLATED, T

ROOT = os.path.join(os.path.dirname(__file__), "..")
OUT = os.path.join(ROOT, "Biliteral", "Localization")

def unit(value):
    return {"stringUnit": {"state": "translated", "value": value}}

def plural(one, other):
    return {"variations": {"plural": {"one": unit(one), "other": unit(other)}}}

strings = {}
for row in T:
    key, values = row[0], row[1:]
    assert len(values) == len(LANGS), key
    strings[key] = {"localizations": {lang: unit(v) for lang, v in zip(LANGS, values)}}
for key, forms in PLURALS.items():
    strings[key] = {"localizations": {lang: plural(*forms[lang]) for lang in ["en"] + LANGS}}
for key in UNTRANSLATED:
    strings[key] = {"shouldTranslate": False}

if len(sys.argv) > 1:
    extracted = set()
    for f in glob.glob(os.path.join(sys.argv[1], "Build/Intermediates.noindex/Biliteral.build/**/*.stringsdata"), recursive=True):
        data = json.load(open(f))
        if "Tests" in data["source"]:
            continue
        for entries in data["tables"].values():
            extracted.update(e["key"] for e in entries)
    missing = sorted(extracted - set(strings))
    unused = sorted(set(strings) - extracted)
    if missing:
        print("MISSING translations:", *missing, sep="\n  ")
    if unused:
        print("Unused keys:", *unused, sep="\n  ")
    if missing:
        sys.exit(1)

os.makedirs(OUT, exist_ok=True)
with open(os.path.join(OUT, "Localizable.xcstrings"), "w") as f:
    json.dump({"sourceLanguage": "en", "strings": dict(sorted(strings.items())), "version": "1.0"},
              f, ensure_ascii=False, indent=2)

print(f"Wrote {len(strings)} strings")
