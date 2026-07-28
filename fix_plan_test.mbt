///|
fn plan_fixture() -> (SourceMap, SourceId, SourceId) {
  let sources = SourceMap::new()
  let config = sources.add(
    "app.conf",
    (
      #|port = 0
      #|host = old
      #|
    ),
  )
  let readme = sources.add("README.md", "# Service\n")
  (sources, config, readme)
}

///|
fn automatic_replace(
  title : String,
  source : SourceId,
  start : Int,
  end : Int,
  replacement : String,
) -> Fix {
  Fix::new(title, applicability=MachineApplicable).with_edit(
    TextEdit::replace(source, Span::new(start, end).unwrap(), replacement),
  )
}

///|
test "empty plan reports a specific validation result" {
  let (sources, _, _) = plan_fixture()
  let plan = FixPlan::new()
  assert_true(plan.validate(sources) == EmptyPlan)
  assert_eq(plan.length(), 0)
  assert_true(plan.is_empty())
}

///|
test "automatic mode reports no selected suggestions" {
  let (sources, config, _) = plan_fixture()
  let suggestion = Fix::new("consider a port").with_edit(
    TextEdit::replace(config, Span::new(7, 8).unwrap(), "8080"),
  )
  let validation = FixPlan::new()
    .with_fix(suggestion)
    .validate(sources, mode=AutomaticFixes)
  assert_true(validation == NoSelectedFixes)
}

///|
test "all mode includes reviewed suggestions" {
  let (sources, config, _) = plan_fixture()
  let suggestion = Fix::new("consider a port").with_edit(
    TextEdit::replace(config, Span::new(7, 8).unwrap(), "8080"),
  )
  let plan = FixPlan::new().with_fix(suggestion)
  assert_true(plan.validate(sources, mode=AllFixes) == PlanValid)
}

///|
test "default apply selects only machine applicable fixes" {
  let (sources, config, _) = plan_fixture()
  let automatic = automatic_replace("repair port", config, 7, 8, "8080")
  let suggestion = Fix::new("rename host").with_edit(
    TextEdit::replace(config, Span::new(16, 19).unwrap(), "new"),
  )
  let plan = FixPlan::new().with_fix(automatic).with_fix(suggestion)
  let (updated, validation) = plan.apply(sources)
  assert_true(validation == PlanValid)
  assert_eq(
    updated.unwrap().get(config).unwrap().text(),
    (
      #|port = 8080
      #|host = old
      #|
    ),
  )
}

///|
test "all mode applies suggestions after review" {
  let (sources, config, _) = plan_fixture()
  let automatic = automatic_replace("repair port", config, 7, 8, "8080")
  let suggestion = Fix::new("rename host").with_edit(
    TextEdit::replace(config, Span::new(16, 19).unwrap(), "new"),
  )
  let plan = FixPlan::new().with_fix(automatic).with_fix(suggestion)
  let (updated, validation) = plan.apply(sources, mode=AllFixes)
  assert_true(validation == PlanValid)
  assert_eq(
    updated.unwrap().get(config).unwrap().text(),
    (
      #|port = 8080
      #|host = new
      #|
    ),
  )
}

///|
test "plan applies edits across multiple sources" {
  let (sources, config, readme) = plan_fixture()
  let plan = FixPlan::new()
    .with_fix(automatic_replace("repair port", config, 7, 8, "80"))
    .with_fix(
      Fix::new("document status", applicability=MachineApplicable).with_edit(
        TextEdit::insert(readme, 10, "Ready\n").unwrap(),
      ),
    )
  let (updated, validation) = plan.apply(sources)
  let result = updated.unwrap()
  assert_true(validation == PlanValid)
  assert_true(result.get(config).unwrap().text().contains("port = 80"))
  assert_true(result.get(readme).unwrap().text().contains("Ready"))
}

///|
test "plan rejects overlaps between otherwise valid fixes" {
  let (sources, config, _) = plan_fixture()
  let left = automatic_replace("replace assignment", config, 0, 8, "port = 80")
  let right = automatic_replace("replace value", config, 7, 8, "443")
  let plan = FixPlan::new().with_fix(left).with_fix(right)
  let validation = plan.validate(sources)
  match validation {
    ConflictingPlannedFixes(Overlapping(id, first, second)) => {
      assert_eq(id.value(), config.value())
      assert_eq(first.start(), 0)
      assert_eq(first.end(), 8)
      assert_eq(second.start(), 7)
      assert_eq(second.end(), 8)
    }
    _ => fail("expected a cross-fix overlap")
  }
}

