# MoonBit ecosystem overlap survey

Survey date: 2026-07-28.

## Search method

The survey searched mooncakes.io documentation/package pages and GitHub using
combinations of: `MoonBit`, `diagnostic`, `source span`, `codespan`, `ariadne`,
`miette`, `error report`, `renderer`, and `label`. It also checked adjacent
high-frequency ideas before selecting this direction.

Search engines cannot prove absence, so the conclusion is deliberately scoped:
no discoverable, reusable MoonBit package with MoonReport's complete boundary
was found on the survey date.

## Rejected candidates

| Candidate | Finding | Decision |
| --- | --- | --- |
| Environment-file loader | `tonyfettes/dotenv` is established | Reject |
| Text diff and patch | `ruifeng/diff` implements Myers and Patience | Reject |
| Glob and gitignore matching | `justjavac/glob` is published and depended upon | Reject |
| Generic assertions | MoonBit core already supplies common assertions | Reject |

## Selected gap

Searches found application-local span and diagnostic records, for example
compiler/tooling code that stores a `SourceSpan`. They did not reveal a package
that combines reusable source indexing, multi-label layout, Unicode-aware
display measurement, context folding, terminal/plain rendering, and stable
machine output.

MoonReport complements those local records: applications can map their own
errors into a small neutral model and receive production-quality reports.

## Differentiation guardrails

- Never claim to be a parser, LSP framework, or logging library.
- Keep source access abstract and rendering deterministic.
- Test tabs, CRLF, Unicode, empty spans, overlaps, and distant multi-file labels.
- Document algorithms and compatibility behavior; do not copy third-party code.
