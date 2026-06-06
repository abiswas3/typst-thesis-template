# Tinymist LSP: Fix cross-file refs and autocomplete

## Why

This project is a multi-file Typst document: `thesis.typ` is the main entry point that
`#include`s chapter files from `chapters/`.
When you open a chapter file directly, tinymist (the Typst LSP) tries to compile that file in isolation. It has no idea about the rest of the project, so it can't resolve:

- `@label` references to headings/figures defined in other chapter files
- `@citation` references to bibliography entries (the bibliography is loaded in `thesis.typ`)
- Glossary abbreviations like `@uit`, `@cpu`

This means you get red squiggly errors on every cross-file ref and `@` autocomplete is empty.

## What pinMain does

The `tinymist.pinMain` command tells the LSP: "compile everything starting from `thesis.typ`,
not from whatever file I happen to have open."
Once pinned, tinymist sees the full document
tree and can resolve all labels, citations, and abbreviations — giving you working
diagnostics and `@` autocomplete in every chapter file.

## Commands

Run this command in Neovim to pin the main file:

## Neovim >= 0.11

```lua
:lua local client = vim.lsp.get_clients({ name = "tinymist" })[1]; client:exec_cmd({ command = "tinymist.pinMain", arguments = { "/Users/francis/Projects/typst-thesis-template/thesis.typ" } })
```

## Neovim < 0.11

```lua
:lua vim.lsp.buf.execute_command({ command = 'tinymist.pinMain', arguments = { '/Users/francis/Projects/typst-thesis-template/thesis.typ' } })
```

## Notes

- Run from any file — doesn't need to be thesis.typ
- `<leader>tm` (bound in lspconfig.lua) does the same with the current buffer's path —
  so press it *while in thesis.typ*, not in a chapter file
- After renaming the main file (demo.typ → thesis.typ), re-pin: the old pin points at a
  file that no longer exists
- Does NOT persist across Neovim restarts — must re-run each session
- After running, `@` autocomplete should work across all chapter files

---

# Equate: Per-line equation numbering (sub-numbering)

## Why

By default Typst gives one number per equation block. For multi-line equations you
often want each line numbered individually, e.g. `(1.1a)`, `(1.1b)`.
The `equate` package (`@preview/equate:0.3.2`) adds this, plus the ability to label
and reference individual lines with `#<label>` inside `$ ... $`.

## What was changed

### `thesis.typ`
- Imported equate and added `#show: equate.with(breakable: true, sub-numbering: true)`
- Without the show rule, `#<label>` inside equations renders as literal text and
  equations only get a single block-level number.

### `lib.typ` — equation numbering function
- Changed `numbering: n => { ... }` to `numbering: (..nums) => { ... }`
- When `sub-numbering: true`, equate passes **two** numbers `(main-number, sub-number)`
  to the numbering function. A single-arg function causes an "unexpected argument" error.
- Uses `"(1.1a)"` format when two args are present (sub-numbered), `"(1.1)"` otherwise.

## Label syntax inside equations

```typst
$
  a &= b #<my-label> \
  c &= d
$ <whole-block>
```
- `#<my-label>` — labels that specific line (referenceable with `@my-label`)
- `<whole-block>` — labels the whole equation block (referenceable with `@whole-block`)

---

# Thesis restructure (2026-06-06): thesis-by-papers

## Why

Every chapter of the thesis is a published/working paper. Each paper needs its own
title page with publication info, its own macros, assets, and sections — without
papers stepping on each other (Typst labels are global, macros can clash, bib keys
can collide).

## Repo structure

```
thesis.typ                  # main entry point (renamed from demo.typ;
                            # typst.toml entrypoint updated to match)
lib.typ                     # template: page setup, outlines, paper-info helper
refs.bib                    # ONE global bibliography for the whole thesis
utils/                      # global helpers (global.typ, symbols.typ, caption.typ, ...)
modules/                    # front/back matter pages (frontpage, abstract, ...)
chapters/
  _paper-skeleton/          # copy this folder to start a new paper-chapter
  00-introduction/main.typ  # Chapter 1 (placeholder — write in February)
  01-dp-hhh/                # Chapter 2: DP Hierarchical Heavy Hitters paper
    main.typ                #   chapter title + paper-info box + section includes
    commands.typ            #   paper-local macros
    sections/               #   the paper text, one file per section
    assets/                 #   paper figures (proof_tree/game/PostSketch still
                            #   placeholders — drop real ones in)
  99-conclusion/main.typ    # Chapter 3 (stub)
  appendix.typ
docs/                       # template usage examples (basic-usage, typst-basics,
                            # utilities) — reference only, not included in thesis
```

## Anatomy of a paper-chapter (main.typ pattern)

