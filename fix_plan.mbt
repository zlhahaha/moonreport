///|
/// Selects which fixes participate in a batch operation.
pub(all) enum FixMode {
  /// Include every fix, including suggestions that need review.
  AllFixes
  /// Include only fixes explicitly marked machine-applicable.
  AutomaticFixes
} derive(Eq, Debug)

///|
pub fn FixMode::name(self : FixMode) -> String {
  match self {
    AllFixes => "all"
    AutomaticFixes => "automatic"
  }
}

///|
/// The result of validating a selected batch of fixes.
pub(all) enum FixPlanValidation {
  PlanValid
  EmptyPlan
  NoSelectedFixes
  InvalidPlannedFix(Int, FixValidation)
  ConflictingPlannedFixes(FixValidation)
} derive(Eq, Debug)

///|
pub fn FixPlanValidation::is_valid(self : FixPlanValidation) -> Bool {
  self == PlanValid
}

///|
pub fn FixPlanValidation::message(self : FixPlanValidation) -> String {
  match self {
    PlanValid => "valid"
    EmptyPlan => "fix plan contains no fixes"
    NoSelectedFixes => "fix plan contains no fixes selected by this mode"
    InvalidPlannedFix(index, validation) =>
      "fix " + index.to_string() + " is invalid: " + validation.message()
    ConflictingPlannedFixes(validation) =>
      "selected fixes conflict: " + validation.message()
  }
}

///|
/// Counts describing a plan before it is applied.
pub struct FixPlanSummary {
  total_fixes : Int
  selected_fixes : Int
  skipped_fixes : Int
  selected_edits : Int
}

///|
pub fn FixPlanSummary::total_fixes(self : FixPlanSummary) -> Int {
  self.total_fixes
}

///|
pub fn FixPlanSummary::selected_fixes(self : FixPlanSummary) -> Int {
  self.selected_fixes
}

///|
pub fn FixPlanSummary::skipped_fixes(self : FixPlanSummary) -> Int {
  self.skipped_fixes
}

///|
pub fn FixPlanSummary::selected_edits(self : FixPlanSummary) -> Int {
  self.selected_edits
}

///|
/// An ordered collection of independent fixes.
///
/// A plan validates the complete edit set before changing any source. This
/// makes unattended formatter, linter, migration, and code-action workflows
/// atomic: either every selected edit is safe to apply, or nothing changes.
pub struct FixPlan {
  fixes : Array[Fix]
}

///|
pub fn FixPlan::new() -> FixPlan {
  { fixes: [] }
}

///|
pub fn FixPlan::with_fix(self : FixPlan, fix : Fix) -> FixPlan {
  { fixes: self.fixes + [fix] }
}

///|
pub fn FixPlan::length(self : FixPlan) -> Int {
  self.fixes.length()
}

///|
pub fn FixPlan::is_empty(self : FixPlan) -> Bool {
  self.fixes.is_empty()
}

///|
pub fn FixPlan::fixes(self : FixPlan) -> Array[Fix] {
  self.fixes.copy()
}

///|
fn FixPlan::selected(self : FixPlan, mode : FixMode) -> Array[Fix] {
  match mode {
    AllFixes => self.fixes.copy()
    AutomaticFixes => self.fixes.filter(fn(fix) { fix.is_automatic() })
  }
}

///|
pub fn FixPlan::summary(
  self : FixPlan,
  mode? : FixMode = AutomaticFixes,
) -> FixPlanSummary {
  let selected = self.selected(mode)
  let mut selected_edits = 0
  for fix in selected {
    selected_edits = selected_edits + fix.edits().length()
  }
  {
    total_fixes: self.fixes.length(),
    selected_fixes: selected.length(),
    skipped_fixes: self.fixes.length() - selected.length(),
    selected_edits,
  }
}

///|
fn FixPlan::combined(
  self : FixPlan,
  sources : SourceMap,
  mode : FixMode,
) -> (Fix?, FixPlanValidation) {
  if self.fixes.is_empty() {
    return (None, EmptyPlan)
  }
  let selected = self.selected(mode)
  if selected.is_empty() {
    return (None, NoSelectedFixes)
  }
  let mut combined = Fix::new(
    "apply " + mode.name() + " fixes",
    applicability=MachineApplicable,
  )
  for index, fix in selected {
    let validation = fix.validate(sources)
    if !validation.is_valid() {
      return (None, InvalidPlannedFix(index, validation))
    }
    for edit in fix.edits() {
      combined = combined.with_edit(edit)
    }
  }
  let validation = combined.validate(sources)
  if !validation.is_valid() {
    return (None, ConflictingPlannedFixes(validation))
  }
  (Some(combined), PlanValid)
}

///|
/// Validates every selected fix and then detects conflicts across fixes.
pub fn FixPlan::validate(
  self : FixPlan,
  sources : SourceMap,
  mode? : FixMode = AutomaticFixes,
) -> FixPlanValidation {
  self.combined(sources, mode).1
}

///|
/// Applies the selected fixes atomically to a copy of the source map.
///
/// The default is deliberately conservative: only machine-applicable fixes
/// are selected. Pass `AllFixes` when a user has reviewed every suggestion.
pub fn FixPlan::apply(
  self : FixPlan,
  sources : SourceMap,
  mode? : FixMode = AutomaticFixes,
) -> (SourceMap?, FixPlanValidation) {
  let (combined, validation) = self.combined(sources, mode)
  match combined {
    None => (None, validation)
    Some(fix) => {
      let (result, fix_validation) = fix.apply(sources)
      if fix_validation.is_valid() {
        (result, PlanValid)
      } else {
        (None, ConflictingPlannedFixes(fix_validation))
      }
    }
  }
}
