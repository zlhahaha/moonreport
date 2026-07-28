///|
fn metric_label(
  source : SourceId,
  start : Int,
  end : Int,
  primary : Bool,
) -> Label {
  let span = Span::new(start, end).unwrap()
  if primary {
    Label::primary(source, span, "primary")
  } else {
    Label::secondary(source, span, "related")
  }
}

///|
test "empty metrics contain no groups" {
  let metrics = DiagnosticBag::new().metrics()
  assert_eq(metrics.summary().total(), 0)
  assert_eq(metrics.coded(), 0)
  assert_eq(metrics.uncoded(), 0)
  assert_eq(metrics.labels(), 0)
  assert_eq(metrics.primary_labels(), 0)
  assert_eq(metrics.secondary_labels(), 0)
  assert_eq(metrics.unique_codes(), 0)
  assert_eq(metrics.unique_sources(), 0)
  assert_eq(metrics.code_counts().length(), 0)
  assert_eq(metrics.source_counts().length(), 0)
}

///|
test "metrics count codes in first-seen order" {
  let bag = DiagnosticBag::from_array([
    Diagnostic::new(Error, "one").with_code("E2"),
    Diagnostic::new(Warning, "two").with_code("W1"),
    Diagnostic::new(Error, "three").with_code("E2"),
    Diagnostic::new(Advice, "four"),
  ])
  let metrics = bag.metrics()
  let codes = metrics.code_counts()
  assert_eq(metrics.coded(), 3)
  assert_eq(metrics.uncoded(), 1)
  assert_eq(metrics.unique_codes(), 2)
  assert_eq(metrics.count_for_code("E2"), 2)
  assert_eq(metrics.count_for_code("W1"), 1)
  assert_eq(metrics.count_for_code("missing"), 0)
  assert_eq(codes[0].code(), "E2")
  assert_eq(codes[1].code(), "W1")
}

///|
test "multiple labels count one diagnostic per source" {
  let first = SourceId::new(7).unwrap()
  let second = SourceId::new(9).unwrap()
  let diagnostic = Diagnostic::new(Error, "cross-source")
    .with_label(metric_label(first, 0, 1, true))
    .with_label(metric_label(first, 2, 3, false))
    .with_label(metric_label(second, 0, 2, false))
  let metrics = DiagnosticBag::from_array([diagnostic]).metrics()
  assert_eq(metrics.labels(), 3)
  assert_eq(metrics.primary_labels(), 1)
  assert_eq(metrics.secondary_labels(), 2)
  assert_eq(metrics.unique_sources(), 2)
  assert_eq(metrics.diagnostics_for_source(first), 1)
  assert_eq(metrics.labels_for_source(first), 2)
  assert_eq(metrics.diagnostics_for_source(second), 1)
  assert_eq(metrics.labels_for_source(second), 1)
}

///|
test "source groups preserve first-seen order across diagnostics" {
  let first = SourceId::new(4).unwrap()
  let second = SourceId::new(2).unwrap()
  let bag = DiagnosticBag::from_array([
    Diagnostic::new(Warning, "first").with_label(
      metric_label(first, 0, 1, true),
    ),
    Diagnostic::new(Error, "second").with_label(
      metric_label(second, 0, 1, true),
    ),
    Diagnostic::new(Advice, "again").with_label(metric_label(first, 2, 3, true)),
  ])
  let metrics = bag.metrics()
  let sources = metrics.source_counts()
  assert_eq(sources.length(), 2)
  assert_eq(sources[0].source().value(), first.value())
  assert_eq(sources[0].diagnostics(), 2)
  assert_eq(sources[0].labels(), 2)
  assert_eq(sources[1].source().value(), second.value())
  assert_eq(metrics.summary().advice(), 1)
  assert_eq(metrics.summary().warnings(), 1)
  assert_eq(metrics.summary().errors(), 1)
}

///|
test "returned metric arrays do not expose internal storage" {
  let source = SourceId::new(0).unwrap()
  let bag = DiagnosticBag::from_array([
    Diagnostic::new(Error, "coded")
    .with_code("E1")
    .with_label(metric_label(source, 0, 1, true)),
  ])
  let metrics = bag.metrics()
  let codes = metrics.code_counts()
  codes.clear()
  let sources = metrics.source_counts()
  sources.clear()
  assert_eq(metrics.code_counts().length(), 1)
  assert_eq(metrics.source_counts().length(), 1)
}
