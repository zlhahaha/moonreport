///|
test "span rejects invalid bounds" {
  assert_true(Span::new(-1, 2) is None)
  assert_true(Span::new(3, 2) is None)
  let span = Span::new(2, 3).unwrap()
  assert_eq(span.start(), 2)
  assert_eq(span.end(), 3)
}

///|
test "span operations use half-open ranges" {
  let left = Span::new(1, 4).unwrap()
  let right = Span::new(4, 7).unwrap()
  assert_true(left.contains(1))
  assert_false(left.contains(4))
  assert_false(left.intersects(right))
  assert_true(left.touches(right))
  let covered = left.cover(right)
  assert_eq(covered.start(), 1)
  assert_eq(covered.end(), 7)
}

///|
test "span clamping preserves ordering" {
  let span = Span::new(8, 20).unwrap()
  let inside = span.clamp(10)
  assert_eq(inside.start(), 8)
  assert_eq(inside.end(), 10)
  let outside = span.clamp(4)
  assert_eq(outside.start(), 4)
  assert_eq(outside.end(), 4)
}
