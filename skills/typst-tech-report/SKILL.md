---
description: Assemble an arxiv-style technical PDF report about the current project using Typst. Reads the codebase, asks clarifying questions about language and depth, proposes a section outline for confirmation, then generates a .typ file from the bundled template and compiles it to PDF in a tech-report/ directory in the project root. Use when the user asks for a project tech report, project passport, architecture document, or similar deliverable.
---

# Typst Tech Report

A skill for producing a clean, arxiv-style technical PDF report about a software project. The report is a "project passport": what the system does, how it's architected, what stack was chosen and why, what's been built, and what's measured.

The bundled template (`templates/tech_report.typ`) is intentionally generic — no branding, serif body (New Computer Modern), justified paragraphs, numbered headings, light-gray tables, optional table of contents.

The full Typst syntax & API reference is embedded at the end of this file (Section 8). Typst is a niche topic and models often haven't seen enough of it to reliably write more than trivial examples — consult that reference before writing anything beyond a basic paragraph.

---

## 1. Typst version & documentation

**This skill targets Typst `0.14.x`** (released October 2025). The embedded reference in Section 8 is written for `0.14`.

Before doing anything else:

1. Check the user's installed version: `typst --version`.
2. If the installed version is **older than 0.14**, do NOT upgrade silently. Ask the user whether to upgrade, and warn that some features used in the template (PDF-export rewrite via `krilla`, multiple table headers, etc.) require 0.14+.
3. If the installed version is **newer** than what this skill targets:
   - Check the changelog: https://typst.app/docs/changelog/
   - Skim for breaking changes in `set`/`show` rules, `table`, `image`, `outline`, `page`, `text`, or in the API functions used by the template.
   - If anything looks like it might break the template or the report patterns here, mention it to the user before proceeding.
   - If the differences are significant, propose updating this skill: edit `SKILL.md` + `templates/tech_report.typ`, bump the version in `.claude-plugin/plugin.json`, and tell the user this skill is now out of date with their Typst.

