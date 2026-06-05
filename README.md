# typst-tech-report

A Claude Code plugin that produces arxiv-style technical PDF reports about a software project using [Typst](https://typst.app).

When invoked, the skill:

1. Reads the codebase to understand what's there.
2. Asks for language (en/ru/…), technical depth (1–5), and audience.
3. Proposes a section outline for confirmation.
4. Writes `tech-report/report.typ` + `report.pdf` in the project root and shows you the PDF.

The bundled template is generic — serif body (New Computer Modern), justified paragraphs, numbered headings, light-gray tables, optional table of contents. No branding.

## Requirements

- [Typst CLI](https://github.com/typst/typst) 0.14+ — `brew install typst`, `cargo install --locked typst-cli`, or [prebuilt binaries](https://github.com/typst/typst/releases).
- [Claude Code](https://claude.com/claude-code).

## Install

In Claude Code:

```
/plugin marketplace add dailydaniel/typst-tech-report
/plugin install typst-tech-report@typst-tech-report
```

(The repo is both the marketplace and the plugin, hence the doubled name in the install command.)

## Use

```
/typst-tech-report
```

Or ask Claude in plain language: *"make a technical report for this project using the typst-tech-report skill"*.

## License

[MIT](LICENSE).
