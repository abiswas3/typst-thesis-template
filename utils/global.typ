//
// About warwick-thesis:
//

// NOTE:
//     following is an (indirect) import of the 'lib.typ' file
//     The file lib.typ (and others) will be downloaded and cached
//     by your system. The location of the @preview cache directory
//     is explained in
//     https://github.com/typst/packages?tab=readme-ov-file#downloads
//     e.g.  %APPDATA% on Windows on Windows
//           ~/.local/share or $XDG_DATA_HOME on Linux
//           ~/Library/Application Support on macOS
//
// NOTE:
//    If you like to modify "lib.typ", copy the file from the cache directory
//    or get it from the 'official' Typst Universe package git repo
//       (i.e. from proper 'version number subdir' of
//         https://github.com/typst/packages/tree/main/packages/preview/modern-uit-thesis)
//    Copy the lib.typ to a (sub)folder of this project and
//    set the path accordingly.
#import "../lib.typ": *

//
// Other packages used:
//

#import "@preview/glossarium:0.5.9": gls, glspl, make-glossary, print-glossary
#import "@preview/codly:1.3.0": *

// When a chapter file is opened standalone (e.g. by the LSP), there is no
// bibliography in scope so @citations can't resolve.  This helper loads the
// bibliography only when one hasn't already been provided by the main document.
#let load-bib(main: false) = {
  counter("bibs").step()
  context if main {
    [#bibliography("../refs.bib") <main-bib>]
  } else if query(<main-bib>) == () and counter("bibs").get().first() == 1 {
    bibliography("../refs.bib")
  }
}

#load-bib()
