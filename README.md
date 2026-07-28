# MoonReport

MoonReport is a pure MoonBit toolkit for turning byte offsets and validation
failures into readable, source-aware diagnostics.

It is designed for parsers, configuration validators, linters, compilers,
code generators, test frameworks, and command-line tools. A caller supplies
source files, spans, labels, and optional help text; MoonReport produces stable
plain-text or ANSI output without requiring a terminal or filesystem.

## Planned scope

- UTF-8-aware source files, line indexes, tabs, and display columns
- errors, warnings, notes, help, codes, and multiple labeled spans
- deterministic context selection and folding for distant labels
- single-line and multi-line annotations with overlap handling
- plain text, ANSI, compact, and machine-readable renderers
- themes, width policies, snapshots, fuzz properties, and runnable examples

The implementation is original and released under Apache-2.0. See
[`docs/ecosystem-survey.md`](docs/ecosystem-survey.md) for the overlap survey
and [`docs/project-charter.md`](docs/project-charter.md) for the acceptance
boundary.

## Development

```sh
moon check --deny-warn
moon test
moon fmt --check
moon info
moon run cmd/main
```

The public API and examples will grow through independently tested milestones.