///|
test "conflicting plan never returns partially updated sources" {
  let (sources, config, _) = plan_fixture()
  let plan = FixPlan::new()
    .with_fix(automatic_replace("wide", config, 0, 8, "port = 80"))
    .with_fix(automatic_replace("narrow", config, 7, 8, "9"))
  let (updated, validation) = plan.apply(sources)
  assert_true(updated is None)
  assert_false(validation.is_valid())
  assert_eq(
    sources.get(config).unwrap().text(),
    (
      #|port = 0
      #|host = old
      #|
    ),
  )
}

///|
test "plan identifies the selected invalid fix" {
  let (sources, config, _) = plan_fixture()
  let valid = automatic_replace("valid", config, 7, 8, "80")
  let invalid = automatic_replace("invalid", config, 100, 101, "x")
  let validation = FixPlan::new()
    .with_fix(valid)
    .with_fix(invalid)
    .validate(sources)
  match validation {
    InvalidPlannedFix(1, OutOfBounds(id, span, length)) => {
      assert_eq(id.value(), config.value())
      assert_eq(span.start(), 100)
      assert_eq(span.end(), 101)
      assert_eq(length, 20)
    }
    _ => fail("expected the second fix to be invalid")
  }
}

///|
test "unselected invalid suggestion does not block automatic mode" {
  let (sources, config, _) = plan_fixture()
  let automatic = automatic_replace("valid", config, 7, 8, "80")
  let invalid_suggestion = Fix::new("invalid suggestion").with_edit(
    TextEdit::replace(config, Span::new(100, 101).unwrap(), "x"),
  )
  let plan = FixPlan::new().with_fix(automatic).with_fix(invalid_suggestion)
  assert_true(plan.validate(sources) == PlanValid)
  assert_true(plan.validate(sources, mode=AllFixes) != PlanValid)
}

///|
test "summary distinguishes selected and skipped fixes" {
  let (_, config, _) = plan_fixture()
  let automatic = automatic_replace("automatic", config, 7, 8, "80")
  let suggestion = Fix::new("suggestion")
    .with_edit(TextEdit::insert(config, 0, "# generated\n").unwrap())
    .with_edit(TextEdit::insert(config, 20, "# end\n").unwrap())
  let plan = FixPlan::new().with_fix(automatic).with_fix(suggestion)
  let automatic_summary = plan.summary()
  assert_eq(automatic_summary.total_fixes(), 2)
  assert_eq(automatic_summary.selected_fixes(), 1)
  assert_eq(automatic_summary.skipped_fixes(), 1)
  assert_eq(automatic_summary.selected_edits(), 1)
  let all_summary = plan.summary(mode=AllFixes)
  assert_eq(all_summary.selected_fixes(), 2)
  assert_eq(all_summary.skipped_fixes(), 0)
  assert_eq(all_summary.selected_edits(), 3)
}

///|
test "plan returns a defensive copy of fixes" {
  let (_, config, _) = plan_fixture()
  let plan = FixPlan::new().with_fix(
    automatic_replace("repair", config, 7, 8, "80"),
  )
  let copy = plan.fixes()
  copy.push(Fix::new("external"))
  assert_eq(plan.length(), 1)
  assert_eq(copy.length(), 2)
}

///|
test "validation messages are useful in command line tools" {
  let valid : FixPlanValidation = PlanValid
  let empty : FixPlanValidation = EmptyPlan
  let no_selection : FixPlanValidation = NoSelectedFixes
  let invalid : FixPlanValidation = InvalidPlannedFix(2, Empty)
  let conflict : FixPlanValidation = ConflictingPlannedFixes(
    Overlapping(
      SourceId::new(0).unwrap(),
      Span::new(0, 2).unwrap(),
      Span::new(1, 3).unwrap(),
    ),
  )
  assert_eq(valid.message(), "valid")
  assert_true(empty.message().contains("no fixes"))
  assert_true(no_selection.message().contains("selected"))
  assert_true(invalid.message().contains("fix 2"))
  assert_true(conflict.message().contains("conflict"))
}
