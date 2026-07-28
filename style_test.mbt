///|
fn styled_fixture() -> (SourceMap, Diagnostic) {
  let sources = SourceMap::new()
  let id = sources.add("theme.mbt", "let answer = 0")
  let diagnostic = Diagnostic::new(Error, "invalid answer")
    .with_code("E42")
    .with_label(Label::primary(id, Span::new(13, 14).unwrap(), "must be 42"))
    .with_note("the answer is checked at startup")
    .with_help("replace 0 with 42")
  (sources, diagnostic)
}

///|
test "disabled ANSI output equals the plain renderer" {
  let (sources, diagnostic) = styled_fixture()
  assert_eq(
    render_ansi(sources, diagnostic, enabled=false),
    render(sources, diagnostic),
  )
}

///|
test "styled output contains ANSI reset and preserves plain text" {
  let (sources, diagnostic) = styled_fixture()
  let styled = render_ansi(sources, diagnostic)
  assert_true(styled.contains("\u{001b}["))
  assert_true(styled.contains("\u{001b}[0m"))
  assert_eq(strip_ansi(styled), render(sources, diagnostic))
}

///|
test "themes expose severity-specific colors" {
  assert_true(Theme::dark().severity(Error) == BrightRed)
  assert_true(Theme::dark().severity(Warning) == BrightYellow)
  assert_true(Theme::light().severity(Advice) == Blue)
}

///|
test "ANSI stripper leaves ordinary Unicode unchanged" {
  assert_eq(strip_ansi("普通文本 😀"), "普通文本 😀")
  assert_eq(strip_ansi("\u{001b}[31m红色\u{001b}[0m"), "红色")
}
