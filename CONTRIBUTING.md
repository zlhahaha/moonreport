# Contributing to MoonReport

MoonReport welcomes focused fixes, tests, documentation, and renderer features.
Please keep source indexing and rendering deterministic: the core package must
not read the filesystem, inspect terminal state, or depend on wall-clock time.

Before opening a pull request, run the same commands as CI:

```sh
moon fmt --check
moon check --deny-warn
moon build
moon test
moon info
moon run cmd/main
```

New rendering behavior should include a snapshot-style assertion. Indexing and
display-width changes should cover boundary offsets, tabs, CRLF, and relevant
Unicode cases. Public APIs require doc comments and a regenerated
`pkg.generated.mbti`.

Commits should each describe one reviewable feature, fix, or documentation
change. Generated build output, local environment files, editor settings, and
rendered proposal previews are intentionally ignored.
