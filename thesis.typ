#import "/lib.typ": *

//
// Other packages used:
//

#import "@preview/glossarium:0.5.9": gls, glspl, make-glossary, print-glossary
#import "@preview/codly:1.3.0": *

#let epigraph = [
  “We can know only that we know nothing. \
  And that is the highest degree of human wisdom.”\
  ― Leo Tolstoy, War and Peace \ \
  "But eyes are blind. You have to look with the heart.”\
  ― Antoine de Saint-Exupéry, The Little Prince
 ]

#let abstract = [#lorem(150)]
#let acknowledgements = [#lorem(150)]
#let appendix = [
  = Appendices
  #include "./chapters/appendix.typ"
]

// Put your abbreviations/acronyms here.
// 'key' is what you will reference in the typst code
// 'short' is the abbreviation (what will be shown in the pdf on all references except the first)
// 'long' is the full acronym expansion (what will be shown in the first reference of the document)
#let abbreviations = (
  (
    key: "gc",
    short: "GC",
    long: "Garbage Collection",
  ),
  (
    key: "uit",
    short: "UiT",
    long: "University of Tromsø – The Arctic University of Norway",
  ),
  (
    key: "cow",
    short: "COW",
    long: "Copy on Write",
  ),
  (
    key: "cpu",
    short: "CPU",
    long: "Central Processing Unit",
  ),
)

#show: thesis.with(
  author: "Ari Biswas",
  title: "<title>",
  degree: "<degree>",
  faculty: "<faculty>",
  department: "<department>",
  major: "<major>",
  supervisors: (
    (
      title: "Supervisor",
      name: "Graham Cormode",
      affiliation: [Professor, University of Warwick \
        and University of Oxford
      ],
    ),
  ),
  epigraph: epigraph,
  abstract: abstract,
  appendix: appendix,
  acknowledgements: acknowledgements,
  preface: none,
  figure-index: true,
  table-index: true,
  listing-index: true,
  abbreviations: abbreviations,
  date: datetime(year: 2025, month: 6, day: 1),
  bibliography: bibliography("./refs.bib", title: "Bibliography", style: "ieee"),
)

// Code blocks
#codly(
  languages: (
    rust: (
      name: "Rust",
      color: rgb("#CE412B"),
    ),
    // NOTE: Hacky, but 'fs' doesn't syntax highlight
    fsi: (
      name: "F#",
      color: rgb("#6a0dad"),
    ),
  ),
)

#import "@preview/equate:0.3.2": equate
// NOTE: equate enables per-line numbering in multi-line equations.
// Without this show rule, #<label> inside equations renders as raw text
// and multi-line blocks get a single number instead of (1.1a), (1.1b), etc.
#show: equate.with(breakable: true, sub-numbering: true)
// If you wish to use lining figures rather than old-style figures, uncomment this line.
// #set text(number-type: "lining")

// Chapters, in reading order. Each paper-chapter is a self-contained folder;
// copy chapters/_paper-skeleton/ to start a new one.
// (Template usage examples live in docs/.)

#include "./chapters/00-introduction/main.typ"
#pagebreak()

#include "./chapters/01-dp-hhh/main.typ"
#pagebreak()

#include "./chapters/99-conclusion/main.typ"
