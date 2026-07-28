///|
test "compact renderer includes source position code note and help" {
  let sources = SourceMap::new()
  let source = sources.add("app.toml", "name = \"demo\"\nport = 0")
  let diagnostic = Diagnostic::new(Severity::Error, "port must be positive")
    .with_code("CFG001")
    .with_note("zero disables the listener")
    .with_help("use a value between 1 and 65535")
    .with_label(
      Label::primary(source, Span::new(21, 22).unwrap(), "invalid port"),
    )
  assert_eq(
    render_compact(sources, diagnostic),
    "app.toml:2:8: error: port must be positive [CFG001]\n  note: zero disables the listener\n  help: use a value between 1 and 65535",
  )
}

///|
test "compact renderer degrades gracefully without a label" {
  let sources = SourceMap::new()
  let diagnostic = Diagnostic::new(Severity::Warning, "configuration is empty")
  assert_eq(
    render_compact(sources, diagnostic),
    "warning: configuration is empty",
  )
}

///|
test "compact batch rendering has stable separators" {
  let sources = SourceMap::new()
  let diagnostics = [
    Diagnostic::new(Severity::Advice, "first"),
    Diagnostic::new(Severity::Warning, "second"),
  ]
  assert_eq(
    render_compact_all(sources, diagnostics),
    "advice: first\nwarning: second",
  )
}
