///|
test "source indexes LF and CRLF lines" {
  let source = Source::new("demo", "one\r\ntwo\nthree")
  assert_eq(source.line_count(), 3)
  assert_eq(source.line_text(0).unwrap(), "one")
  assert_eq(source.line_text(1).unwrap(), "two")
  assert_eq(source.line_text(2).unwrap(), "three")
}

///|
test "source location clamps offsets" {
  let source = Source::new("demo", "ab\ncd")
  let before = source.location(-3)
  assert_eq(before.line(), 0)
  assert_eq(before.column(), 0)
  assert_eq(before.offset(), 0)
  let middle = source.location(4)
  assert_eq(middle.line(), 1)
  assert_eq(middle.column(), 1)
  assert_eq(middle.offset(), 4)
  let after = source.location(99)
  assert_eq(after.line(), 1)
  assert_eq(after.column(), 2)
  assert_eq(after.offset(), 5)
}

///|
test "empty source has one addressable line" {
  let source = Source::new("empty", "")
  assert_eq(source.line_count(), 1)
  assert_eq(source.line_text(0).unwrap(), "")
  assert_true(source.line_text(1) is None)
}

///|
test "source offsets are UTF-8 bytes" {
  let source = Source::new("unicode", "a界b")
  assert_eq(source.byte_length(), 5)
  let location = source.location(4)
  assert_eq(location.line(), 0)
  assert_eq(location.column(), 4)
  assert_eq(location.offset(), 4)
}
