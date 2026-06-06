// Paper-chapter skeleton.
// To start a new paper-chapter:
//   1. Copy this folder to chapters/NN-<paper-key>/
//   2. Pick a short label prefix for the paper (e.g. "hhh") and use it on
//      EVERY label: <key:sec:intro>, <key:thm:main>, ... Labels are global
//      across the thesis, so unprefixed labels WILL collide between papers.
//   3. Merge the paper's .bib entries into the root refs.bib (dedup shared keys).
//   4. Add `#include "./chapters/NN-<paper-key>/main.typ"` to thesis.typ.

#import "/lib.typ": paper-info

= TODO Chapter Title <chp:paper-key>

#paper-info(
  title: "TODO: paper title",
  authors: ("Ari Biswas",),
  venue: "TODO: venue",
  year: 2026,
  // doi: "10.0000/00000",
)

#pagebreak()

// Demote the paper's headings by one level: `=` in the section files
// becomes a section of this chapter rather than a chapter of the thesis.
#set heading(offset: 1)

#include "sections/introduction.typ"
