#!/usr/bin/env python3
"""Cross-checks every language in i18n/manifest.json against i18n/en/*.json,
domain by domain. English is the source of truth: every key it defines must
exist in every other language (missing keys silently fall back to English at
runtime, which is fine for a WIP translation, but this is how you find them).
Also flags stale keys a language has that English no longer does, and domains
listed in the manifest with no English file (a real bug, since English is the
mandatory fallback).

Run from anywhere: `python3 scripts/i18n-check.py`. Exit code is nonzero if
any English key is missing from a non-English language, so this can be wired
into CI later without extra plumbing.
"""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
I18N_DIR = ROOT / "i18n"


def load(path: Path) -> dict:
    if not path.exists():
        return None
    with path.open(encoding="utf-8") as f:
        return json.load(f)


def main() -> int:
    manifest = load(I18N_DIR / "manifest.json")
    if manifest is None:
        print(f"error: {I18N_DIR / 'manifest.json'} not found")
        return 1

    languages = [l["code"] for l in manifest["languages"]]
    domains = manifest["domains"]
    if "en" not in languages:
        print("error: manifest.json must list 'en' as a language (it's the mandatory fallback)")
        return 1

    problems = 0
    warnings = 0

    for domain in domains:
        en_path = I18N_DIR / "en" / f"{domain}.json"
        en_data = load(en_path)
        if en_data is None:
            print(f"ERROR  [{domain}] missing {en_path.relative_to(ROOT)} (English is mandatory)")
            problems += 1
            continue
        en_keys = set(en_data.keys())

        for lang in languages:
            if lang == "en":
                continue
            lang_path = I18N_DIR / lang / f"{domain}.json"
            lang_data = load(lang_path)
            if lang_data is None:
                print(f"WARN   [{domain}] {lang}: no file at {lang_path.relative_to(ROOT)} (falls back to English entirely)")
                warnings += 1
                continue
            lang_keys = set(lang_data.keys())

            missing = en_keys - lang_keys
            extra = lang_keys - en_keys
            if missing:
                print(f"ERROR  [{domain}] {lang}: missing {len(missing)} key(s): {', '.join(sorted(missing))}")
                problems += 1
            if extra:
                print(f"WARN   [{domain}] {lang}: {len(extra)} stale key(s) not in English: {', '.join(sorted(extra))}")
                warnings += 1

    print(f"\n{len(domains)} domain(s), {len(languages)} language(s) checked. "
          f"{problems} error(s), {warnings} warning(s).")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
