#!/usr/bin/env python3
"""This fixes Squirrel's fuckup.

Usage:
    python3 scripts/lowercase_folders.py
    python3 scripts/lowercase_folders.py --apply # bombs awayyyy
    python3 scripts/lowercase_folders.py --apply --report renames.md # debugging
"""

from __future__ import annotations

import argparse
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

EXCLUDE_DIR_NAMES = {".git", "_refs", ".direnv", "node_modules", ".vscode"}

# Pain in the ass to fix
CASE_SENSITIVE_PARENTS = {"i18n"}

TEXT_EXTS = {".qml", ".js", ".nix", ".md", ".json", ".sh", ".py", ".ini"}


def is_excluded(path: Path) -> bool:
    return any(part in EXCLUDE_DIR_NAMES for part in path.parts)


def collect_dirs_to_rename() -> list[Path]:
    dirs = []
    for p in ROOT.rglob("*"):
        if not p.is_dir() or is_excluded(p):
            continue
        if p.parent.name in CASE_SENSITIVE_PARENTS:
            continue
        if p.name != p.name.lower():
            dirs.append(p)
    dirs.sort(key=lambda p: len(p.parts), reverse=True)
    return dirs


def plan_renames(dirs: list[Path]) -> list[tuple[Path, Path]]:
    return [(d, d.parent / d.name.lower()) for d in dirs]


def do_renames(renames: list[tuple[Path, Path]]) -> None:
    for old, new in renames:
        if new.exists():
            raise RuntimeError(f"refusing to rename, target exists: {old} -> {new}")
        old.rename(new)


def build_name_map(renames: list[tuple[Path, Path]]) -> dict[str, str]:
    return {old.name: new.name for old, new in renames}


def _name_pattern(name_map: dict[str, str]) -> re.Pattern:
    # \b keeps this from matching inside a larger identifier so SomeBarThing, Bar_test etc
    names = sorted(name_map, key=len, reverse=True)
    return re.compile(r"\b(%s)\b" % "|".join(re.escape(n) for n in names))


_QUOTED_SPAN_RE = re.compile(r'"[^"\n]*"|\'[^\'\n]*\'|`[^`\n]*`')

LINE_COMMENT_MARKERS = {".qml": "//", ".js": "//", ".py": "#", ".sh": "#", ".nix": "#"}


def _quoted_spans(line: str) -> list[tuple[int, int]]:
    return [m.span() for m in _QUOTED_SPAN_RE.finditer(line)]


def _comment_span(
    line: str, marker: str, quoted: list[tuple[int, int]]
) -> tuple[int, int] | None:
    idx = 0
    while True:
        idx = line.find(marker, idx)
        if idx == -1:
            return None
        if not any(s <= idx < e for s, e in quoted):
            return (idx, len(line))
        idx += len(marker)


def _fenced_line_numbers(text: str) -> set[int]:
    fenced: set[int] = set()
    in_fence = False
    for i, line in enumerate(text.splitlines()):
        if line.strip().startswith("```"):
            in_fence = not in_fence
            fenced.add(i)
            continue
        if in_fence:
            fenced.add(i)
    return fenced


def _is_path_segment(
    line: str,
    start: int,
    end: int,
    spans: list[tuple[int, int]],
    require_slash: bool = True,
) -> bool:
    if not any(s <= start and end <= e for s, e in spans):
        return False

    before = line[start - 1] if start > 0 else ""
    before2 = line[start - 2] if start > 1 else ""
    after = line[end] if end < len(line) else ""
    after2 = line[end + 1] if end + 1 < len(line) else ""

    if after == ".":
        return False
    if before == "/" and before2 != "/":
        return True
    if after == "/" and after2 != "/":
        return True
    return require_slash is False