```typst
#import "/lib.typ": paper-info

= Chapter Title <chp:paper-key>

#paper-info(                  // "This chapter is based on..." box
  title: "...", authors: (...), venue: "...", year: ..., doi: "...",
)

#pagebreak()                  // paper starts on the next page

#set heading(offset: 1)       // paper's `=` headings become thesis sections

#include "sections/introduction.typ"
...
```

## Conventions (IMPORTANT for every new paper)

1. **Label prefixes**: every label in a paper gets the paper's short key, e.g.
   `<hhh:sec:introduction>`, `@hhh:thm:main`. Labels are global across the thesis —
   two papers both defining `<sec:introduction>` is a compile error.
   (dp-hhh was migrated wholesale with sed; bib cite keys like `@cormode2003finding`
   have no `ns:` colon prefix so they were untouched.)
2. **Bibliography**: merge each paper's .bib into the root `refs.bib` and dedup
   shared keys — Typst errors on duplicate keys across multiple bib files.
3. **Macros**: paper-local commands live in `chapters/NN-key/commands.typ`,
   imported by section files as `#import "../commands.typ": *`. Never in lib.typ.
4. **New paper**: copy `chapters/_paper-skeleton/`, follow the checklist in its
   main.typ, add the `#include` to thesis.typ.

## Template fixes made along the way

- **`set ref(supplement: <function>)` removed from lib.typ** — the theorion fork in
  `@local/random-walks` reads `supplement` verbatim and crashes with
  "cannot join function with string" on any theorem ref (e.g. `@hhh:def:hhh`).
  Function supplements on headings don't work either (`level`/`offset` unresolved
  in the callback). Now plain show-set rules:
  `set heading(supplement: [Section])` +
  `show heading.where(level: 1): set heading(supplement: [Chapter])`
  (+ `[Appendix]` override in back-matter). Cross-refs into the appendix now
  correctly say "Appendix" (the old state-based version said "Chapter").
- **List of Figures**: entries auto-truncate to the caption's first sentence
  (`caption-first-sentence` in lib.typ). `dynamic-caption(long, short)` from
  utils/caption.typ still works for manual control. Two LoF entries are blank
  because their captions are empty in the paper source
  (private_hhh_non_streaming.typ ~116 and ~294) — write captions there.

---

# scripts/new-chapter.py — scaffold a new paper-chapter

Creates `chapters/NN-<key>/` from `chapters/_paper-skeleton/`, fills in the paper
metadata, and wires the `#include` into thesis.typ (before the conclusion).

## Usage

```sh
scripts/new-chapter.py <key> --title "Paper Title" [options]
```

- `<key>` — short paper slug, lowercase/hyphens (e.g. `dp-median`). Becomes the
  folder name `chapters/NN-dp-median/` AND (hyphens stripped) the label prefix
  `dpmedian:` you must use on every label in the paper.

## Options

| flag         | default          | meaning                                      |
|--------------|------------------|----------------------------------------------|
| `--title`    | (required)       | chapter/paper title                           |
| `--authors`  | `"Ari Biswas"`   | one or more author names, space-separated     |
| `--venue`    | `TODO: venue`    | publication venue for the paper-info box      |
| `--year`     | `2026`           | publication year                              |
| `--doi`      | (none)           | DOI; uncomments the doi line in paper-info    |
| `--number`   | next free NN     | force a chapter number (99 = conclusion, reserved) |
| `--sections` | `introduction`   | section files to create under `sections/`     |

## Example

```sh
scripts/new-chapter.py dp-median \
  --title "Differentially Private Medians" \
  --authors "Ari Biswas" "Graham Cormode" \
  --venue "NeurIPS" --year 2026 \
  --sections introduction prelims main_result experiments
```

creates:

```
chapters/02-dp-median/
  main.typ          # title + paper-info(NeurIPS 2026) + includes, all filled in
  commands.typ
  sections/{introduction,prelims,main_result,experiments}.typ
  assets/
```

and inserts `#include "./chapters/02-dp-median/main.typ"` into thesis.typ.

## After running (manual steps it tells you about)

1. Paste the paper text into `sections/*.typ`, prefixing ALL labels with the
   paper key, e.g. `<dpmedian:thm:main>` / `@dpmedian:thm:main`. Bulk-migrate
   an existing paper with sed, as done for dp-hhh:
   ```sh
   sed -i '' -E 's/<(alg|cor|def|eq|equate|fig|lemma|problem|sec|thm):/<dpmedian:\1:/g;
                 s/@(alg|cor|def|eq|equate|fig|lemma|problem|sec|thm):/@dpmedian:\1:/g' \
       chapters/02-dp-median/sections/*.typ
   ```
   (bib cite keys have no `ns:` colon, so they're untouched)
2. Merge the paper's `.bib` into root `refs.bib`, dedup keys shared with other papers.
3. Drop figures into `assets/`.
4. `typst compile thesis.typ` (or `typst watch thesis.typ`).
