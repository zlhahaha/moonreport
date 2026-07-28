# Acceptance baseline and post-contest roadmap

MoonReport has reached its OSC acceptance-scale baseline: 4,113 physical
MoonBit lines and 84 passing tests. The implemented surface is deliberately
cohesive rather than a collection of unrelated utilities.

## Baseline delivered

- UTF-8 byte-offset indexing, source locations, CRLF, tabs, and display width;
- primary and secondary labels, context merging, folding, and multiline spans;
- plain, ANSI, compact, JSON, and JSON Lines output;
- diagnostic batches, filtering, severity promotion, budgets, and CI status;
- validated atomic edits, previews, JSON interchange, and batch fix plans;
- configuration-validator example and Ubuntu/Windows CI definition.

The baseline is sufficient for parsers, configuration validators, linters,
compilers, test frameworks, code generators, and command-line tools to share
one diagnostic model instead of rebuilding source excerpts and error output.

## Post-contest candidates

Future work should be driven by adopter feedback and kept outside the
acceptance claim:

- Language Server Protocol conversion helpers;
- terminal capability policy (`auto`, `always`, `never`);
- optional wcwidth-compatible display-width tables;
- randomized invariant tests for source indexing and edit application;
- adapters for popular MoonBit parser libraries as those APIs stabilize.

These are extensions, not requirements for the current 4k–10k submission.
