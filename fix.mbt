///|
/// How confidently an automated edit can be applied.
pub(all) enum Applicability {
  /// The replacement is semantics-preserving and safe for unattended use.
  MachineApplicable
  /// The replacement is normally correct but may require user review.
  MaybeIncorrect
  /// The replacement contains explanatory placeholders.
  HasPlaceholders
  /// The edit is a suggestion that requires a human decision.
  Unspecified
} derive(Eq, Debug)

///|
pub fn Applicability::name(self : Applicability) -> String {
  match self {
    MachineApplicable => "machine-applicable"
    MaybeIncorrect => "maybe-incorrect"
    HasPlaceholders => "has-placeholders"
    Unspecified => "unspecified"
  }
}

///|
pub fn Applicability::is_automatic(self : Applicability) -> Bool {
  self == MachineApplicable
}

///|
/// One UTF-8 byte-range replacement in a registered source.
pub struct TextEdit {
  source : SourceId
  span : Span
  replacement : String
} derive(Eq, Debug)

///|
pub fn TextEdit::replace(
  source : SourceId,
  span : Span,
  replacement : String,
) -> TextEdit {
  { source, span, replacement }
}

///|
pub fn TextEdit::insert(
  source : SourceId,
  offset : Int,
  text : String,
) -> TextEdit? {
  match Span::new(offset, offset) {
    Some(span) => Some({ source, span, replacement: text })
    None => None
  }
}

///|
pub fn TextEdit::delete(source : SourceId, span : Span) -> TextEdit {
  { source, span, replacement: "" }
}

///|
pub fn TextEdit::source(self : TextEdit) -> SourceId {
  self.source
}

///|
pub fn TextEdit::span(self : TextEdit) -> Span {
  self.span
}

///|
pub fn TextEdit::replacement(self : TextEdit) -> String {
  self.replacement
}

///|
pub fn TextEdit::is_insertion(self : TextEdit) -> Bool {
  self.span.is_empty() && self.replacement.length() > 0
}

///|
pub fn TextEdit::is_deletion(self : TextEdit) -> Bool {
  !self.span.is_empty() && self.replacement.length() == 0
}

///|
/// The outcome of checking a fix against a source registry.
pub(all) enum FixValidation {
  Valid
  Empty
  UnknownSource(SourceId)
  OutOfBounds(SourceId, Span, Int)
  Overlapping(SourceId, Span, Span)
} derive(Eq, Debug)

///|
pub fn FixValidation::is_valid(self : FixValidation) -> Bool {
  self == Valid
}

///|
pub fn FixValidation::message(self : FixValidation) -> String {
  match self {
    Valid => "valid"
    Empty => "fix contains no edits"
    UnknownSource(id) => "unknown source " + id.value().to_string()
    OutOfBounds(id, span, length) =>
      "edit " +
      span.start().to_string() +
      ".." +
      span.end().to_string() +
      " exceeds source " +
      id.value().to_string() +
      " length " +
      length.to_string()
    Overlapping(id, left, right) =>
      "overlapping edits in source " +
      id.value().to_string() +
      ": " +
      left.start().to_string() +
      ".." +
      left.end().to_string() +
      " and " +
      right.start().to_string() +
      ".." +
      right.end().to_string()
  }
}

///|
/// A named group of edits that should be accepted or rejected together.
pub struct Fix {
  title : String
  applicability : Applicability
  edits : Array[TextEdit]
}

///|
pub fn Fix::new(
  title : String,
  applicability? : Applicability = Unspecified,
) -> Fix {
  { title, applicability, edits: [] }
}

///|
pub fn Fix::with_edit(self : Fix, edit : TextEdit) -> Fix {
  { ..self, edits: self.edits + [edit] }
}

///|
pub fn Fix::title(self : Fix) -> String {
  self.title
}

///|
pub fn Fix::applicability(self : Fix) -> Applicability {
  self.applicability
}

///|
pub fn Fix::edits(self : Fix) -> Array[TextEdit] {
  self.edits.copy()
}

///|
pub fn Fix::is_automatic(self : Fix) -> Bool {
  self.applicability.is_automatic()
}

///|
fn TextEdit::compare_position(self : TextEdit, other : TextEdit) -> Int {
  let source_order = self.source.compare(other.source)
  if source_order != 0 {
    source_order
  } else {
    let start_order = self.span.start().compare(other.span.start())
    if start_order != 0 {
      start_order
    } else {
      self.span.end().compare(other.span.end())
    }
  }
}

///|
fn Fix::sorted_edits(self : Fix) -> Array[TextEdit] {
  let sorted = self.edits.copy()
  sorted.sort_by(fn(left, right) { left.compare_position(right) })
  sorted
}

///|
pub fn Fix::validate(self : Fix, sources : SourceMap) -> FixValidation {
  if self.edits.is_empty() {
    return Empty
  }
  let sorted = self.sorted_edits()
  for index, edit in sorted {
    match sources.get(edit.source()) {
      None => return UnknownSource(edit.source())
      Some(source) =>
        if edit.span().end() > source.byte_length() {
          return OutOfBounds(edit.source(), edit.span(), source.byte_length())
        }
    }
    if index > 0 {
      let previous = sorted[index - 1]
      if previous.source() == edit.source() &&
        previous.span().end() > edit.span().start() {
        return Overlapping(edit.source(), previous.span(), edit.span())
      }
    }
  }
  Valid
}

///|
fn apply_source_edits(source : Source, edits : Array[TextEdit]) -> String {
  let output = StringBuilder::new()
  let mut cursor = 0
  for edit in edits {
    output.write_string(source.slice_offsets(cursor, edit.span().start()))
    output.write_string(edit.replacement())
    cursor = edit.span().end()
  }
  output.write_string(source.slice_offsets(cursor, source.byte_length()))
  output.to_string()
}

///|
/// Applies this fix and returns a new source map.
///
/// The original map is never mutated. Invalid fixes return their validation
/// result and no partial edit is observable.
pub fn Fix::apply(
  self : Fix,
  sources : SourceMap,
) -> (SourceMap?, FixValidation) {
  let validation = self.validate(sources)
  if !validation.is_valid() {
    return (None, validation)
  }
  let sorted = self.sorted_edits()
  let result = SourceMap::new()
  for source_index = 0
      source_index < sources.length()
      source_index = source_index + 1 {
    let source_id = SourceId::new(source_index).unwrap()
    let source = sources.get(source_id).unwrap()
    let edits = sorted.filter(fn(edit) { edit.source() == source_id })
    let text = if edits.is_empty() {
      source.text()
    } else {
      apply_source_edits(source, edits)
    }
    result.add(source.name(), text) |> ignore
  }
  (Some(result), Valid)
}

///|
/// Applies only edits for one source and leaves validation explicit.
pub fn Fix::apply_to_source(
  self : Fix,
  sources : SourceMap,
  source_id : SourceId,
) -> (String?, FixValidation) {
  let validation = self.validate(sources)
  if !validation.is_valid() {
    return (None, validation)
  }
  match sources.get(source_id) {
    None => (None, UnknownSource(source_id))
    Some(source) => {
      let edits = self
        .sorted_edits()
        .filter(fn(edit) { edit.source() == source_id })
      if edits.is_empty() {
        (Some(source.text()), Valid)
      } else {
        (Some(apply_source_edits(source, edits)), Valid)
      }
    }
  }
}