def rewrite_references(name_map: dict[str, str]) -> dict[Path, int]:
    if not name_map:
        return {}

    pattern = _name_pattern(name_map)

    changed: dict[Path, int] = {}
    for path in ROOT.rglob("*"):
        if not path.is_file() or is_excluded(path):
            continue
        if path.suffix not in TEXT_EXTS:
            continue
        try:
            text = path.read_text(encoding="utf-8")
        except (UnicodeDecodeError, OSError):
            continue

        comment_marker = LINE_COMMENT_MARKERS.get(path.suffix)
        fenced = _fenced_line_numbers(text) if path.suffix == ".md" else set()

        count = 0
        out_lines = []
        for lineno, line in enumerate(text.splitlines(keepends=True)):
            in_fence = lineno in fenced
            if in_fence:
                spans = [(0, len(line))]
            else:
                spans = _quoted_spans(line)
                if comment_marker:
                    comment = _comment_span(line, comment_marker, spans)
                    if comment:
                        spans = spans + [comment]

            def repl(m: re.Match) -> str:
                nonlocal count
                if not _is_path_segment(
                    line, m.start(), m.end(), spans, require_slash=not in_fence
                ):
                    return m.group(0)
                count += 1
                return name_map[m.group(1)]

            out_lines.append(pattern.sub(repl, line))

        if count:
            changed[path] = count
            path.write_text("".join(out_lines), encoding="utf-8")

    return changed


def sweep_leftovers(name_map: dict[str, str]) -> dict[str, list[str]]:
    leftovers: dict[str, list[str]] = {}
    pattern = _name_pattern(name_map)

    for path in ROOT.rglob("*"):
        if not path.is_file() or is_excluded(path):
            continue
        if path.suffix not in TEXT_EXTS:
            continue
        try:
            text = path.read_text(encoding="utf-8")
        except (UnicodeDecodeError, OSError):
            continue
        for lineno, line in enumerate(text.splitlines(), start=1):
            for m in pattern.finditer(line):
                key = str(path.relative_to(ROOT))
                leftovers.setdefault(key, []).append(
                    f"{lineno}: {line.strip()} ({m.group(1)})"
                )
    return leftovers


def main() -> None:
    ap = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    ap.add_argument("--apply", action="store_true", help="perform the rename + rewrite")
    ap.add_argument("--report", type=Path, default=None, help="mainly debug")
    args = ap.parse_args()

    dirs = collect_dirs_to_rename()
    renames = plan_renames(dirs)

    if not renames:
        return

    print("Point of no return")
    for old, new in renames:
        print(f"  {old.relative_to(ROOT)} -> {new.relative_to(ROOT)}")

    name_map = build_name_map(renames)

    if not args.apply:
        leftovers = sweep_leftovers(name_map)
        if leftovers:
            print(
                f"\n{sum(len(v) for v in leftovers.values())} mentions of these names exist across {len(leftovers)} file(s)!!!"
            )
        return

    do_renames(renames)
    changed = rewrite_references(name_map)

    print(f"\nRewrote path references in {len(changed)} file(s):")
    for path, count in sorted(changed.items()):
        print(
            f"  {path.relative_to(ROOT)}  ({count} replacement{'s' if count != 1 else ''})"
        )

    leftovers = sweep_leftovers(name_map)
    if leftovers:
        print(f"\n{sum(len(v) for v in leftovers.values())} mention(s) not auto-fixed:")
        for path, lines in sorted(leftovers.items()):
            print(f"  {path}:")
            for line in lines:
                print(f"    {line}")

    if args.report:
        lines = ["# Folder lowercasing\n"]
        lines.append("## Renamed folders\n")
        for old, new in renames:
            lines.append(f"- `{old.relative_to(ROOT)}` -> `{new.relative_to(ROOT)}`")
        lines.append("\n## Auto-fixed text references\n")
        for path, count in sorted(changed.items()):
            lines.append(
                f"- `{path.relative_to(ROOT)}` ({count} replacement{'s' if count != 1 else ''})"
            )
        lines.append("\n## Ya don fucked up, fix these: \n")
        if leftovers:
            for path, entries in sorted(leftovers.items()):
                lines.append(f"### `{path}`")
                for entry in entries:
                    lines.append(f"- {entry}")
        else:
            lines.append("None found")
        args.report.write_text("\n".join(lines) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
