///|
/// Importance of a diagnostic, ordered from least to most severe.
pub(all) enum Severity {
  Advice
  Warning
  Error
} derive(Eq, Debug)

///|
pub fn Severity::name(self : Severity) -> String {
  match self {
    Advice => "advice"
    Warning => "warning"
    Error => "error"
  }
}

///|
pub fn Severity::rank(self : Severity) -> Int {
  match self {
    Advice => 0
    Warning => 1
    Error => 2
  }
}

///|
/// A stable identifier for one source registered in a SourceMap.
pub(all) struct SourceId(Int) derive(Eq, Compare, Hash, Debug)

///|
pub fn SourceId::new(value : Int) -> SourceId? {
  if value < 0 {
    None
  } else {
    Some(SourceId(value))
  }
}

///|
pub fn SourceId::value(self : SourceId) -> Int {
  self.0
}

///|
/// A source range and its optional explanatory text.
pub struct Label {
  source : SourceId
  span : Span
  message : String
  primary : Bool
} derive(Eq, Debug)

///|
pub fn Label::primary(
  source : SourceId,
  span : Span,
  message : String,
) -> Label {
  { source, span, message, primary: true }
}

///|
pub fn Label::secondary(
  source : SourceId,
  span : Span,
  message : String,
) -> Label {
  { source, span, message, primary: false }
}

///|
pub fn Label::source(self : Label) -> SourceId {
  self.source
}

///|
pub fn Label::span(self : Label) -> Span {
  self.span
}

///|
pub fn Label::message(self : Label) -> String {
  self.message
}

///|
pub fn Label::is_primary(self : Label) -> Bool {
  self.primary
}

///|
/// A complete problem report independent of presentation format.
pub struct Diagnostic {
  severity : Severity
  message : String
  code : String?
  help : String?
  notes : Array[String]
  labels : Array[Label]
} derive(Eq, Debug)

///|
pub fn Diagnostic::new(severity : Severity, message : String) -> Diagnostic {
  { severity, message, code: None, help: None, notes: [], labels: [] }
}

///|
pub fn Diagnostic::with_code(self : Diagnostic, code : String) -> Diagnostic {
  { ..self, code: Some(code) }
}

///|
pub fn Diagnostic::with_help(self : Diagnostic, help : String) -> Diagnostic {
  { ..self, help: Some(help) }
}

///|
pub fn Diagnostic::with_note(self : Diagnostic, note : String) -> Diagnostic {
  { ..self, notes: self.notes + [note] }
}

///|
pub fn Diagnostic::with_label(self : Diagnostic, label : Label) -> Diagnostic {
  { ..self, labels: self.labels + [label] }
}

///|
pub fn Diagnostic::severity(self : Diagnostic) -> Severity {
  self.severity
}

///|
pub fn Diagnostic::message(self : Diagnostic) -> String {
  self.message
}

///|
pub fn Diagnostic::code(self : Diagnostic) -> String? {
  self.code
}

///|
pub fn Diagnostic::help(self : Diagnostic) -> String? {
  self.help
}

///|
pub fn Diagnostic::notes(self : Diagnostic) -> Array[String] {
  self.notes.copy()
}

///|
pub fn Diagnostic::labels(self : Diagnostic) -> Array[Label] {
  self.labels.copy()
}

///|
pub fn Diagnostic::primary_label(self : Diagnostic) -> Label? {
  for label in self.labels {
    if label.is_primary() {
      return Some(label)
    }
  }
  None
}

///|
pub fn Diagnostic::is_valid(self : Diagnostic) -> Bool {
  self.message.length() > 0 && self.labels.any(fn(label) { label.is_primary() })
}
