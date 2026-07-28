# MoonReport quick start

## Add the package

After publication, add MoonReport to a MoonBit module:

```sh
moon add zlhahaha/moonreport
```

Import it from a package:

```moonbit
import {
  "zlhahaha/moonreport" @report,
}
```

## Build a report

Register each input once in a `SourceMap`, then use the returned `SourceId` in
labels. Spans are half-open UTF-8 byte ranges, matching parser-friendly offset
conventions.

```moonbit
let sources = @report.SourceMap::new()
let id = sources.add("settings.toml", "timeout = -1\n")
let diagnostic = @report.Diagnostic::new(Error, "timeout cannot be negative")
  .with_code("CFG001")
  .with_label(
    @report.Label::primary(
      id,
      @report.Span::new(10, 12).unwrap(),
      "use zero or a positive duration",
    ),
  )
  .with_help("set timeout = 30")
```

Use `render` for snapshots and redirected logs, `render_ansi` for an interactive
terminal, `render_compact` for one-line summaries, and `render_json` for editor
or CI integrations. `render_ansi(..., enabled=false)` is byte-for-byte the same
as `render`.

## Report several problems

`DiagnosticBag` preserves insertion order and provides counts and a conventional
exit code:

```moonbit
let bag = @report.DiagnosticBag::new()
bag.add(diagnostic)
println(bag.render(sources))
let status = bag.exit_code(fail_on=Warning)
```

Applications that stream findings can use `bag.render_json_lines(sources)`.
Each line is a complete JSON object, so consumers can process large reports
without buffering an array.

## Coordinate conventions

- `Span` offsets and `Location::column` are zero-based byte values.
- JSON `start_line`, `start_column`, `end_line`, and `end_column` are one-based.

## Preview and apply source fixes

Use `Fix` when a diagnostic can offer an exact replacement. Edits use the same
UTF-8 byte offsets as labels. Validation happens before application, and the
original `SourceMap` is never mutated.

```moonbit
let fix = @report.Fix::new(
  "use the default port",
  applicability=@report.MachineApplicable,
).with_edit(
  @report.TextEdit::replace(
    id,
    @report.Span::new(7, 12).unwrap(),
    "8080",
  ),
)

let (preview, preview_status) = fix.render_preview(sources)
if preview_status.is_valid() {
  println(preview.unwrap())
}

let (updated, apply_status) = fix.apply(sources)
if apply_status.is_valid() {
  println(updated.unwrap().get(id).unwrap().text())
}
```

`render_preview` is intended for terminals and review UIs.
`render_json` provides deterministic fields for editor extensions, CI
annotations, and code-action services.

## Apply a safe batch

`FixPlan` combines independent fixes atomically. Its default
`AutomaticFixes` mode excludes suggestions that require review:

```moonbit
let plan = @report.FixPlan::new()
  .with_fix(first_fix)
  .with_fix(second_fix)
let (updated, status) = plan.apply(sources)
```

Every selected fix is validated first, then the combined edit set is checked
again for cross-fix conflicts. If any edit is invalid or overlaps another,
`updated` is `None` and no partial result is returned. Use `mode=AllFixes`
only after a user has reviewed the suggestions.
- Terminal carets use display columns, expanding tabs and treating common
  wide Unicode characters as two cells.
- Source text is immutable after registration, so cached line indexes remain
  deterministic.
