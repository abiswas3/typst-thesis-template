#import "/lib.typ": paper-info

= Differentially Private Hierarchical Heavy Hitters <chp:dp-hhh>

#paper-info(
  title: "Differentially Private Hierarchical Heavy Hitters",
  authors: ("Ari Biswas", "Graham Cormode"),
  venue: "TODO: venue",
  year: 2025,
  // doi: "10.0000/00000",
)

#pagebreak()

// Demote the paper's headings by one level: `=` in the section files
// becomes a section of this chapter rather than a chapter of the thesis.
#set heading(offset: 1)

#include "sections/introduction.typ"
#include "sections/prelims.typ"

#include "sections/private_hhh_non_streaming.typ"
#include "sections/private_hhh_stream.typ"

// Supplementary discussion sections (level-2 headings from the paper's appendix)
= Discussion <hhh:sec:discussion>
#include "sections/composition.typ"
#include "sections/larger_pop_larger_privacy.typ"
#include "sections/noise_reusage.typ"
