# Roadmap to the 4k-10k acceptance scope

MoonReport deliberately starts with a small, verified core. The repository has
2,114 physical MoonBit source lines at the 0.1.0 proposal checkpoint. The
following increments take the implementation beyond 4,000 effective project
lines without generated or filler code.

## 0.2 - Fix suggestions

- typed replacement, insertion, and deletion suggestions;
- applicability levels for machine-safe and review-required edits;
- overlap validation and deterministic edit application;
- unified preview rendering and JSON representation;
- Unicode, CRLF, adjacent-edit, and conflict tests.

Expected increment: 650-900 MoonBit lines.

## 0.3 - Layout planning

- a renderer-independent annotation layout plan;
- lanes for overlapping and multiline labels;
- width budgets, source elision, and long-line clipping;
- stable ordering and deduplication across multiple sources;
- golden tests for dense diagnostics and narrow terminals.

Expected increment: 800-1,100 MoonBit lines.

## 0.4 - Policy and integration

- diagnostic fingerprints and configurable deduplication;
- severity overrides, warning budgets, and code-based filtering;
- terminal capability policy (`auto`, `always`, `never`);
- GitHub Actions workflow commands and SARIF-compatible output;
- property tests for indexing, spans, edits, and layout invariants.

Expected increment: 900-1,300 MoonBit lines.

## Release boundary

The acceptance release targets 4,000-5,500 maintained MoonBit lines. The upper
10,000-line boundary leaves room for additional renderers and integration
adapters without turning MoonReport into a parser, LSP, logging framework, or
filesystem library.
