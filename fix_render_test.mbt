///|
fn preview_fixture() -> (SourceMap, SourceId, SourceId) {
  let sources = SourceMap::new()
  let config = sources.add("app.conf", "port = 0\nhost = old\n")
  let readme = sources.add("README.md", "# Service\n")
  (sources, config, readme)
}

///|
test "preview enriches edits with source names and locations" {
  let (sources, config, _) = preview_fixture()
  let fix = Fix::new("repair port", applicability=MachineApplicable).with_edit(
    TextEdit::replace(config, Span::new(7, 8).unwrap(), "8080"),
  )
  let (preview, validation) = fix.preview(sources)
  assert_true(validation == Valid)
  let preview = preview.unwrap()
  assert_eq(preview.title(), "repair port")
  assert_true(preview.applicability() == MachineApplicable)
  assert_eq(preview.edit_count(), 1)
  assert_eq(preview.source_count(), 1)
  let edit = preview.edits()[0]
  assert_eq(edit.source_name(), "app.conf")
  assert_eq(edit.start().line(), 0)
  assert_eq(edit.start().column(), 7)
  assert_eq(edit.end().column(), 8)
  assert_eq(edit.original(), "0")
  assert_eq(edit.replacement(), "8080")
}

///|
test "preview orders sources and byte offsets deterministically" {
  let (sources, config, readme) = preview_fixture()
  let fix = Fix::new("batch")
    .with_edit(TextEdit::insert(readme, 10, "Ready\n").unwrap())
    .with_edit(TextEdit::insert(config, 0, "# generated\n").unwrap())
    .with_edit(TextEdit::replace(config, Span::new(7, 8).unwrap(), "443"))
  let preview = fix.preview(sources).0.unwrap()
  let edits = preview.edits()
  assert_eq(edits.length(), 3)
  assert_true(edits[0].source() == config)
  assert_eq(edits[0].span().start(), 0)
  assert_eq(edits[1].span().start(), 7)
  assert_true(edits[2].source() == readme)
  assert_eq(preview.source_count(), 2)
}

///|
test "text preview displays replacement with human locations" {
  let (sources, config, _) = preview_fixture()
  let fix = Fix::new("repair port", applicability=MachineApplicable).with_edit(
    TextEdit::replace(config, Span::new(7, 8).unwrap(), "8080"),
  )
  let output = fix.render_preview(sources).0.unwrap()
  inspect(
    output,
    content=(
      #|fix: repair port [machine-applicable]
      #|--- app.conf
      #|+++ app.conf (fixed)
      #|@@ -1:8 +1:8 @@
      #|-0
      #|+8080
      #|
    ),
  )
}

///|
test "text preview groups multiple edits under one file header" {
  let (sources, config, _) = preview_fixture()
  let fix = Fix::new("normalize")
    .with_edit(TextEdit::insert(config, 0, "# generated\n").unwrap())
    .with_edit(TextEdit::delete(config, Span::new(16, 19).unwrap()))
  let output = fix.render_preview(sources).0.unwrap()
  assert_eq(output.split("--- app.conf").length(), 2)
  assert_eq(output.split("+++ app.conf").length(), 2)
  // Each of the two hunk headers contains an opening and closing marker.
  assert_eq(output.split("@@").length(), 5)
  assert_true(output.contains("+# generated"))
  assert_true(output.contains("-old"))
}

///|
test "text preview uses separate headers for separate files" {
  let (sources, config, readme) = preview_fixture()
  let fix = Fix::new("document")
    .with_edit(TextEdit::insert(config, 0, "# config\n").unwrap())
    .with_edit(TextEdit::insert(readme, 10, "Ready\n").unwrap())
  let output = fix.render_preview(sources).0.unwrap()
  assert_true(output.contains("--- app.conf"))
  assert_true(output.contains("--- README.md"))
  assert_true(output.contains("+Ready"))
}

///|
test "multiline replacement emits each preview line" {
  let (sources, config, _) = preview_fixture()
  let fix = Fix::new("expand").with_edit(
    TextEdit::replace(
      config,
      Span::new(0, 8).unwrap(),
      "port = 8080\nsecure = true",
    ),
  )
  let output = fix.render_preview(sources).0.unwrap()
  assert_true(output.contains("-port = 0"))
  assert_true(output.contains("+port = 8080"))
  assert_true(output.contains("+secure = true"))
}

///|
test "insertions and deletions are classified in previews" {
  let (sources, config, _) = preview_fixture()
  let fix = Fix::new("change")
    .with_edit(TextEdit::insert(config, 0, "#").unwrap())
    .with_edit(TextEdit::delete(config, Span::new(16, 19).unwrap()))
  let edits = fix.preview(sources).0.unwrap().edits()
  assert_true(edits[0].is_insertion())
  assert_false(edits[0].is_deletion())
  assert_true(edits[1].is_deletion())
  assert_false(edits[1].is_insertion())
}

///|
test "JSON preview includes stable offsets and one-based positions" {
  let (sources, config, _) = preview_fixture()
  let fix = Fix::new("repair \"port\"", applicability=MaybeIncorrect).with_edit(
    TextEdit::replace(config, Span::new(7, 8).unwrap(), "8080"),
  )
  let output = fix.render_json(sources).0.unwrap()
  inspect(
    output,
    content=(
      #|{"title":"repair \"port\"","applicability":"maybe-incorrect","source_count":1,"edits":[{"source_id":0,"source_name":"app.conf","start":{"line":1,"column":8,"offset":7},"end":{"line":1,"column":9,"offset":8},"original":"0","replacement":"8080"}]}
    ),
  )
}

///|
test "JSON preview escapes control characters and Unicode stays readable" {
  let sources = SourceMap::new()
  let id = sources.add("月.conf", "a\tb\n")
  let fix = Fix::new("replace").with_edit(
    TextEdit::replace(id, Span::new(1, 2).unwrap(), "\"\n"),
  )
  let output = fix.render_json(sources).0.unwrap()
  assert_true(output.contains("\"source_name\":\"月.conf\""))
  assert_true(output.contains("\"original\":\"\\t\""))
  assert_true(output.contains("\"replacement\":\"\\\"\\n\""))
}

///|
test "invalid fixes do not produce previews or JSON" {
  let (sources, config, _) = preview_fixture()
  let fix = Fix::new("invalid").with_edit(
    TextEdit::replace(config, Span::new(0, 99).unwrap(), "x"),
  )
  let (preview, preview_validation) = fix.preview(sources)
  let (json, json_validation) = fix.render_json(sources)
  let (text, text_validation) = fix.render_preview(sources)
  assert_true(preview is None)
  assert_true(json is None)
  assert_true(text is None)
  assert_true(preview_validation == json_validation)
  assert_true(json_validation == text_validation)
}

///|
test "empty fixes are rejected consistently" {
  let (sources, _, _) = preview_fixture()
  let fix = Fix::new("empty")
  assert_true(fix.preview(sources).1 == Empty)
  assert_true(fix.render_json(sources).1 == Empty)
  assert_true(fix.render_preview(sources).1 == Empty)
}

///|
test "preview source count ignores repeated edits" {
  let (sources, config, readme) = preview_fixture()
  let fix = Fix::new("many")
    .with_edit(TextEdit::insert(config, 0, "a").unwrap())
    .with_edit(TextEdit::insert(config, 1, "b").unwrap())
    .with_edit(TextEdit::insert(readme, 0, "c").unwrap())
  let preview = fix.preview(sources).0.unwrap()
  assert_eq(preview.edit_count(), 3)
  assert_eq(preview.source_count(), 2)
}
