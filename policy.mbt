///|
/// Why a diagnostic was not emitted by a policy evaluation.
pub(all) enum SuppressionReason {
  BelowMinimum
  CodeAllowed(String)
  NotSelected(String)
  Duplicate
  SeverityBudget(Severity, Int)
  TotalBudget(Int)
} derive(Eq, Debug)

///|
pub fn SuppressionReason::name(self : SuppressionReason) -> String {
  match self {
    BelowMinimum => "below-minimum"
    CodeAllowed(_) => "code-allowed"
    NotSelected(_) => "not-selected"
    Duplicate => "duplicate"
    SeverityBudget(_, _) => "severity-budget"
    TotalBudget(_) => "total-budget"
  }
}

///|
pub fn SuppressionReason::message(self : SuppressionReason) -> String {
  match self {
    BelowMinimum => "diagnostic is below the configured minimum severity"
    CodeAllowed(code) => "diagnostic code " + code + " is explicitly allowed"
    NotSelected(code) => "diagnostic code " + code + " is not selected"
    Duplicate => "an equivalent diagnostic was already emitted"
    SeverityBudget(severity, limit) =>
      severity.name() +
      " diagnostic budget of " +
      limit.to_string() +
      " was exhausted"
    TotalBudget(limit) =>
      "total diagnostic budget of " + limit.to_string() + " was exhausted"
  }
}

///|
/// A diagnostic together with the reason it was suppressed.
pub struct SuppressedDiagnostic {
  diagnostic : Diagnostic
  reason : SuppressionReason
}

///|
pub fn SuppressedDiagnostic::diagnostic(
  self : SuppressedDiagnostic,
) -> Diagnostic {
  self.diagnostic
}

///|
pub fn SuppressedDiagnostic::reason(
  self : SuppressedDiagnostic,
) -> SuppressionReason {
  self.reason
}

///|
/// Statistics produced while applying a diagnostic policy.
pub struct PolicySummary {
  input : Int
  emitted : Int
  promoted : Int
  suppressed : Int
  duplicates : Int
  budgeted : Int
}

///|
pub fn PolicySummary::input(self : PolicySummary) -> Int {
  self.input
}

///|
pub fn PolicySummary::emitted(self : PolicySummary) -> Int {
  self.emitted
}

///|
pub fn PolicySummary::promoted(self : PolicySummary) -> Int {
  self.promoted
}

///|
pub fn PolicySummary::suppressed(self : PolicySummary) -> Int {
  self.suppressed
}

///|
pub fn PolicySummary::duplicates(self : PolicySummary) -> Int {
  self.duplicates
}

///|
pub fn PolicySummary::budgeted(self : PolicySummary) -> Int {
  self.budgeted
}

///|
/// Result of applying a policy without mutating the input bag.
pub struct PolicyResult {
  emitted : DiagnosticBag
  suppressed : Array[SuppressedDiagnostic]
  summary : PolicySummary
}

///|
pub fn PolicyResult::emitted(self : PolicyResult) -> DiagnosticBag {
  DiagnosticBag::from_array(self.emitted.to_array())
}

///|
pub fn PolicyResult::suppressed(
  self : PolicyResult,
) -> Array[SuppressedDiagnostic] {
  self.suppressed.copy()
}

///|
pub fn PolicyResult::summary(self : PolicyResult) -> PolicySummary {
  self.summary
}

///|
pub fn PolicyResult::has_suppressed(self : PolicyResult) -> Bool {
  !self.suppressed.is_empty()
}

///|
/// Filtering, promotion, de-duplication, and output-budget rules.
///
/// Rules are evaluated in this order:
/// minimum severity, allow-list suppression, selection, promotion,
/// de-duplication, per-severity budget, then total budget.
pub struct DiagnosticPolicy {
  minimum : Severity
  allowed_codes : Array[String]
  selected_codes : Array[String]
  denied_codes : Array[String]
  warnings_as_errors : Bool
  deduplicate : Bool
  advice_limit : Int?
  warning_limit : Int?
  error_limit : Int?
  total_limit : Int?
}

///|
pub fn DiagnosticPolicy::new() -> DiagnosticPolicy {
  {
    minimum: Advice,
    allowed_codes: [],
    selected_codes: [],
    denied_codes: [],
    warnings_as_errors: false,
    deduplicate: true,
    advice_limit: None,
    warning_limit: None,
    error_limit: None,
    total_limit: None,
  }
}