**Reference URLs** (use only if Section 8 doesn't cover what you need):

- Full reference: https://typst.app/docs/reference/
- Tutorial: https://typst.app/docs/tutorial/
- Changelog: https://typst.app/docs/changelog/
- Packages (Universe): https://typst.app/universe/
- GitHub: https://github.com/typst/typst

---

## 2. Prerequisites

### Typst CLI

This skill compiles via the `typst` CLI (not the Python binding). The CLI ships with `New Computer Modern`, `New Computer Modern Math`, `Libertinus Serif`, and `DejaVu Sans Mono` embedded — no system font installation needed.

**Check whether it's installed and at the right version:**

```bash
which typst && typst --version
```

**If not installed**, suggest one of these. Don't run any of them without the user's say-so:

```bash
# macOS — Homebrew
brew install typst

# Linux / macOS / Windows — Cargo (requires Rust toolchain)
cargo install --locked typst-cli

# Windows — Winget
winget install --id Typst.Typst

# Windows — Scoop
scoop install typst

# Arch Linux
pacman -S typst

# Any OS — prebuilt binaries
# https://github.com/typst/typst/releases
```

Official install guide: https://github.com/typst/typst#installation

**If installed but old (< 0.14)**: ask the user before upgrading. Don't silently run `brew upgrade typst` or `cargo install --force`.

### Fonts

Do **not** ship fonts in the report directory or the skill. The embedded set covers the template. Run `typst fonts --ignore-system-fonts` to confirm what's available without system fallback.

---

## 3. Workflow

When invoked, follow this sequence. Each step has a checkpoint — don't skip ahead.

### Step 1 — Gather context

Before asking anything, do a quick read of the project so your clarifying questions are specific, not generic:

- Read `README.md`, `CLAUDE.md`, top-level package manifests (`pyproject.toml`, `package.json`, `Cargo.toml`, etc.).
- List the top-level source layout (`src/`, `packages/`, `app/`).
- Note the git branch and recent commits (`git log --oneline -20`).
- Check for existing reports / docs the user may want to extend rather than replace.

This is usually 3–5 tool calls. Don't deep-read the entire codebase yet.

### Step 2 — Ask clarifying questions

Ask only the items the user didn't already specify. Batch into a single round.

1. **Language** — what language should the report be in? (English / Russian / other). The template defaults to `lang: "en"`; pass `lang: "ru"` for Russian.
2. **Technical depth (1–5 scale)** —
   - 1: executive summary, no code, one page
   - 2: brief overview, diagrams over code, ~2–3 pages
   - 3: balanced — architecture + key code paths, ~5–8 pages *(default)*
   - 4: detailed — full module breakdown, API tables, measured results
   - 5: exhaustive — every subsystem documented, dataflow diagrams, benchmarks
3. **Audience** — internal team / management / external (recruiters, conference, prospective collaborators)? Affects tone and how much background to assume.
4. **Sections to include or skip** — only if the project has unusual emphasis (e.g., "skip deployment, this is research code" or "make sure to cover the data pipeline in detail").

If the user gave a one-line request like "make a tech report", ask all four. If they said "make a russian tech report at depth 3", just confirm audience and special sections.

### Step 3 — Deep-read the project

After clarifications, study the project to the depth requested. Read the actual source — don't paraphrase the README. For depth 3+, you should be able to name the main modules, the data flow between them, and one or two non-obvious design decisions.

### Step 4 — Propose the outline (CHECKPOINT — do not skip)

Before writing any `.typ`, send the user a proposed section outline. Format:

- **In the user's chosen language** (English by default, Russian if they asked for `ru`, etc.).
- A short bullet list of section titles, each with a one-line summary of what will go inside.
- 5–10 sections, matching the depth level chosen in Step 2.

Then wait for one of: confirmation, edits ("add a section on X", "drop Y"), or a different direction. Only after confirmation, move to Step 5.

Example (English, depth 3):

```
Proposed outline for the report:

1. Introduction — what scout-agent-core is, the problem it solves, headline outcome
2. Architecture — three-layer breakdown (data marts → agent core → AG-UI server), data flow
3. Stack — smolagents, Qwen3 235B FP8 via OpenAI-compatible endpoint, FastAPI, SQLite WAL
4. Implementation — per-package walkthrough: scout_core, smolagents_agui, api
5. Tools surface — what tools the agent has access to, with one-line descriptions
6. Deployment — Docker compose layout, prod endpoint, observability
7. Open questions — TM bridge extension, prod thread-wipe bug under investigation

OK to proceed, or want changes?
```

Same structure in Russian (`lang: "ru"`):

```
Предлагаемая структура отчёта:

1. Введение — что такое scout-agent-core, какую задачу решает, ключевой результат
2. Архитектура — три слоя (витрины → ядро агента → AG-UI сервер), поток данных
...

Ок, погнали, или нужно что-то поменять?
```

### Step 5 — Create the report directory

In the **project root** (not in this skill's directory), create:

```
<project-root>/tech-report/
├── tech_report.typ     (the template, copied)
├── report.typ          (the actual report)
└── report.pdf          (after compile)
```

**Do not** add `tech-report/` to `.gitignore`. The report is a project artifact and should be committed alongside the code.

If `tech-report/` already exists with previous reports, either overwrite `report.typ` (after confirming with the user) or write to a dated filename like `report-2026-06.typ`.

### Step 6 — Write the report

Copy the template into the report directory:

```bash
cp "${CLAUDE_PLUGIN_ROOT}/skills/typst-tech-report/templates/tech_report.typ" <project-root>/tech-report/
```

**Why the copy?** Typst's `#import "name.typ"` resolves the path **relative to the importing file** (not to the cwd, not to a global package store). So `tech_report.typ` must sit in the same directory as `report.typ` — that's the cheapest way to make the import work. No installation step, no `~/.local/share/typst/packages/...` paths, nothing to PATH. Verified — both `cd tech-report && typst compile report.typ` and `typst compile tech-report/report.typ` from the project root work identically.

If the user later wants to reuse the same template across many projects without copying, they can install it as a local Typst package (drop it into `~/.local/share/typst/packages/local/tech-report/0.1.0/tech_report.typ` with a `typst.toml`, then `#import "@local/tech-report:0.1.0": tech-report`). Don't do that automatically — only if they ask. For a single project, the copy is simpler and self-contained.

Then write `report.typ`:

```typst
#import "tech_report.typ": tech-report

#show: tech-report.with(
  title: "Project Name — Technical Report",
  subtitle: "Architecture, stack, current state",
  authors: (
    (name: "Author Name", affiliation: "Org", email: "author@example.com"),
  ),
  date: "Month YYYY",
  abstract: [Two to four sentences summarising what the system does and what this report covers.],
  lang: "en",
)

= Introduction
...
```

For the content of the report body, follow the structure confirmed in Step 4. For Typst syntax, consult Section 8 below.

### Step 7 — Compile

```bash
cd <project-root>/tech-report && typst compile report.typ report.pdf
```

If compilation fails, read the error, fix the `.typ`, recompile. Typst error messages are precise (line + column). Common causes: unmatched brackets in math mode, wrong content/code mode for an expression, function called without required parameter.

### Step 8 — Deliver

Show the PDF to the user via `SendUserFile`. Briefly summarise what's inside (sections, page count, anything you skipped or simplified). Offer to iterate.

---

## 4. Template API

The template is at `templates/tech_report.typ`. It exposes one function: `tech-report`.

**Required parameter:**

- `title` — string, displayed large on the title page and in the page header

**Optional parameters with sensible defaults:**

| Parameter | Default | Purpose |
|---|---|---|
| `subtitle` | `none` | Subtitle under the title on page 1 |
| `authors` | `()` | List of `(name, affiliation, email)` dicts; affiliation/email optional |
| `date` | `none` | Date string, e.g. `"June 2026"` |
| `abstract` | `none` | Content block; rendered centered on title page |
| `show-outline` | `true` | Table of contents on page 2 |
| `outline-depth` | `3` | How deep the ToC goes |
| `outline-title` | `[Contents]` | ToC heading (use `[Содержание]` for Russian) |
| `paper` | `"a4"` | Paper size |
| `margin` | `(x: 2cm, y: 2cm)` | Page margins |
| `lang` | `"en"` | Language tag (`"ru"`, `"de"`, ...) |
| `body-font` | `"New Computer Modern"` | Main text font |
| `body-size` | `11pt` | Body font size |
| `mono-font` | `"DejaVu Sans Mono"` | Code font |
| `math-font` | `"New Computer Modern Math"` | Math font |
| `heading-numbering` | `"1.1"` | Heading numbering scheme (use `"1."` for flat) |
| `page-numbering` | `"1"` | Page number format |

**Built-in styling** (no parameters needed):

- Heading levels 1–3 styled (size, weight, italic for level 3).
- Tables: light-gray border (`0.5pt + luma(180)`), bold header row with light-gray fill.
- Inline code: small light-gray pill.
- Block code: light-gray panel with thin border.
- Links: blue underlined.
- Page header on pages > 1: small gray title, right-aligned.

---

## 5. Report content guide

A good arxiv-style project report is structured top-down: from the goal of the system to the implementation details. Adapt to project type, but the typical skeleton is:

### Introduction
- What problem does the project solve?
- Who is it for?
- What's the headline outcome? (one or two sentences)

### Architecture
- Diagram or numbered list of major components.
- Data flow: where does input come from, what gets produced.
- Key abstractions (state machine, event bus, agent loop, etc.).
- Non-obvious design decisions and their tradeoffs.

### Stack
- Languages, frameworks, third-party services.
- Why each was chosen (briefly — one line per major choice).
- What was rejected and why, if there were real alternatives considered.

### Implementation
- Per-module breakdown: name, purpose, key public interface.
- For ML/data projects: features, model architecture, training data, validation strategy.
- For agent/LLM projects: tool surface, prompts/system instructions overview, memory model.
- Reference actual file paths in inline code: `package/module.py:line`.

### Results / measurements
- Benchmarks, evaluation metrics, error rates.
- Comparison tables against baselines.
- Plots if you have them — either pre-generated PNGs or drawn directly via `cetz` (see Section 8.18).
- For projects without measurements, replace with "Validation" — how was the system verified to work.

### Deployment
- How it runs in production (Docker, K8s, FastAPI, etc.).
- Configuration, secrets, environment variables.
- Observability — logs, metrics, dashboards.

### Open questions / future work
- Known limitations.
- What you'd do with more time.
- Concrete next steps if any are planned.

**Length guidance by depth:**

- Depth 1: Introduction + Architecture only, no subsections.
- Depth 2: + Stack, brief Implementation.
- Depth 3: All sections, 1–2 paragraphs each.
- Depth 4: All sections with subsections, tables, code snippets.
- Depth 5: Add appendices — full API tables, dataflow diagrams, benchmark methodology.

---

## 6. Common report-writing patterns

### Component listing → use a table

```typst
#table(
  columns: (auto, 1fr),
  table.header([*Component*], [*Purpose*]),
  [`scout_core`], [Tools, prompts, model guard],
  [`smolagents_agui`], [AG-UI protocol translator + persistence],
  [`api`], [FastAPI server with /threads, /runs, /artifacts],
)
```

### Feature/parameter explanation → kv-style table

```typst
#table(
  columns: (auto, auto, 2fr),
  table.header([*Feature*], [*Type*], [*Description*]),
  [`max_depth`], [int], [Maximum boosting tree depth],
  [`learning_rate`], [float], [Step size shrinkage],
)
```

### Highlighted finding → block quote callout

```typst
#rect(
  width: 100%,
  inset: 1em,
  fill: luma(245),
  stroke: 1pt + luma(180),
)[
  *Key finding:* The model is 4× faster than the previous baseline
  while matching its accuracy.
]
```

### Math formula

Inline for variables in a sentence: `$T_"context" = T_"system" + T_"history"$`.
Block for derivations:

```typst
$ "BS" = frac(1, N) sum_(i=1)^N (p_i - y_i)^2 $
```

### Code block with language

```typst
` ``python
def hello():
    print("world")
` ``
```

(Remove the spaces inside the backticks — Markdown formatting here.)

### Figure with reference

```typst
#figure(
  image("arch.svg", width: 80%),
  caption: [System architecture: three-layer pipeline from data marts to UI.],
) <fig-arch>

See @fig-arch for the high-level component layout.
```

---

## 7. Updating this skill

If during a run you notice:

- A new Typst version has shipped breaking changes that affect the template or the reference in Section 8.
- A pattern in the template is no longer idiomatic (deprecated function, replaced syntax).
- A common report-writing need keeps coming up that isn't covered.

…then update this skill:

1. Edit `SKILL.md` and/or `templates/tech_report.typ`.
2. Bump the version in `.claude-plugin/plugin.json` (semver: patch for fixes, minor for new features, major for breaking).
3. Tell the user the skill is now updated and what changed.

The skill repository is the source of truth — changes here propagate to anyone who has it installed.

---

# Section 8 — Typst Reference (self-contained)

This is the bulk of the skill. Treat it as the authoritative source while working — Typst is a niche topic and models tend to hallucinate its syntax. If something here doesn't match what `typst compile` says, trust `typst` and update this section.

Targets Typst 0.14.x.

## 8.1 Content modes

Typst has three modes:

- **Markup mode** (default) — plain text and markup syntax like `= heading`, `- list`, `*bold*`, `_italic_`, `` `code` ``.
- **Code mode** — after `#` or inside `{ ... }`. Lets you call functions, do arithmetic, branch.
- **Math mode** — inside `$ ... $`. Special syntax for formulas.

You switch between them constantly. `#emph[hi]` is code mode calling `emph` with a content-mode argument.

## 8.2 Headings

```typst
= Level 1
== Level 2
=== Level 3
==== Level 4

#set heading(numbering: "1.")     // 1., 2., 3.
#set heading(numbering: "1.1")    // 1., 1.1., 1.1.1.
#set heading(numbering: "1.a")    // 1., 1.a., 1.a.i.
```

To style headings, use `show heading.where(level: N): it => { ... }`.

## 8.3 Text formatting

| Markup | Function | Effect |
|---|---|---|
| `*bold*` | `strong[bold]` | **Bold** |
| `_italic_` | `emph[italic]` | *Italic* |
| `` `code` `` | `raw("code")` | `Monospace` |
| | `#underline[u]` | Underlined |
| | `#strike[s]` | Struck out |
| | `#highlight[h]` | Highlighted |
| | `#smallcaps[S]` | Small caps |
| | `#super[2]` | Superscript |
| | `#sub[1]` | Subscript |
| | `#upper[hi]` | UPPERCASE |
| | `#lower[Hi]` | lowercase |

## 8.4 Lists

```typst
// Bulleted
- item one
- item two
  - nested

// Numbered
+ first
+ second
  + nested

// Term list
/ Term: Definition
/ Other term: Other definition
```

## 8.5 Links and references

```typst
// Hyperlink
#link("https://typst.app")[Typst]
#link("mailto:user@example.com")

// Label & cross-reference
A figure is shown below. <fig-1>

#figure(image("x.png"), caption: [Caption]) <fig-2>
As shown in @fig-2, ...
```

## 8.6 Images and figures

```typst
#image("path.jpg")
#image("path.png", width: 50%)
#image("path.svg", height: 3cm)

#figure(
  image("photo.jpg", width: 80%),
  caption: [Caption text.],
) <my-label>
```

Supported formats: PNG, JPEG, GIF, SVG, PDF (since 0.14), WebP (since 0.14).

## 8.7 Math

```typst
// Inline
The Pythagorean theorem: $x^2 + y^2 = z^2$.

// Block
$ sum_(i=0)^n a_i x^i $

// Common constructs
$x^2$           // superscript
$x_i$           // subscript
$a / b$         // fraction (or frac(a, b))
$sqrt(x)$       // square root
$root(3, x)$    // cube root
$vec(x, y, z)$  // column vector
$mat(a, b; c, d)$  // matrix (rows separated by ;)
$lr([ x_1, ..., x_n ])$  // auto-sized brackets

// Greek letters: alpha, beta, gamma, delta, epsilon, theta, lambda,
//                mu, nu, pi, rho, sigma, tau, phi, chi, psi, omega
// (uppercase: capitalize first letter — Alpha, Beta, ...)

// Arrows
$arrow.r$       // →
$arrow.l$       // ←
$arrow.lr$      // ↔
$arrow.r.long$  // ⟶

// Text inside formula
$ y = "salary" + 1 $

// Operators
$sum_(i=1)^n$    sum_(...)^...
$product_(i=1)^n$
$integral_a^b$
$lim_(x -> 0)$
$max_(x in X)$

// Named functions
$sin(x), cos(x), tan(x), log(x), ln(x), exp(x)$

// Sets
$RR$    // real numbers (or upright bold R)
$NN$    // naturals
$ZZ$    // integers
$QQ$    // rationals
$CC$    // complex
```

## 8.8 Tables

```typst
#table(
  columns: (1fr, auto, auto),       // 1 flex column, 2 auto-sized
  inset: 8pt,
  align: (left, center, right),
  table.header(
    [*Name*], [*Age*], [*Score*],
  ),
  [Alice], [30], [95],
  [Bob], [25], [88],
)
```

**Styling table headers:**

```typst
#set table(stroke: 0.5pt + luma(180), inset: 6pt)
#show table.cell.where(y: 0): set text(weight: "bold")
#show table.cell.where(y: 0): set table.cell(fill: luma(230))
```

**Conditional fill (zebra rows):**

```typst
#table(
  columns: 3,
  fill: (_, y) => if calc.odd(y) { luma(245) },
  ...
)
```

**Spanning cells:**

```typst
#table(
  columns: 3,
  table.cell(colspan: 2)[wide cell], [normal],
  table.cell(rowspan: 2)[tall], [a], [b],
  [c], [d],
)
```

## 8.9 Code blocks

```typst
// Inline
The function `process_data()` returns ...

// Block with syntax highlighting
` ``python
def hello():
    print("world")
` ``

// Programmatic (when you need to compute the text)
#raw(content, lang: "rust", block: true)
```

The triple-backtick form takes a language tag right after the opening fence (`` ```python ``, `` ```rust ``, `` ```bash ``, etc.). Typst auto-highlights for supported languages.

## 8.10 Page setup

```typst
#set page(
  paper: "a4",                         // "a4", "a5", "us-letter", "iso-b5", ...
  margin: (x: 2cm, y: 2.5cm),
  // or: margin: (top: 2cm, bottom: 2cm, left: 2cm, right: 2cm),
  numbering: "1",                      // "1", "i", "I", "a", "A"
  number-align: center + bottom,
  header: [Header text],
  footer: [Footer text],
  columns: 2,                          // multi-column page
  fill: white,
)

#pagebreak()
#pagebreak(weak: true)                 // skip if already on a new page
```

**Conditional header (only on pages > 1):**

```typst
#set page(
  header: context {
    if counter(page).get().first() > 1 [
      Document Title
    ]
  }
)
```

## 8.11 Text and paragraph

```typst
#set text(
  font: "New Computer Modern",
  size: 11pt,
  weight: "regular",                  // "thin", "light", "regular", "medium", "bold", "black"
  style: "normal",                    // "normal", "italic", "oblique"
  fill: black,
  lang: "en",                         // affects hyphenation, smart quotes
  region: "us",
)

