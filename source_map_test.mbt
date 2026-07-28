///|
test "source map assigns stable insertion IDs" {
  let sources = SourceMap::new()
  let first = sources.add("first.mbt", "let a = 1")
  let second = sources.add("second.mbt", "let b = 2")
  assert_eq(first.value(), 0)
  assert_eq(second.value(), 1)
  assert_eq(sources.length(), 2)
  assert_eq(sources.get(first).unwrap().name(), "first.mbt")
  assert_eq(sources.find_by_name("second.mbt").unwrap().value(), 1)
  assert_true(sources.find_by_name("missing.mbt") is None)
}

///|
test "source map validates every diagnostic label" {
  let sources = SourceMap::new()
  let source = sources.add("config.toml", "port = 0")
  let valid = Diagnostic::new(Severity::Error, "invalid port").with_label(
    Label::primary(source, Span::new(7, 8).unwrap(), "must be positive"),
  )
  assert_true(sources.validate(valid))
  let invalid = Diagnostic::new(Severity::Error, "invalid range").with_label(
    Label::primary(source, Span::new(7, 99).unwrap(), "past end"),
  )
  assert_false(sources.validate(invalid))
}

///|
test "empty source map rejects unknown IDs" {
  let sources = SourceMap::new()
  assert_true(sources.is_empty())
  let unknown = SourceId::new(0).unwrap()
  assert_false(sources.contains(unknown))
  assert_true(sources.get(unknown) is None)
}
