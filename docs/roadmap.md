# Project status and roadmap

MoonReport currently contains more than 4,000 physical MoonBit lines and 89
passing tests. The implemented surface is deliberately cohesive rather than a
collection of unrelated utilities.

## Current capabilities

- UTF-8 byte-offset indexing, source locations, CRLF, tabs, and display width;
- primary and secondary labels, context merging, folding, and multiline spans;
- plain, ANSI, compact, JSON, and JSON Lines output;
- diagnostic batches, filtering, severity promotion, budgets, and CI status;
- stable diagnostic metrics grouped by severity, code, and source;
- validated atomic edits, previews, JSON interchange, and batch fix plans;
- configuration-validator example and Ubuntu/Windows CI definition.

These capabilities let parsers, configuration validators, linters, compilers,
test frameworks, code generators, and command-line tools share one diagnostic
model instead of rebuilding source excerpts and error output.

## Extension candidates

Future work should be driven by adopter feedback:

- Language Server Protocol conversion helpers;
- terminal capability policy (`auto`, `always`, `never`);
- optional wcwidth-compatible display-width tables;
- randomized invariant tests for source indexing and edit application;
- adapters for popular MoonBit parser libraries as those APIs stabilize.

These are optional extensions, not requirements for using the current library.
