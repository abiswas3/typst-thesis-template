#let frontpage(
  title: [],
  subtitle: "",
  author: "",
  degree: "",
  faculty: "",
  department: "",
  major: "",
  date: none,
) = {
  set document(title: title, author: author)

// -------------------------------
// Front matter configuration
// -------------------------------

// Roman numeral page numbering
set page(
  numbering: none,
)

// Disable heading numbering in front matter
set heading(numbering: none)

// Helper for front-matter chapters
let frontchapter(title) = block(
  heading(level: 1)[title]
)


// -------------------------------
// Title page
// -------------------------------

// #pagebreak()
// Top keyline
align(center)[
  #image("/assets/keyline_black_with.pdf", width: 100%)
]

align(center)[
  #image("/assets/variation3.png", width: 4cm)


  #text(size: 18pt, weight: "bold")[
    Secure Verifiable Computation In The Modern World
  ]


  Ari


  A thesis submitted in support of the degree of
  *Doctor of Philosophy in Computer Science*


  Department of Computer Science
  University of Warwick


  March 2024
]
}