#set par(
  justify: true,
  leading: 0.65em,                    // line spacing within a paragraph
  first-line-indent: 1em,
  spacing: 1.2em,                     // gap between paragraphs
)
```

## 8.12 Set and show rules

**`set` — sets default parameters of a function:**

```typst
#set text(size: 12pt)
#set page(margin: 2cm)
#set heading(numbering: "1.")
```

**`show` — transforms elements:**

```typst
// Apply a function to every heading
#show heading: smallcaps

// Filter by selector, then set or transform
#show heading.where(level: 1): set text(size: 16pt)
#show heading.where(level: 2): it => emph(it.body)

// Replace string literals
#show "Typst": "TYPST"

// Wrap the whole document in a template
#show: my-template
#show: my-template.with(title: "Doc")
```

## 8.13 Variables, functions, conditions, loops

```typst
// Variables
#let name = "Alice"
#let n = 42
#let pi-approx = 3.14
#let items = (1, 2, 3)              // array
#let person = (name: "Bob", age: 30)  // dictionary
#let flag = true

// Function
#let greet(name) = [Hello, #name!]
#let styled(body, color: blue) = {
  set text(fill: color)
  body
}

// Partial application (curry)
#let blue-styled = styled.with(color: blue)

// Conditions
#if n > 0 [positive] else [non-positive]

