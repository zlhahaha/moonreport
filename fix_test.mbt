///|
fn fix_fixture() -> (SourceMap, SourceId) {
  let sources = SourceMap::new()
  let id = sources.add("settings.toml", "port = 0\nhost = \"old\"\n")
  (sources, id)
}

///|
test "text edits identify insertion deletion and replacement" {
  let (_, id) = fix_fixture()
  let insertion = TextEdit::insert(id, 0, "# generated\n").unwrap()
  let deletion = TextEdit::delete(id, Span::new(7, 8).unwrap())
  let replacement = TextEdit::replace(id, Span::new(7, 8).unwrap(), "8080")
  assert_true(insertion.is_insertion())
  assert_true(deletion.is_deletion())
  assert_false(replacement.is_insertion())
  assert_false(replacement.is_deletion())
}

///|
test "fix applies unordered non-overlapping edits atomically" {
  let (sources, id) = fix_fixture()
  let fix = Fix::new("repair configuration", applicability=MachineApplicable)
    .with_edit(
      TextEdit::replace(id, Span::new(16, 21).unwrap(), "\"localhost\""),
    )
    .with_edit(TextEdit::replace(id, Span::new(7, 8).unwrap(), "8080"))
    .with_edit(TextEdit::insert(id, 0, "# generated\n").unwrap())
  let (updated, validation) = fix.apply(sources)
  assert_true(validation == FixValidation::Valid)
  assert_eq(
    updated.unwrap().get(id).unwrap().text(),
    "# generated\nport = 8080\nhost = \"localhost\"\n",
  )
}

///|
test "fix preserves untouched sources and stable identifiers" {
  let (sources, id) = fix_fixture()
  let other = sources.add("README", "unchanged")
  let fix = Fix::new("repair port").with_edit(
    TextEdit::replace(id, Span::new(7, 8).unwrap(), "443"),
  )
  let (updated, _) = fix.apply(sources)
  let updated = updated.unwrap()
  assert_eq(updated.get(id).unwrap().text(), "port = 443\nhost = \"old\"\n")
  assert_eq(updated.get(other).unwrap().text(), "unchanged")
  assert_eq(updated.get(other).unwrap().name(), "README")
}

///|
test "overlapping edits are rejected without partial output" {
  let (sources, id) = fix_fixture()
  let fix = Fix::new("ambiguous repair")
    .with_edit(TextEdit::delete(id, Span::new(0, 8).unwrap()))
    .with_edit(TextEdit::replace(id, Span::new(7, 9).unwrap(), "1"))
  let (updated, validation) = fix.apply(sources)
  assert_true(updated is None)
  match validation {
    Overlapping(source, left, right) => {
      assert_true(source == id)
      assert_true(left == Span::new(0, 8).unwrap())
      assert_true(right == Span::new(7, 9).unwrap())
    }
    _ => fail("expected overlapping validation result")
  }
}

///|
test "adjacent and same-offset insertions are deterministic" {
  let (sources, id) = fix_fixture()
  let fix = Fix::new("decorate")
    .with_edit(TextEdit::insert(id, 0, "A").unwrap())
    .with_edit(TextEdit::insert(id, 0, "B").unwrap())
    .with_edit(TextEdit::insert(id, 9, "!").unwrap())
  let (text, validation) = fix.apply_to_source(sources, id)
  assert_true(validation == Valid)
  assert_eq(text.unwrap(), "ABport = 0\n!host = \"old\"\n")
}

///|
test "out-of-bounds and unknown sources report useful details" {
  let (sources, id) = fix_fixture()
  let too_long = Fix::new("bad").with_edit(
    TextEdit::delete(id, Span::new(0, 100).unwrap()),
  )
  let unknown = SourceId::new(99).unwrap()
  let absent = Fix::new("absent").with_edit(
    TextEdit::insert(unknown, 0, "x").unwrap(),
  )
  match too_long.validate(sources) {
    OutOfBounds(_, _, _) => ()
    _ => fail("expected out-of-bounds validation result")
  }
  match absent.validate(sources) {
    UnknownSource(_) => ()
    _ => fail("expected unknown-source validation result")
  }
  assert_true(too_long.validate(sources).message().contains("exceeds"))
  assert_true(absent.validate(sources).message().contains("99"))
}

///|
test "UTF-8 replacements use byte offsets" {
  let sources = SourceMap::new()
  let id = sources.add("unicode", "name = \"月亮\"\n")
  let fix = Fix::new("translate").with_edit(
    TextEdit::replace(id, Span::new(8, 14).unwrap(), "moon"),
  )
  let (text, validation) = fix.apply_to_source(sources, id)
  assert_true(validation == Valid)
  assert_eq(text.unwrap(), "name = \"moon\"\n")
}

///|
test "applicability exposes automation intent" {
  assert_true(Applicability::MachineApplicable.is_automatic())
  assert_false(Applicability::MaybeIncorrect.is_automatic())
  assert_eq(Applicability::HasPlaceholders.name(), "has-placeholders")
  let fix = Fix::new("safe", applicability=MachineApplicable)
  assert_true(fix.is_automatic())
  assert_eq(fix.title(), "safe")
}
