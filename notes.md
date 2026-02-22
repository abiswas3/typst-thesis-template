# Tinymist LSP: Fix cross-file refs and autocomplete

## Why

This project is a multi-file Typst document: `demo.typ` is the main entry point that
`#include`s chapter files from `chapters/`.
When you open a chapter file directly, tinymist (the Typst LSP) tries to compile that file in isolation. It has no idea about the rest of the project, so it can't resolve:

- `@label` references to headings/figures defined in other chapter files
- `@citation` references to bibliography entries (the bibliography is loaded in `demo.typ`)
- Glossary abbreviations like `@uit`, `@cpu`

This means you get red squiggly errors on every cross-file ref and `@` autocomplete is empty.

## What pinMain does

The `tinymist.pinMain` command tells the LSP: "compile everything starting from `demo.typ`,
not from whatever file I happen to have open."
Once pinned, tinymist sees the full document
tree and can resolve all labels, citations, and abbreviations — giving you working
diagnostics and `@` autocomplete in every chapter file.

## Commands

Run this command in Neovim to pin the main file:

## Neovim >= 0.11

```lua
:lua local client = vim.lsp.get_clients({ name = "tinymist" })[1]; client:exec_cmd({ command = "tinymist.pinMain", arguments = { "/Users/francis/Projects/typst-thesis-template/demo.typ" } })
```

## Neovim < 0.11

```lua
:lua vim.lsp.buf.execute_command({ command = 'tinymist.pinMain', arguments = { '/Users/francis/Projects/typst-thesis-template/demo.typ' } })
```

## Notes

- Run from any file — doesn't need to be demo.typ
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

### `demo.typ`
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