#let kind = if n > 0 { "pos" } else if n < 0 { "neg" } else { "zero" }

// Loops
#for item in items [
  Item: #item \
]

#for (k, v) in person [
  - #k: #v
]

#while n > 0 { n -= 1 }
```

## 8.14 Imports and modules

```typst
// Import specific names
#import "template.typ": tech-report, helper

// Import everything
#import "template.typ": *

// Import a module without unpacking
#import "utils.typ"
#utils.helper()

// Universe packages
#import "@preview/cetz:0.3.4"
#import "@preview/cetz-plot:0.1.1": chart, plot

// Local packages (~/.local/share/typst/packages/<namespace>/<name>/<version>/)
#import "@local/mypkg:1.0.0": something

// Include another file's contents inline
#include "appendix.typ"
```

## 8.15 Layout

```typst
// Alignment
#align(center)[centered]
#align(center + horizon)[centered both ways]
#align(right + bottom)[corner]

// Blocks (block-level, fillable container)
#block(
  width: 100%,
  fill: luma(240),
  inset: 10pt,
  radius: 4pt,
  stroke: 0.5pt + luma(180),
)[content]

// Boxes (inline container)
#box(stroke: 1pt, inset: 4pt)[inline content]

// Padding (without a fill/stroke)
#pad(x: 1em, y: 0.5em)[padded]
#pad(left: 2em)[left-padded only]

