///|
fn bag_diagnostic(severity : Severity, message : String) -> Diagnostic {
  Diagnostic::new(severity, message)
}

///|
test "bag preserves insertion order and protects its storage" {
  let bag = DiagnosticBag::new()
  bag.add(bag_diagnostic(Warning, "first"))
  bag.add(bag_diagnostic(Error, "second"))
  let copy = bag.to_array()
  copy.clear()
  assert_eq(bag.length(), 2)
  assert_eq(bag.to_array()[0].message(), "first")
  assert_eq(bag.to_array()[1].message(), "second")
}

///|
test "summary counts every severity" {
  let bag = DiagnosticBag::from_array([
    bag_diagnostic(Advice, "a"),
    bag_diagnostic(Warning, "w1"),
    bag_diagnostic(Warning, "w2"),
    bag_diagnostic(Error, "e"),
  ])
  let summary = bag.summary()
  assert_eq(summary.advice(), 1)
  assert_eq(summary.warnings(), 2)
  assert_eq(summary.errors(), 1)
  assert_eq(summary.total(), 4)
  assert_true(summary.has_errors())
}

///|
test "severity filtering and exit thresholds are configurable" {
  let bag = DiagnosticBag::from_array([
    bag_diagnostic(Advice, "a"),
    bag_diagnostic(Warning, "w"),
  ])
  assert_eq(bag.at_least(Warning).length(), 1)
  assert_eq(bag.at_least(Error).length(), 0)
  assert_eq(bag.exit_code(), 0)
  assert_eq(bag.exit_code(fail_on=Warning), 1)
}

///|
test "empty batch renders empty output and succeeds" {
  let sources = SourceMap::new()
  let bag = DiagnosticBag::new()
  assert_true(bag.is_empty())
  assert_eq(bag.render(sources), "")
  assert_eq(bag.render_json_lines(sources), "")
  assert_eq(bag.exit_code(fail_on=Advice), 0)
}
