#!/usr/bin/env python3
"""Scaffold a new paper-chapter from chapters/_paper-skeleton/.

Creates chapters/NN-<key>/ with main.typ, commands.typ, sections/ and assets/,
substitutes the paper metadata, and inserts the #include into thesis.typ
(before the conclusion chapter).

Usage:
  scripts/new-chapter.py <key> --title "Paper Title" [options]

Examples:
  scripts/new-chapter.py dp-median --title "Differentially Private Medians" \
      --authors "Ari Biswas" "Graham Cormode" --venue "NeurIPS" --year 2026 \
      --sections introduction prelims main_result experiments

Conventions enforced:
  - <key> doubles as the label prefix: every label in the paper must be
    <key:sec:...>, <key:thm:...> etc. (labels are global across the thesis)
  - merge the paper's .bib into the root refs.bib yourself (dedup shared keys)
"""

import argparse
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CHAPTERS = ROOT / "chapters"
SKELETON = CHAPTERS / "_paper-skeleton"
THESIS = ROOT / "thesis.typ"
CONCLUSION_INCLUDE = '#include "./chapters/99-conclusion/main.typ"'


def typst_str(s: str) -> str:
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'


def next_number() -> int:
    nums = [
        int(m.group(1))
        for d in CHAPTERS.iterdir()
        if d.is_dir() and (m := re.match(r"^(\d\d)-", d.name))
        if int(m.group(1)) != 99  # 99 is reserved for the conclusion
    ]
    return max(nums, default=-1) + 1


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    p.add_argument("key", help="short paper key, e.g. 'dp-median' — used as folder name and label prefix")
    p.add_argument("--title", required=True, help="paper/chapter title")
    p.add_argument("--authors", nargs="+", default=["Ari Biswas"], help="author names")
    p.add_argument("--venue", default="TODO: venue", help="publication venue")
    p.add_argument("--year", type=int, default=2026, help="publication year")
    p.add_argument("--doi", default=None, help="DOI (optional)")
    p.add_argument("--number", type=int, default=None, help="chapter number NN (default: next free)")
    p.add_argument(
        "--sections",
        nargs="+",
        default=["introduction"],
        help="section file names to create (default: introduction)",
    )
    args = p.parse_args()

    if not re.fullmatch(r"[a-z][a-z0-9-]*", args.key):
        sys.exit(f"error: key '{args.key}' must be lowercase alphanumeric/hyphens")
    if not SKELETON.is_dir():
        sys.exit(f"error: skeleton not found at {SKELETON}")

    # the label prefix uses the key without hyphens, e.g. dp-median -> dpmedian:sec:...
    prefix = args.key.replace("-", "")
    for d in CHAPTERS.iterdir():
        if d.is_dir() and d.name.endswith(f"-{args.key}"):
            sys.exit(f"error: a chapter for key '{args.key}' already exists: {d.name}")

    num = args.number if args.number is not None else next_number()
    chapter = CHAPTERS / f"{num:02d}-{args.key}"
    if chapter.exists():
        sys.exit(f"error: {chapter} already exists")

    # --- main.typ from the skeleton, with metadata substituted ---
    main = (SKELETON / "main.typ").read_text()
    main = main.replace("= TODO Chapter Title <chp:paper-key>", f"= {args.title} <chp:{args.key}>")
    main = main.replace('title: "TODO: paper title",', f"title: {typst_str(args.title)},")
    authors = ", ".join(typst_str(a) for a in args.authors)
    main = main.replace('authors: ("Ari Biswas",),', f"authors: ({authors},),")
    main = main.replace('venue: "TODO: venue",', f"venue: {typst_str(args.venue)},")
    main = main.replace("year: 2026,", f"year: {args.year},")
    if args.doi:
        main = main.replace('// doi: "10.0000/00000",', f"doi: {typst_str(args.doi)},")
    includes = "\n".join(f'#include "sections/{s}.typ"' for s in args.sections)
    main = main.replace('#include "sections/introduction.typ"', includes)

    # --- section files from the skeleton section template ---
    section_tpl = (SKELETON / "sections" / "introduction.typ").read_text()
    chapter.mkdir(parents=True)
    (chapter / "sections").mkdir()
    (chapter / "assets").mkdir()
    (chapter / "main.typ").write_text(main)
    (chapter / "commands.typ").write_text((SKELETON / "commands.typ").read_text())
    for s in args.sections:
        body = section_tpl.replace(
            "= Introduction <paper-key:sec:introduction>",
            f"= {s.replace('_', ' ').title()} <{prefix}:sec:{s}>",
        )
        (chapter / "sections" / f"{s}.typ").write_text(body)

    # --- insert the include into thesis.typ, before the conclusion ---
    thesis = THESIS.read_text()
    include = f'#include "./chapters/{chapter.name}/main.typ"\n#pagebreak()\n\n'
    if CONCLUSION_INCLUDE in thesis:
        thesis = thesis.replace(CONCLUSION_INCLUDE, include + CONCLUSION_INCLUDE, 1)
        THESIS.write_text(thesis)
        wired = True
    else:
        wired = False

    print(f"created {chapter.relative_to(ROOT)}/")
    for f in sorted(chapter.rglob("*.typ")):
        print(f"  {f.relative_to(ROOT)}")
    if wired:
        print(f"wired into thesis.typ (before the conclusion)")
    else:
        print(f"WARNING: could not find the conclusion include in thesis.typ — add this yourself:")
        print(f'  #include "./chapters/{chapter.name}/main.typ"')
    print("\nnext steps:")
    print(f"  - prefix ALL labels in the paper with '{prefix}:' (e.g. <{prefix}:thm:main>)")
    print(f"  - merge the paper's .bib into refs.bib (dedup shared keys)")
    print(f"  - drop figures into {chapter.relative_to(ROOT)}/assets/")


if __name__ == "__main__":
    main()