// Grid (rigid columns/rows)
#grid(
  columns: (1fr, 1fr, auto),
  row-gutter: 12pt,
  column-gutter: 16pt,
  [a], [b], [c],
  [d], [e], [f],
)

// Stack (flexible direction)
#stack(dir: ttb, spacing: 1em, [a], [b], [c])  // top to bottom
#stack(dir: ltr, spacing: 1em, [a], [b], [c])  // left to right

// Multi-column flowed text
#columns(2)[
  Long text that flows into two columns.
  #colbreak()
  Second column starts here.
]

// Spacing
#v(1em)         // vertical space
#h(2em)         // horizontal space
#h(1fr)         // flexible horizontal space (push to edge)
#linebreak()    // or just `\` in text

// Place (absolute or floating)
#place(top + right)[absolute positioned]
#place(top + center, float: true, scope: "parent")[floats above content]
```

## 8.16 Shapes

```typst
#rect(width: 100%, height: 2cm, fill: blue, radius: 4pt)
#square(size: 1cm, fill: green)
#circle(radius: 1cm, fill: red)
#ellipse(width: 3cm, height: 2cm, fill: orange)
#line(length: 100%, stroke: 2pt + red)
#polygon(fill: blue, (0pt, 0pt), (2cm, 0pt), (1cm, 2cm))

