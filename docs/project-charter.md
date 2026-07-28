# Project charter

## Problem

MoonBit tool authors repeatedly implement offsets, line/column lookup, snippets,
carets, colors, and multi-line errors inside each parser or validator. Those
private implementations are difficult to reuse and often fail on tabs, Unicode,
overlapping labels, narrow terminals, or deterministic snapshot tests.

## Product boundary

MoonReport owns the path from immutable source text plus diagnostic metadata to
rendered output. It does not parse a programming language, implement an LSP,
read files, or decide application-specific error semantics. Keeping I/O outside
the core makes the library deterministic and portable across native, Wasm, and
JavaScript targets.

## Users and daily use

- parser and compiler authors reporting syntax/type errors;
- CLI authors validating configuration and command input;
- linters and code generators explaining source transformations;
- test frameworks improving assertion and snapshot failures;
- editor integrations sharing the same diagnostics as a CLI.

## Engineering scope

The project grows through cohesive production features rather than generated
or duplicated code: source indexing, a validated diagnostic model, layout
planning, annotation routing, renderers, themes, serialization, tests, and
examples.

## Definition of done

The repository must have a stable documented API, runnable demo, strict
format/check/build/test CI on major targets, broad unit and golden tests,
property tests for indexing/layout invariants, clean artifacts, Apache-2.0
licensing, and reproducible release instructions.
