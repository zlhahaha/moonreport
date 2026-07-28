///|
fn json_fixture() -> (SourceMap, Diagnostic) {
  let sources = SourceMap::new()
  let id = sources.add("配置.json", "name = \"demo\"\n")
  let diagnostic = Diagnostic::new(Error, "expected JSON: \"quoted\"")
    .with_code("JSON001")
    .with_label(Label::primary(id, Span::new(7, 13).unwrap(), "remove quotes"))
    .with_note("line one\nline two")
    .with_help("use a JSON string")
  (sources, diagnostic)
}

///|
test "JSON output includes source coordinates and escaped content" {
  let (sources, diagnostic) = json_fixture()
  let json = render_json(sources, diagnostic)
  assert_true(json.has_prefix("{\"severity\":\"error\""))
  assert_true(json.contains("\"source_name\":\"配置.json\""))
  assert_true(json.contains("\"message\":\"expected JSON: \\\"quoted\\\"\""))
  assert_true(json.contains("\"start_line\":1"))
  assert_true(json.contains("\"start_column\":8"))
  assert_true(json.contains("\"notes\":[\"line one\\nline two\"]"))
}

///|
test "JSON output uses null for absent optional fields" {
  let sources = SourceMap::new()
  let id = sources.add("input.txt", "x")
  let diagnostic = Diagnostic::new(Advice, "consider this").with_label(
    Label::primary(id, Span::new(0, 1).unwrap(), "x"),
  )
  let json = render_json(sources, diagnostic)
  assert_true(json.contains("\"code\":null"))
  assert_true(json.contains("\"help\":null"))
  assert_true(json.contains("\"notes\":[]"))
}

///|
test "JSON lines separates reports without trailing newline" {
  let (sources, diagnostic) = json_fixture()
  let output = render_json_lines(sources, [diagnostic, diagnostic])
  assert_eq(output.split("\n").length(), 2)
  assert_false(output.has_suffix("\n"))
}

///|
test "JSON escapes every ASCII control character" {
  let sources = SourceMap::new()
  let id = sources.add("control.txt", "x")
  let diagnostic = Diagnostic::new(Warning, "a\u{0000}b\u{0008}c\u{000c}d\t").with_label(
    Label::primary(id, Span::new(0, 1).unwrap(), "\\"),
  )
  let json = render_json(sources, diagnostic)
  assert_true(json.contains("a\\u0000b\\bc\\fd\\t"))
  assert_true(json.contains("\"message\":\"\\\\\""))
}