// Bézier curves (since 0.13)
#curve(
  stroke: 2pt + black,
  curve.move((0pt, 0pt)),
  curve.line((1cm, 0pt)),
  curve.cubic(none, (2cm, 1cm), (1cm, 1cm)),
  curve.close(),
)
```

## 8.17 Colors and strokes

```typst
// Predefined: black, white, gray, silver, red, maroon, green, olive,
//             blue, navy, yellow, orange, purple, fuchsia, aqua, teal

#rgb("#ff0000")
#rgb(255, 0, 0)
#rgb(255, 0, 0, 50%)        // with alpha
#luma(200)                  // grayscale
#cmyk(0%, 100%, 100%, 0%)
#oklch(70%, 0.15, 30deg)

// Methods
blue.lighten(80%)
red.darken(20%)
green.saturate(50%)
black.transparentize(70%)

// Gradients
#gradient.linear(red, blue)
#gradient.linear(..color.map.rainbow)
#gradient.radial(red, blue, center: (50%, 50%), radius: 50%)
#gradient.conic(red, blue, center: (50%, 50%))

// Strokes
stroke: 2pt + red
stroke: (paint: blue, thickness: 4pt, cap: "round", dash: "dashed")
// Caps: "butt", "round", "square"
// Joins: "miter", "round", "bevel"
// Dashes: "solid", "dotted", "dashed", "dash-dotted", "dense-dashed", "loose-dashed"
```

## 8.18 cetz — drawing and plots

For diagrams and plots embedded directly in the document:

```typst
#import "@preview/cetz:0.3.4"
#import "@preview/cetz-plot:0.1.1": chart, plot

#figure(
  cetz.canvas({
    import cetz.draw: *
    rect((0, 0), (2, 1), fill: blue.lighten(70%))
    line((0, 0), (2, 1), stroke: 2pt + red)
    content((1, 0.5), [Label])
  }),
  caption: [A cetz drawing.],
)

#figure(
  cetz.canvas({
    plot.plot(
      size: (10, 6),
      x-label: [Training samples],
      y-label: [Brier Score],
      x-tick-step: 3000,
      y-min: 0.06,
      y-max: 0.12,
      legend: "north-east",
      {
        plot.add(
          ((221, 0.107), (1102, 0.080), (2675, 0.079), (4334, 0.076)),
          label: "Model A",
          style: (stroke: blue + 2pt),
        )
      },
    )
  }),
  caption: [Brier Score vs training set size.],
)

#figure(
  cetz.canvas({
    chart.barchart(
      size: (12, 6),
      label-key: 0,
      value-key: 1,
      bar-style: (fill: blue.lighten(40%), stroke: blue),
      (
        ("feature_a", 20),
        ("feature_b", 50),
        ("feature_c", 92),
      ),
    )
  }),
  caption: [Feature importance.],
)
```

cetz versions move fast — pin a specific version in the import. As of 0.14, `cetz:0.3.4` and `cetz-plot:0.1.1` are current.

## 8.19 Outline (table of contents)

```typst
#outline()                              // default: all headings
#outline(depth: 2)                      // limit depth
#outline(title: [Contents])             // custom title
#outline(title: [Содержание], indent: 1.5em, depth: 3)

