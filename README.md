# MoonReport

MoonReport is a pure MoonBit toolkit for turning byte offsets and validation
failures into readable, source-aware diagnostics. It is useful anywhere a
developer tool needs to point at the exact part of an input that caused a
problem.

It is designed for parsers, configuration validators, linters, compilers,
code generators, test frameworks, and command-line tools. A caller supplies
source files, spans, labels, and optional help text; MoonReport produces stable
plain-text or ANSI output without requiring a terminal or filesystem.

## Features

- UTF-8-aware source files, line indexes, tabs, and display columns
- errors, warnings, notes, help, codes, and multiple labeled spans
- deterministic context selection and folding for distant labels
- single-line and multi-line annotations
- plain text, ANSI, compact, JSON, and JSON Lines renderers
- dark/light terminal themes and ANSI stripping
- diagnostic batches, severity summaries, filtering, and CI exit thresholds

## Quick start

```moonbit
let sources = @report.SourceMap::new()
let id = sources.add("app.conf", "port = 70000")
let problem = @report.Diagnostic::new(Error, "invalid port")
  .with_code("CFG002")
  .with_label(
    @report.Label::primary(
      id,
      @report.Span::new(7, 12).unwrap(),
      "expected a value from 1 to 65535",
    ),
  )
  .with_help("try port 8080")

println(@report.render(sources, problem))
```

Run the included configuration-validator demo:

```sh
moon run cmd/main
```

See [`docs/quickstart.md`](docs/quickstart.md) for package setup, renderer
selection, batch reporting, and output integration.

The implementation is original and released under Apache-2.0. See
[`docs/ecosystem-survey.md`](docs/ecosystem-survey.md) for the overlap survey
and [`docs/project-charter.md`](docs/project-charter.md) for the acceptance
boundary.

## Development and verification

```sh
moon check --deny-warn
moon test
moon fmt --check
moon info
moon run cmd/main
```

The library has no runtime I/O dependency; callers decide how sources are
loaded and where reports are sent. This keeps output deterministic across
native, JavaScript, and WebAssembly environments.
