///|
test "ASCII and tabs use terminal tab stops" {
  inspect(display_width("ab\tc"), content="5")
  inspect(expand_tabs("ab\tc"), content="ab  c")
  inspect(display_column("ab\tc", 3), content="4")
}

///|
test "CJK and emoji occupy two display cells" {
  inspect(display_width("Moon月"), content="6")
  inspect(display_width("ok😀"), content="4")
  inspect(display_column("a月b", 4), content="3")
}

///|
test "combining marks do not advance the column" {
  inspect(display_width("e\u{0301}"), content="1")
}

///|
test "display configuration clamps invalid widths" {
  let config = DisplayConfig::new(0, 9)
  inspect(config.tab_width(), content="1")
  inspect(display_width("\tx", config~), content="2")
}