///|
pub fn DiagnosticPolicy::with_minimum(
  self : DiagnosticPolicy,
  minimum : Severity,
) -> DiagnosticPolicy {
  { ..self, minimum, }
}

///|
pub fn DiagnosticPolicy::allow_code(
  self : DiagnosticPolicy,
  code : String,
) -> DiagnosticPolicy {
  if self.allowed_codes.contains(code) {
    self
  } else {
    { ..self, allowed_codes: self.allowed_codes + [code] }
  }
}

///|
pub fn DiagnosticPolicy::select_code(
  self : DiagnosticPolicy,
  code : String,
) -> DiagnosticPolicy {
  if self.selected_codes.contains(code) {
    self
  } else {
    { ..self, selected_codes: self.selected_codes + [code] }
  }
}

///|
pub fn DiagnosticPolicy::deny_code(
  self : DiagnosticPolicy,
  code : String,
) -> DiagnosticPolicy {
  if self.denied_codes.contains(code) {
    self
  } else {
    { ..self, denied_codes: self.denied_codes + [code] }
  }
}

///|
pub fn DiagnosticPolicy::with_warnings_as_errors(
  self : DiagnosticPolicy,
  enabled : Bool,
) -> DiagnosticPolicy {
  { ..self, warnings_as_errors: enabled }
}

///|
pub fn DiagnosticPolicy::with_deduplication(
  self : DiagnosticPolicy,
  enabled : Bool,
) -> DiagnosticPolicy {
  { ..self, deduplicate: enabled }
}

///|
pub fn DiagnosticPolicy::with_advice_limit(
  self : DiagnosticPolicy,
  limit : Int,
) -> DiagnosticPolicy {
  { ..self, advice_limit: Some(limit.clamp(min=0, max=limit)) }
}

///|
pub fn DiagnosticPolicy::with_warning_limit(
  self : DiagnosticPolicy,
  limit : Int,
) -> DiagnosticPolicy {
  { ..self, warning_limit: Some(limit.clamp(min=0, max=limit)) }
}

///|
pub fn DiagnosticPolicy::with_error_limit(
  self : DiagnosticPolicy,
  limit : Int,
) -> DiagnosticPolicy {
  { ..self, error_limit: Some(limit.clamp(min=0, max=limit)) }
}

///|
pub fn DiagnosticPolicy::with_total_limit(
  self : DiagnosticPolicy,
  limit : Int,
) -> DiagnosticPolicy {
  { ..self, total_limit: Some(limit.clamp(min=0, max=limit)) }
}

///|
fn non_negative(value : Int) -> Int {
  if value < 0 {
    0
  } else {
    value
  }
}

///|
pub fn DiagnosticPolicy::limits(
  self : DiagnosticPolicy,
  advice? : Int? = None,
  warnings? : Int? = None,
  errors? : Int? = None,
  total? : Int? = None,
) -> DiagnosticPolicy {
  {
    ..self,
    advice_limit: advice.map(non_negative),
    warning_limit: warnings.map(non_negative),
    error_limit: errors.map(non_negative),
    total_limit: total.map(non_negative),
  }
}

///|
pub fn DiagnosticPolicy::minimum(self : DiagnosticPolicy) -> Severity {
  self.minimum
}

///|
pub fn DiagnosticPolicy::warnings_as_errors(self : DiagnosticPolicy) -> Bool {
  self.warnings_as_errors
}

///|
pub fn DiagnosticPolicy::deduplicates(self : DiagnosticPolicy) -> Bool {
  self.deduplicate
}

///|
fn diagnostic_code_or_empty(diagnostic : Diagnostic) -> String {
  diagnostic.code().unwrap_or("")
}

///|
fn DiagnosticPolicy::early_suppression(
  self : DiagnosticPolicy,
  diagnostic : Diagnostic,
) -> SuppressionReason? {
  if diagnostic.severity().rank() < self.minimum.rank() {
    return Some(BelowMinimum)
  }
  let code = diagnostic_code_or_empty(diagnostic)
  if code.length() > 0 && self.allowed_codes.contains(code) {
    return Some(CodeAllowed(code))
  }
  if !self.selected_codes.is_empty() &&
    (code.length() == 0 || !self.selected_codes.contains(code)) {
    return Some(NotSelected(code))
  }
  None
}

