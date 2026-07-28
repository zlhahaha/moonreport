///|
test "diagnostic builder preserves structured fields" {
  let source = SourceId::new(3).unwrap()
  let primary = Label::primary(source, Span::new(2, 5).unwrap(), "bad value")
  let secondary = Label::secondary(
    source,
    Span::new(8, 9).unwrap(),
    "used here",
  )
  let diagnostic = Diagnostic::new(Severity::Error, "invalid configuration")
    .with_code("CFG001")
    .with_help("choose a positive value")
    .with_note("values are validated before startup")
    .with_label(primary)
    .with_label(secondary)
  assert_eq(diagnostic.severity().name(), "error")
  assert_eq(diagnostic.message(), "invalid configuration")
  assert_eq(diagnostic.code().unwrap(), "CFG001")
  assert_eq(diagnostic.help().unwrap(), "choose a positive value")
  assert_eq(diagnostic.notes().length(), 1)
  assert_eq(diagnostic.labels().length(), 2)
  assert_true(diagnostic.is_valid())
  assert_eq(diagnostic.primary_label().unwrap().message(), "bad value")
}

///|
test "diagnostic requires a message and primary label" {
  let source = SourceId::new(0).unwrap()
  let span = Span::new(0, 0).unwrap()
  assert_false(Diagnostic::new(Severity::Error, "missing label").is_valid())
  assert_false(
    Diagnostic::new(Severity::Warning, "secondary only")
    .with_label(Label::secondary(source, span, "context"))
    .is_valid(),
  )
  assert_false(
    Diagnostic::new(Severity::Advice, "")
    .with_label(Label::primary(source, span, "location"))
    .is_valid(),
  )
}

///|
test "severity exposes stable machine names and ordering" {
  assert_eq(Severity::Advice.name(), "advice")
  assert_eq(Severity::Warning.name(), "warning")
  assert_eq(Severity::Error.name(), "error")
  assert_true(Severity::Error.rank() > Severity::Warning.rank())
  assert_true(Severity::Warning.rank() > Severity::Advice.rank())
}
