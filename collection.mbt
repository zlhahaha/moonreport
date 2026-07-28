///|
/// Counts diagnostics by severity without exposing mutable internal state.
pub struct Summary {
  advice : Int
  warnings : Int
  errors : Int
} derive(Eq, Debug)

///|
pub fn Summary::advice(self : Summary) -> Int {
  self.advice
}

///|
pub fn Summary::warnings(self : Summary) -> Int {
  self.warnings
}

///|
pub fn Summary::errors(self : Summary) -> Int {
  self.errors
}

///|
pub fn Summary::total(self : Summary) -> Int {
  self.advice + self.warnings + self.errors
}

///|
pub fn Summary::has_errors(self : Summary) -> Bool {
  self.errors > 0
}

///|
/// An insertion-ordered batch of diagnostics.
pub struct DiagnosticBag {
  items : Array[Diagnostic]
}

///|
pub fn DiagnosticBag::new() -> DiagnosticBag {
  { items: [] }
}

///|
pub fn DiagnosticBag::from_array(items : Array[Diagnostic]) -> DiagnosticBag {
  { items: items.copy() }
}

///|
pub fn DiagnosticBag::add(
  self : DiagnosticBag,
  diagnostic : Diagnostic,
) -> Unit {
  self.items.push(diagnostic)
}

///|
pub fn DiagnosticBag::length(self : DiagnosticBag) -> Int {
  self.items.length()
}

///|
pub fn DiagnosticBag::is_empty(self : DiagnosticBag) -> Bool {
  self.items.is_empty()
}

///|
pub fn DiagnosticBag::to_array(self : DiagnosticBag) -> Array[Diagnostic] {
  self.items.copy()
}

///|
pub fn DiagnosticBag::summary(self : DiagnosticBag) -> Summary {
  let mut advice = 0
  let mut warnings = 0
  let mut errors = 0
  for diagnostic in self.items {
    match diagnostic.severity() {
      Advice => advice += 1
      Warning => warnings += 1
      Error => errors += 1
    }
  }
  { advice, warnings, errors }
}

///|
/// Returns diagnostics at or above the requested severity.
pub fn DiagnosticBag::at_least(
  self : DiagnosticBag,
  minimum : Severity,
) -> Array[Diagnostic] {
  self.items.filter(fn(item) { item.severity().rank() >= minimum.rank() })
}

///|
/// Conventional process exit code: one when a diagnostic reaches the failure
/// threshold, otherwise zero.
pub fn DiagnosticBag::exit_code(
  self : DiagnosticBag,
  fail_on? : Severity = Error,
) -> Int {
  if self.items.any(fn(item) { item.severity().rank() >= fail_on.rank() }) {
    1
  } else {
    0
  }
}

///|
/// Renders a diagnostic batch, separated by one blank line.
pub fn DiagnosticBag::render(
  self : DiagnosticBag,
  sources : SourceMap,
  config? : RenderConfig = RenderConfig::default(),
) -> String {
  let output = StringBuilder::new()
  for index, diagnostic in self.items {
    if index > 0 {
      output.write_string("\n\n")
    }
    output.write_string(render(sources, diagnostic, config~))
  }
  output.to_string()
}

///|
/// Serializes a batch as newline-delimited JSON.
pub fn DiagnosticBag::render_json_lines(
  self : DiagnosticBag,
  sources : SourceMap,
) -> String {
  render_json_lines(sources, self.items)
}
