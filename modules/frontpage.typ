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
    Secure And Verifiable Computation In The Modern World
  ]

#text(size: 12pt)[by]\
\
#text(size: 16pt, weight: "bold")[Ari Biswas]

#set par(leading: 1.3em)
#text(size: 13pt)[A thesis submitted to the University of Warwick \ in partial fulfilment of the requirements \ for admission to the degree of \
  *Doctor of Philosophy*]


#text(size: 16pt, weight: "bold")[ Department of Computer Science
  ]


  #text(size: 14pt)[#datetime.today().display("[month repr:long] [year repr:full]")]
]
}