///|
fn DiagnosticPolicy::promote(
  self : DiagnosticPolicy,
  diagnostic : Diagnostic,
) -> (Diagnostic, Bool) {
  let code = diagnostic_code_or_empty(diagnostic)
  let denied = code.length() > 0 && self.denied_codes.contains(code)
  let all_warnings = self.warnings_as_errors && diagnostic.severity() == Warning
  if diagnostic.severity() != Error && (denied || all_warnings) {
    (diagnostic.with_severity(Error), true)
  } else {
    (diagnostic, false)
  }
}

///|
fn write_fingerprint_label(output : StringBuilder, label : Label) -> Unit {
  output.write_string(label.source().value().to_string())
  output.write_char(':')
  output.write_string(label.span().start().to_string())
  output.write_char(':')
  output.write_string(label.span().end().to_string())
  output.write_char(':')
  output.write_string(if label.is_primary() { "p" } else { "s" })
  output.write_char(':')
  output.write_string(label.message())
  output.write_char('|')
}

///|
/// Stable identity used by policy de-duplication.
///
/// Notes and help are intentionally excluded: producers often attach contextual
/// notes at different layers while referring to the same underlying problem.
pub fn diagnostic_fingerprint(diagnostic : Diagnostic) -> String {
  let output = StringBuilder::new()
  output.write_string(diagnostic.severity().name())
  output.write_char('|')
  output.write_string(diagnostic_code_or_empty(diagnostic))
  output.write_char('|')
  output.write_string(diagnostic.message())
  output.write_char('|')
  let labels = diagnostic.labels()
  labels.sort_by(fn(left, right) {
    let source_order = left.source().compare(right.source())
    if source_order != 0 {
      source_order
    } else {
      left.span().start().compare(right.span().start())
    }
  })
  labels.each(fn(label) { write_fingerprint_label(output, label) })
  output.to_string()
}

///|
fn limit_for(policy : DiagnosticPolicy, severity : Severity) -> Int? {
  match severity {
    Advice => policy.advice_limit
    Warning => policy.warning_limit
    Error => policy.error_limit
  }
}

///|
fn count_for(
  severity : Severity,
  advice : Int,
  warnings : Int,
  errors : Int,
) -> Int {
  match severity {
    Advice => advice
    Warning => warnings
    Error => errors
  }
}

///|
pub fn DiagnosticPolicy::apply(
  self : DiagnosticPolicy,
  bag : DiagnosticBag,
) -> PolicyResult {
  let emitted = DiagnosticBag::new()
  let suppressed : Array[SuppressedDiagnostic] = []
  let fingerprints : Array[String] = []
  let mut promoted_count = 0
  let mut duplicate_count = 0
  let mut budget_count = 0
  let mut advice_count = 0
  let mut warning_count = 0
  let mut error_count = 0
  for diagnostic in bag.to_array() {
    match self.early_suppression(diagnostic) {
      Some(reason) => {
        suppressed.push({ diagnostic, reason })
        continue
      }
      None => ()
    }
    let (candidate, promoted) = self.promote(diagnostic)
    let fingerprint = diagnostic_fingerprint(candidate)
    if self.deduplicate && fingerprints.contains(fingerprint) {
      suppressed.push({ diagnostic: candidate, reason: Duplicate })
      duplicate_count += 1
      continue
    }
    let severity = candidate.severity()
    let severity_count = count_for(
      severity, advice_count, warning_count, error_count,
    )
    match limit_for(self, severity) {
      Some(limit) =>
        if severity_count >= limit {
          suppressed.push({
            diagnostic: candidate,
            reason: SeverityBudget(severity, limit),
          })
          budget_count += 1
          continue
        }
      None => ()
    }
    match self.total_limit {
      Some(limit) =>
        if emitted.length() >= limit {
          suppressed.push({ diagnostic: candidate, reason: TotalBudget(limit) })
          budget_count += 1
          continue
        }
      None => ()
    }
    fingerprints.push(fingerprint)
    emitted.add(candidate)
    if promoted {
      promoted_count += 1
    }
    match severity {
      Advice => advice_count += 1
      Warning => warning_count += 1
      Error => error_count += 1
    }
  }
  let summary = {
    input: bag.length(),
    emitted: emitted.length(),
    promoted: promoted_count,
    suppressed: suppressed.length(),
    duplicates: duplicate_count,
    budgeted: budget_count,
  }
  { emitted, suppressed, summary }
}
