///|
test "source window includes bounded context" {
  let source = Source::new("demo", "zero\none\ntwo\nthree\nfour")
  let span = Span::new(9, 12).unwrap()
  let window = source.window(span, context_lines=1)
  inspect(window.first(), content="1")
  inspect(window.last(), content="3")
  inspect(window.focus_first(), content="2")
  inspect(window.focus_last(), content="2")
}

///|
test "multi-line span focuses every touched line" {
  let source = Source::new("demo", "aa\nbb\ncc")
  let window = source.window(Span::new(1, 5).unwrap(), context_lines=0)
  inspect(window.focus_first(), content="0")
  inspect(window.focus_last(), content="1")
}

///|
test "nearby windows merge but distant windows remain separate" {
  let source = Source::new("demo", "0\n1\n2\n3\n4\n5\n6")
  let a = source.window(Span::new(0, 1).unwrap(), context_lines=0)
  let b = source.window(Span::new(4, 5).unwrap(), context_lines=0)
  let c = source.window(Span::new(12, 13).unwrap(), context_lines=0)
  let merged = merge_windows([c, b, a], gap=1)
  inspect(merged.length(), content="2")
  inspect(merged[0].first(), content="0")
  inspect(merged[0].last(), content="2")
}
