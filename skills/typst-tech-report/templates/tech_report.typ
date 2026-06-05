// tech_report.typ — generic arxiv-style technical report template.
//
// Use:
//   #import "tech_report.typ": tech-report
//   #show: tech-report.with(
//     title: "My Project — Technical Report",
//     subtitle: "Architecture, stack, current state",
//     authors: (
//       (name: "Jane Doe", affiliation: "Acme Labs", email: "jane@acme.io"),
//     ),
//     date: "March 2026",
//     abstract: [Short summary of what the project does and what this report covers.],
//   )
//
//   = Introduction
//   ...
//
// Design goals: clean serif look (New Computer Modern), no branding,
// works on any machine with `typst` CLI (NCM is embedded in the CLI binary).

#let tech-report(
  // Required
  title: "",

  // Optional metadata
  subtitle: none,
  authors: (),          // list of (name, affiliation, email) dicts; affiliation/email optional
  date: none,           // string or datetime; rendered as-is if string

  // Front matter
  logo: none,           // path to a logo image (e.g. "logo.png"); rendered above the title
  logo-height: 2.8cm,   // height of the logo on the title page
  abstract: none,       // content block; if set, rendered on the title page
  show-outline: true,   // table of contents after the title page
  outline-depth: 3,
  outline-title: [Contents],

  // Page setup
  paper: "a4",
  margin: (x: 2cm, y: 2cm),
  lang: "en",           // "en", "ru", ...

  // Typography
  body-font: "New Computer Modern",
  body-size: 11pt,
  mono-font: "DejaVu Sans Mono",
  math-font: "New Computer Modern Math",

  // Numbering
  heading-numbering: "1.1",
  page-numbering: "1",

  // Document body
  doc,
) = {
  // ---- Document metadata ----------------------------------------------------
  set document(
    title: title,
    author: authors.map(a => a.name),
  )

  // ---- Page setup -----------------------------------------------------------
  set page(
    paper: paper,
    margin: margin,
    numbering: page-numbering,
    number-align: center,
    // Header carries the document title on every page after the title page.
    // First page (title) stays clean.
    header: context {
      if counter(page).get().first() > 1 [
        #set text(size: 9pt, fill: luma(120))
        #h(1fr)
        #title
      ]
    },
  )

  // ---- Text & paragraph -----------------------------------------------------
  set text(font: body-font, size: body-size, lang: lang)
  set par(justify: true, leading: 0.65em)
  show math.equation: set text(font: math-font)
  show raw: set text(font: mono-font)

  // ---- Headings -------------------------------------------------------------
  set heading(numbering: heading-numbering)

  show heading.where(level: 1): it => {
    v(0.8em)
    set text(size: 14pt, weight: "bold")
    it
    v(0.4em)
  }
  show heading.where(level: 2): it => {
    v(0.6em)
    set text(size: 12pt, weight: "bold")
    it
    v(0.3em)
  }
  show heading.where(level: 3): it => {
    v(0.4em)
    set text(size: 11pt, weight: "bold", style: "italic")
    it
    v(0.2em)
  }

  // ---- Tables ---------------------------------------------------------------
  set table(stroke: 0.5pt + luma(180), inset: 6pt)
  show table.cell.where(y: 0): set text(weight: "bold", size: 10pt)
  show table.cell.where(y: 0): set table.cell(fill: luma(230))

  // ---- Code -----------------------------------------------------------------
  // Inline code: small light-gray pill.
  show raw.where(block: false): box.with(
    fill: luma(240),
    inset: (x: 3pt, y: 0pt),
    outset: (y: 3pt),
    radius: 2pt,
  )
  // Block code: light-gray panel with padding.
  show raw.where(block: true): it => {
    block(
      fill: luma(245),
      stroke: 0.5pt + luma(200),
      radius: 3pt,
      inset: 10pt,
      width: 100%,
      it,
    )
  }

  // ---- Links ----------------------------------------------------------------
  show link: it => underline(text(fill: blue.darken(20%))[#it])

  // ===========================================================================
  // Title page
  // ===========================================================================

  if logo != none {
    v(2cm)
    align(center)[
      #image(logo, height: logo-height)
    ]
    v(0.8cm)
  } else {
    v(3cm)
  }
  align(center)[
    #text(size: 22pt, weight: "bold")[#title]
    #if subtitle != none {
      v(0.6em)
      text(size: 13pt, fill: luma(80))[#subtitle]
    }
  ]

  v(1.5cm)

  // Authors block — multi-column grid if more than one author
  if authors.len() > 0 {
    let ncols = calc.min(authors.len(), 3)
    align(center)[
      #grid(
        columns: (1fr,) * ncols,
        row-gutter: 18pt,
        column-gutter: 24pt,
        ..authors.map(a => align(center)[
          #text(weight: "bold")[#a.name] \
          #if "affiliation" in a and a.affiliation != none [#a.affiliation \ ]
          #if "email" in a and a.email != none [
            #link("mailto:" + a.email)[#text(size: 10pt)[#a.email]]
          ]
        ]),
      )
    ]
    v(0.8cm)
  }

  if date != none {
    align(center)[
      #text(size: 11pt, fill: luma(100))[#date]
    ]
    v(0.5cm)
  }

  // Abstract
  if abstract != none {
    v(1cm)
    align(center)[
      #block(width: 80%)[
        #align(left)[
          #text(weight: "bold")[Abstract] \
          #set par(justify: true, leading: 0.65em)
          #abstract
        ]
      ]
    ]
  }

  pagebreak()

  // ===========================================================================
  // Outline
  // ===========================================================================

  if show-outline {
    outline(
      title: outline-title,
      indent: 1.5em,
      depth: outline-depth,
    )
    pagebreak()
  }

  // ===========================================================================
  // Body
  // ===========================================================================

  doc
}