// Outline for figures
#outline(target: figure)

// Outline for tables only
#outline(target: figure.where(kind: table))
```

The outline was reworked in 0.13 — the old `body` and `page` fields on entries are gone. Use the high-level API (`title`, `depth`, `indent`, `target`).

## 8.20 Footnotes

```typst
This is a sentence#footnote[Explanation in a footnote.] with a note.
```

## 8.21 Counters and state

```typst
// Counter
#let mycounter = counter("mycounter")
#mycounter.step()
#mycounter.update(0)
#context mycounter.display("1")
#context mycounter.get()
#context mycounter.final()

// Built-in counters
#context counter(page).display()
#context counter(heading).display("1.")
#context counter(figure).display()

// State (general-purpose value across the document)
#let mystate = state("flag", false)
#mystate.update(true)
#mystate.update(x => not x)             // mutator function
#context mystate.get()
```

`context` is required because state/counters are resolved during layout.

## 8.22 Query and introspection

```typst
// Find elements with a selector
#context query(heading)
#context query(heading.where(level: 1))
#context query(<my-label>)

// Current position
#context {
  let loc = here()
  [Page #loc.page(), position #loc.position()]
}
```

## 8.23 Data loading

```typst
#let csv-data = csv("file.csv")          // -> array of arrays of strings
#let json-data = json("config.json")     // -> dictionary or array
#let toml-data = toml("settings.toml")
#let yaml-data = yaml("data.yaml")
#let xml-data = xml("doc.xml")
#let text = read("notes.txt")
#let cbor-data = cbor("data.cbor")
```

Since 0.13, all of the above also accept `bytes` instead of a path.

## 8.24 Document metadata

```typst
#set document(
  title: [My Report],
  author: ("Author One", "Author Two"),
  date: datetime.today(),
  keywords: ("typst", "report"),
)
```

## 8.25 Datetime

```typst
#datetime.today()
#datetime(year: 2026, month: 6, day: 5)

#let dt = datetime.today()
#dt.display()                            // default format
#dt.display("[year]-[month]-[day]")
#dt.year()
#dt.month()
#dt.day()
```

## 8.26 Arrays and dictionaries

```typst
// Array
#let arr = (1, 2, 3)
#arr.len()                  // 3
#arr.at(0)                  // 1
#arr.first()
#arr.first(default: 0)      // since 0.14
#arr.last()
#arr.push(4)
#arr.pop()
#arr.map(x => x * 2)
#arr.filter(x => x > 1)
#arr.sorted()
#arr.sorted(by: (a, b) => a > b)   // since 0.14
#arr.fold(0, (acc, x) => acc + x)
#arr.sum()
#arr.join(", ")
#arr.flatten()
#arr.rev()
#arr.enumerate()
#arr.zip(other)
#arr.contains(2)
#arr.slice(1, 3)
#arr.position(x => x > 5)

// Dictionary
#let d = (name: "Alice", age: 30)
#d.at("name")
#d.keys()
#d.values()
#d.pairs()
#d.insert("city", "London")
#d.remove("age")
#d.len()

// Check key presence
#("name" in d)              // true
```

## 8.27 Strings

```typst
#let s = "Hello, World"
#s.len()
#s.contains("World")
#s.starts-with("Hello")
#s.ends-with("World")
#s.replace(",", ";")
#s.split(", ")              // array
#s.trim()
#s.first()
#s.last()
#s.slice(0, 5)
#s.normalize()              // Unicode normalization, since 0.14
#upper(s)                   // "HELLO, WORLD"
#lower(s)                   // "hello, world"

// Regex matching
#s.match(regex("\w+"))
#s.matches(regex("\w+"))
#s.replace(regex("\d+"), "N")
```

## 8.28 Calc

```typst
#calc.abs(-5)               // 5
#calc.min(1, 2, 3)          // 1
#calc.max(1, 2, 3)          // 3
#calc.pow(2, 10)            // 1024
#calc.sqrt(9)               // 3.0
#calc.floor(3.7)            // 3
#calc.ceil(3.2)             // 4
#calc.round(3.5)            // 4
#calc.round(3.14159, digits: 2)  // 3.14
#calc.rem(10, 3)            // 1
#calc.quo(10, 3)            // 3
#calc.log(100)              // 2.0
#calc.ln(2.71828)           // ~1.0
#calc.sin(90deg)            // 1.0
#calc.cos(0deg)             // 1.0
#calc.gcd(12, 8)            // 4
#calc.lcm(4, 6)             // 12
#calc.even(4)               // true
#calc.odd(3)                // true
```

## 8.29 Units

```typst
// Length
1pt, 1mm, 1cm, 1in, 1em

// Fractional (in grid/table)
1fr, 2fr

