///|
test "renderer shows aligned source and primary label" {
  let sources = SourceMap::new()
  let id = sources.add("app.conf", "name = demo\nport = 0")
  let diagnostic = Diagnostic::new(Error, "port must be positive")
    .with_code("CFG001")
    .with_label(Label::primary(id, Span::new(19, 20).unwrap(), "invalid port"))
    .with_help("choose a value from 1 to 65535")
  let expected =
    #|error[CFG001]: port must be positive
    #|  --> app.conf:2:8
    #|  |
    #|2 | port = 0
    #|  |        ^ invalid port
    #|  = help: choose a value from 1 to 65535
    #|
  inspect(
    render(sources, diagnostic, config=RenderConfig::new(context_lines=0)),
    content=expected,
  )
}

///|
test "renderer aligns CJK labels after tabs" {
  let sources = SourceMap::new()
  let id = sources.add("中文.mbt", "\tlet 月 = 0")
  let diagnostic = Diagnostic::new(Warning, "unused binding").with_label(
    Label::primary(id, Span::new(5, 8).unwrap(), "月"),
  )
  let expected =
    #|warning: unused binding
    #|  --> 中文.mbt:1:6
    #|  |
    #|1 |     let 月 = 0
    #|  |         ^^ 月
    #|
  inspect(
    render(
      sources,
      diagnostic,
      config=RenderConfig::new(context_lines=0, tab_width=4),
    ),
    content=expected,
  )
}

///|
test "renderer groups labels from multiple sources" {
  let sources = SourceMap::new()
  let first = sources.add("first.mbt", "let value = 1")
  let second = sources.add("second.mbt", "use value")
  let diagnostic = Diagnostic::new(Error, "duplicate definition")
    .with_label(Label::primary(first, Span::new(4, 9).unwrap(), "defined here"))
    .with_label(Label::secondary(second, Span::new(4, 9).unwrap(), "used here"))
    .with_note("names must be unique")
  let text = render(
    sources,
    diagnostic,
    config=RenderConfig::new(context_lines=0),
  )
  assert_true(text.contains("first.mbt"))
  assert_true(text.contains("second.mbt"))
  assert_true(text.contains("^"))
  assert_true(text.contains("-"))
  assert_true(text.contains("= note: names must be unique"))
}

///|
test "empty spans render a single caret" {
  let sources = SourceMap::new()
  let id = sources.add("empty.mbt", "let x = ")
  let diagnostic = Diagnostic::new(Error, "expected expression").with_label(
    Label::primary(id, Span::at(8).unwrap(), "insert here"),
  )
  let text = render(
    sources,
    diagnostic,
    config=RenderConfig::new(context_lines=0),
  )
  assert_true(text.contains("^ insert here"))
}
