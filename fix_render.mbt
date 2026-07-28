///|
/// One edit enriched with source locations for display and transport.
pub struct EditPreview {
  source : SourceId
  source_name : String
  span : Span
  start : Location
  end : Location
  original : String
  replacement : String
}

///|
pub fn EditPreview::source(self : EditPreview) -> SourceId {
  self.source
}

///|
pub fn EditPreview::source_name(self : EditPreview) -> String {
  self.source_name
}

///|
pub fn EditPreview::span(self : EditPreview) -> Span {
  self.span
}

///|
pub fn EditPreview::start(self : EditPreview) -> Location {
  self.start
}

///|
pub fn EditPreview::end(self : EditPreview) -> Location {
  self.end
}

///|
pub fn EditPreview::original(self : EditPreview) -> String {
  self.original
}

///|
pub fn EditPreview::replacement(self : EditPreview) -> String {
  self.replacement
}

///|
pub fn EditPreview::is_insertion(self : EditPreview) -> Bool {
  self.span.is_empty() && self.replacement.length() > 0
}

///|
pub fn EditPreview::is_deletion(self : EditPreview) -> Bool {
  !self.span.is_empty() && self.replacement.length() == 0
}

///|
/// A validated, presentation-ready view of a fix.
pub struct FixPreview {
  title : String
  applicability : Applicability
  edits : Array[EditPreview]
}

///|
pub fn FixPreview::title(self : FixPreview) -> String {
  self.title
}

///|
pub fn FixPreview::applicability(self : FixPreview) -> Applicability {
  self.applicability
}

///|
pub fn FixPreview::edits(self : FixPreview) -> Array[EditPreview] {
  self.edits.copy()
}

///|
pub fn FixPreview::edit_count(self : FixPreview) -> Int {
  self.edits.length()
}

///|
pub fn FixPreview::source_count(self : FixPreview) -> Int {
  let seen : Array[SourceId] = []
  for edit in self.edits {
    if !seen.contains(edit.source()) {
      seen.push(edit.source())
    }
  }
  seen.length()
}

///|
/// Builds a preview only after the complete fix has passed validation.
pub fn Fix::preview(
  self : Fix,
  sources : SourceMap,
) -> (FixPreview?, FixValidation) {
  let validation = self.validate(sources)
  if !validation.is_valid() {
    return (None, validation)
  }
  let previews : Array[EditPreview] = []
  for edit in self.edits() {
    let source = sources.get(edit.source()).unwrap()
    previews.push({
      source: edit.source(),
      source_name: source.name(),
      span: edit.span(),
      start: source.location(edit.span().start()),
      end: source.location(edit.span().end()),
      original: source.slice(edit.span()),
      replacement: edit.replacement(),
    })
  }
  previews.sort_by(fn(left, right) {
    let source_order = left.source().compare(right.source())
    if source_order != 0 {
      source_order
    } else {
      left.span().start().compare(right.span().start())
    }
  })
  (
    Some({
      title: self.title(),
      applicability: self.applicability(),
      edits: previews,
    }),
    Valid,
  )
}

///|
fn write_prefixed_lines(
  output : StringBuilder,
  prefix : Char,
  text : String,
) -> Unit {
  if text.length() == 0 {
    output.write_char(prefix)
    output.write_char('\n')
    return
  }
  let lines = text.split("\n")
  for line in lines {
    output.write_char(prefix)
    output.write_string(line.to_owned())
    output.write_char('\n')
  }
}

///|
fn write_preview_header(output : StringBuilder, edit : EditPreview) -> Unit {
  output.write_string("@@ -")
  output.write_string((edit.start().line() + 1).to_string())
  output.write_char(':')
  output.write_string((edit.start().column() + 1).to_string())
  output.write_string(" +")
  output.write_string((edit.start().line() + 1).to_string())
  output.write_char(':')
  output.write_string((edit.start().column() + 1).to_string())
  output.write_string(" @@\n")
}

///|
/// Renders a compact unified-diff-like preview.
///
/// Locations are one-based for humans. The format is deliberately a preview
/// rather than a patch file: replacements may start or end mid-line.
pub fn render_fix_preview(preview : FixPreview) -> String {
  let output = StringBuilder::new()
  output.write_string("fix: ")
  output.write_string(preview.title())
  output.write_string(" [")
  output.write_string(preview.applicability().name())
  output.write_string("]\n")
  let mut previous_source : SourceId? = None
  for edit in preview.edits() {
    if previous_source != Some(edit.source()) {
      output.write_string("--- ")
      output.write_string(edit.source_name())
      output.write_char('\n')
      output.write_string("+++ ")
      output.write_string(edit.source_name())
      output.write_string(" (fixed)\n")
      previous_source = Some(edit.source())
    }
    write_preview_header(output, edit)
    write_prefixed_lines(output, '-', edit.original())
    write_prefixed_lines(output, '+', edit.replacement())
  }
  output.to_string()
}

///|
fn write_json_location(output : StringBuilder, location : Location) -> Unit {
  output.write_string("{\"line\":")
  output.write_string((location.line() + 1).to_string())
  output.write_string(",\"column\":")
  output.write_string((location.column() + 1).to_string())
  output.write_string(",\"offset\":")
  output.write_string(location.offset().to_string())
  output.write_char('}')
}

///|
fn write_json_edit_preview(output : StringBuilder, edit : EditPreview) -> Unit {
  output.write_string("{\"source_id\":")
  output.write_string(edit.source().value().to_string())
  output.write_string(",\"source_name\":")
  write_json_string(output, edit.source_name())
  output.write_string(",\"start\":")
  write_json_location(output, edit.start())
  output.write_string(",\"end\":")
  write_json_location(output, edit.end())
  output.write_string(",\"original\":")
  write_json_string(output, edit.original())
  output.write_string(",\"replacement\":")
  write_json_string(output, edit.replacement())
  output.write_char('}')
}

///|
/// Serializes a validated fix preview to stable JSON for editor integrations.
pub fn render_fix_json(preview : FixPreview) -> String {
  let output = StringBuilder::new()
  output.write_string("{\"title\":")
  write_json_string(output, preview.title())
  output.write_string(",\"applicability\":")
  write_json_string(output, preview.applicability().name())
  output.write_string(",\"source_count\":")
  output.write_string(preview.source_count().to_string())
  output.write_string(",\"edits\":[")
  for index, edit in preview.edits() {
    if index > 0 {
      output.write_char(',')
    }
    write_json_edit_preview(output, edit)
  }
  output.write_string("]}")
  output.to_string()
}

///|
/// Convenience operation for callers that want validation and JSON in one step.
pub fn Fix::render_json(
  self : Fix,
  sources : SourceMap,
) -> (String?, FixValidation) {
  let (preview, validation) = self.preview(sources)
  match preview {
    Some(value) => (Some(render_fix_json(value)), validation)
    None => (None, validation)
  }
}

///|
/// Convenience operation for callers that want validation and text in one step.
pub fn Fix::render_preview(
  self : Fix,
  sources : SourceMap,
) -> (String?, FixValidation) {
  let (preview, validation) = self.preview(sources)
  match preview {
    Some(value) => (Some(render_fix_preview(value)), validation)
    None => (None, validation)
  }
}