// Ratio
50%

// Angle
45deg, 1rad

// Duration
1s, 1min, 1h, 1d
```

## 8.30 Data types

- `int` — integer: `42`
- `float` — float: `3.14`
- `decimal` — arbitrary precision decimal
- `bool` — `true` / `false`
- `str` — `"text"`
- `content` — markup: `[Hello]`
- `array` — `(1, 2, 3)`
- `dictionary` — `(a: 1, b: 2)`
- `bytes` — raw bytes
- `length` — `1cm`
- `ratio` — `50%`
- `angle` — `45deg`
- `color` — `rgb(...)`, `luma(...)`, ...
- `datetime` — `datetime.today()`
- `duration` — `1h`
- `regex` — `regex("\d+")`
- `label` — `<my-label>`
- `selector` — `heading.where(level: 1)`
- `function` — `f => f * 2`
- `auto` — placeholder meaning "default"
- `none` — absence of a value
- `arguments` — captured args
- `version` — `version(1, 2, 3)`
- `symbol` — Unicode/math symbol

## 8.31 Common gotchas

- **Markup vs code mode** — `#strong[hi]` (code calling function with content) ≠ `*hi*` (markup). Inside `{ ... }` you're in code mode; use `[...]` to drop back into content.
- **Trailing comma in function calls** — Typst tolerates and often requires trailing commas in arrays and function args. `(1, 2, 3,)` is fine.
- **`set` vs `show`** — `set` changes default args; `show` transforms or replaces elements. `show heading: set text(size: 16pt)` is a common combo: "for every heading, set the text size".
- **Whitespace in math** — Math mode uses spaces as separators for symbols. `$ab$` is the symbol `ab`; `$a b$` is `a` times `b`. Use multi-letter names in quotes: `$"name"$`.
- **Context-dependent values** — Counters and state need `#context { ... }` to read. Outside `context`, `counter(page).get()` errors.
- **Labels must be non-empty** (since 0.14) — `<>` is an error. Same for `link("")`.
- **Image inside figure inside a table cell** — works, but be explicit about widths to avoid overflow.
- **`pagebreak()` inside a flow element** — has no effect if the parent doesn't allow page breaks. Place at the top level.
- **Font fallback** — Typst tries fonts in order. `text(font: ("Inter", "Noto Sans"))` falls back to Noto if Inter isn't found.

## 8.32 CLI

```bash
typst compile input.typ                       # → input.pdf
typst compile input.typ out.pdf
typst compile input.typ out.html --features html
typst compile input.typ --root /path/to/root  # restrict file access
typst compile input.typ --font-path ./fonts   # extra font directory
typst compile input.typ --ignore-system-fonts
typst compile input.typ --input key=value     # pass to sys.inputs

typst watch input.typ                         # auto-recompile on change
typst init template-name                      # scaffold from a template
typst fonts                                   # list available fonts
typst query input.typ "<label>"               # extract metadata
typst info                                    # build info (since 0.14)
typst completions zsh                         # shell completions (since 0.14)
```

## 8.33 What changed in 0.14 (Oct 2025)

**Highlights:**

- PDF export rewritten on top of `krilla`. Faster, supports PDF 1.4–2.0 and all PDF/A levels.
- Accessibility tags by default in PDFs (PDF/UA-1 ready). Disable with `--no-pdf-tags`.
- HTML export significantly expanded (still experimental). Typed HTML functions: `html.div`, `html.span`, `html.p`, etc.
- Math: `frac.style: "skewed"` and `"inline"`. `scr()` for roundhand. `dotless` for accents.
- Tables: multiple headers / subheaders.
- Layout engine is now multithreaded (2–3× speedup on large docs).
- WebP and PDF-as-image support in `image()`.

**Breaking:**

- Type/str comparison removed: `int == "integer"` is now an error. Use `type(x) == int`.
- Empty `font` lists in `text` are an error.
- Empty labels (`<>`) are an error.
- `link("")` is an error.
- `enum.item` default changed from `none` to `auto`.
- Bibliography style renames: `chicago-fullnotes` → `chicago-notes`, etc.

## 8.34 What changed in 0.13 (Feb 2025)

- Paragraphs vs. inline content distinction tightened. Affects `show` rules over content.
- `outline` reworked; `body` and `page` fields on entries removed. Use the new API (`title`, `depth`, `indent`, `target`).
- New `curve` function replaces `path`: `curve.move`, `curve.line`, `curve.cubic`, `curve.close`.
- Plugins: `plugin` is now a function returning a module, not a type.
- HTML export started (behind `--features html`).
- `image()` accepts raw pixel data and bytes.
- Removed: `style()`, `state.display()`, `locate()` compatibility shims.
- Symbol renames: `ohm.inv` → `Omega.inv`. Removed: `degree.c`, `degree.f`, `kelvin`.
