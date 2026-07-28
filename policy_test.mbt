///|
fn policy_diagnostic(
  severity : Severity,
  code : String,
  message : String,
  start : Int,
) -> Diagnostic {
  Diagnostic::new(severity, message)
  .with_code(code)
  .with_label(
    Label::primary(
      SourceId::new(0).unwrap(),
      Span::new(start, start + 1).unwrap(),
      message,
    ),
  )
}

///|
test "policy filters below minimum severity" {
  let bag = DiagnosticBag::from_array([
    policy_diagnostic(Advice, "A1", "hint", 0),
    policy_diagnostic(Warning, "W1", "careful", 1),
    policy_diagnostic(Error, "E1", "broken", 2),
  ])
  let result = DiagnosticPolicy::new().with_minimum(Warning).apply(bag)
  assert_eq(result.emitted().length(), 2)
  assert_eq(result.suppressed().length(), 1)
  assert_true(result.suppressed()[0].reason() == BelowMinimum)
}

///|
test "allow rules suppress and deny rules promote by code" {
  let bag = DiagnosticBag::from_array([
    policy_diagnostic(Warning, "STYLE", "style", 0),
    policy_diagnostic(Warning, "SECURITY", "security", 2),
  ])
  let result = DiagnosticPolicy::new()
    .allow_code("STYLE")
    .deny_code("SECURITY")
    .apply(bag)
  assert_eq(result.emitted().length(), 1)
  assert_true(result.emitted().to_array()[0].severity() == Error)
  assert_true(result.suppressed()[0].reason() == CodeAllowed("STYLE"))
  assert_eq(result.summary().promoted(), 1)
}

///|
test "selected codes form an explicit inclusion set" {
  let bag = DiagnosticBag::from_array([
    policy_diagnostic(Warning, "W1", "first", 0),
    policy_diagnostic(Warning, "W2", "second", 2),
    Diagnostic::new(Error, "uncoded").with_label(
      Label::primary(
        SourceId::new(0).unwrap(),
        Span::new(4, 5).unwrap(),
        "uncoded",
      ),
    ),
  ])
  let result = DiagnosticPolicy::new().select_code("W2").apply(bag)
  assert_eq(result.emitted().length(), 1)
  assert_eq(result.emitted().to_array()[0].code().unwrap(), "W2")
  assert_eq(result.suppressed().length(), 2)
  assert_true(result.suppressed()[0].reason() == NotSelected("W1"))
  assert_true(result.suppressed()[1].reason() == NotSelected(""))
}

///|
test "warnings-as-errors changes output without mutating input" {
  let warning = policy_diagnostic(Warning, "W1", "careful", 0)
  let bag = DiagnosticBag::from_array([warning])
  let result = DiagnosticPolicy::new().with_warnings_as_errors(true).apply(bag)
  assert_true(result.emitted().to_array()[0].severity() == Error)
  assert_true(bag.to_array()[0].severity() == Warning)
  assert_eq(result.summary().promoted(), 1)
}

///|
test "equivalent diagnostics are deduplicated by default" {
  let first = policy_diagnostic(Error, "E1", "broken", 0)
  let second = first.with_note("reported by another validation pass")
  let bag = DiagnosticBag::from_array([first, second])
  let result = DiagnosticPolicy::new().apply(bag)
  assert_eq(result.emitted().length(), 1)
  assert_eq(result.summary().duplicates(), 1)
  assert_true(result.suppressed()[0].reason() == Duplicate)
}

///|
test "deduplication can be disabled" {
  let diagnostic = policy_diagnostic(Error, "E1", "broken", 0)
  let bag = DiagnosticBag::from_array([diagnostic, diagnostic])
  let result = DiagnosticPolicy::new().with_deduplication(false).apply(bag)
  assert_eq(result.emitted().length(), 2)
  assert_eq(result.summary().duplicates(), 0)
}

///|
test "fingerprints ignore label order but include positions" {
  let source = SourceId::new(0).unwrap()
  let left = Label::primary(source, Span::new(0, 1).unwrap(), "first")
  let right = Label::secondary(source, Span::new(2, 3).unwrap(), "second")
  let one = Diagnostic::new(Error, "broken")
    .with_code("E1")
    .with_label(left)
    .with_label(right)
  let reordered = Diagnostic::new(Error, "broken")
    .with_code("E1")
    .with_label(right)
    .with_label(left)
  let moved = Diagnostic::new(Error, "broken")
    .with_code("E1")
    .with_label(left)
    .with_label(Label::secondary(source, Span::new(3, 4).unwrap(), "second"))
  assert_eq(diagnostic_fingerprint(one), diagnostic_fingerprint(reordered))
  assert_true(diagnostic_fingerprint(one) != diagnostic_fingerprint(moved))
}

///|
test "per-severity budgets are independent after promotion" {
  let bag = DiagnosticBag::from_array([
    policy_diagnostic(Advice, "A1", "a1", 0),
    policy_diagnostic(Advice, "A2", "a2", 1),
    policy_diagnostic(Warning, "W1", "w1", 2),
    policy_diagnostic(Warning, "W2", "w2", 3),
    policy_diagnostic(Error, "E1", "e1", 4),
    policy_diagnostic(Error, "E2", "e2", 5),
  ])
  let result = DiagnosticPolicy::new()
    .limits(advice=Some(1), warnings=Some(1), errors=Some(1))
    .apply(bag)
  let summary = result.emitted().summary()
  assert_eq(summary.advice(), 1)
  assert_eq(summary.warnings(), 1)
  assert_eq(summary.errors(), 1)
  assert_eq(result.summary().budgeted(), 3)
}

///|
test "total budget is applied after severity budgets" {
  let bag = DiagnosticBag::from_array([
    policy_diagnostic(Error, "E1", "one", 0),
    policy_diagnostic(Error, "E2", "two", 1),
    policy_diagnostic(Error, "E3", "three", 2),
  ])
  let result = DiagnosticPolicy::new().with_total_limit(2).apply(bag)
  assert_eq(result.emitted().length(), 2)
  assert_eq(result.suppressed().length(), 1)
  assert_true(result.suppressed()[0].reason() == TotalBudget(2))
}

///|
test "zero limits suppress all matching diagnostics" {
  let bag = DiagnosticBag::from_array([
    policy_diagnostic(Warning, "W1", "warning", 0),
    policy_diagnostic(Error, "E1", "error", 1),
  ])
  let result = DiagnosticPolicy::new()
    .with_warning_limit(0)
    .with_error_limit(0)
    .apply(bag)
  assert_eq(result.emitted().length(), 0)
  assert_eq(result.summary().budgeted(), 2)
}

///|
test "policy summaries reconcile input and output" {
  let duplicate = policy_diagnostic(Error, "E1", "broken", 0)
  let bag = DiagnosticBag::from_array([
    policy_diagnostic(Advice, "A1", "hint", 1),
    duplicate,
    duplicate,
  ])
  let result = DiagnosticPolicy::new().with_minimum(Warning).apply(bag)
  let summary = result.summary()
  assert_eq(summary.input(), 3)
  assert_eq(summary.emitted(), 1)
  assert_eq(summary.suppressed(), 2)
  assert_eq(summary.input(), summary.emitted() + summary.suppressed())
  assert_true(result.has_suppressed())
}

///|
test "suppression reasons provide CLI-ready explanations" {
  assert_eq(SuppressionReason::Duplicate.name(), "duplicate")
  assert_true(
    SuppressionReason::SeverityBudget(Warning, 3).message().contains("3"),
  )
  assert_true(
    SuppressionReason::CodeAllowed("STYLE").message().contains("STYLE"),
  )
}
