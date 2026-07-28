///|
fn one_based(value : Int) -> Int {
  value + 1
}

///|
/// Renders one diagnostic as a stable, grep-friendly line plus notes.
pub fn render_compact(sources : SourceMap, diagnostic : Diagnostic) -> String {
  let header = match diagnostic.primary_label() {
    None => "\{diagnostic.severity().name()}: \{diagnostic.message()}"
    Some(label) =>
      match sources.get(label.source()) {
        None => "\{diagnostic.severity().name()}: \{diagnostic.message()}"
        Some(source) => {
          let location = source.location(label.span().start())
          "\{source.name()}:\{one_based(location.line())}:\{one_based(location.column())}: \{diagnostic.severity().name()}: \{diagnostic.message()}"
        }
      }
  }
  let with_code = match diagnostic.code() {
    None => header
    Some(code) => "\{header} [\{code}]"
  }
  let buffer = StringBuilder::new()
  buffer.write_string(with_code)
  for note in diagnostic.notes() {
    buffer.write_string("\n  note: ")
    buffer.write_string(note)
  }
  match diagnostic.help() {
    Some(help) => {
      buffer.write_string("\n  help: ")
      buffer.write_string(help)
    }
    None => ()
  }
  buffer.to_string()
}

///|
/// Renders diagnostics separated by newlines without a trailing newline.
pub fn render_compact_all(
  sources : SourceMap,
  diagnostics : Array[Diagnostic],
) -> String {
  let buffer = StringBuilder::new()
  for index, diagnostic in diagnostics {
    if index > 0 {
      buffer.write_char('\n')
    }
    buffer.write_string(render_compact(sources, diagnostic))
  }
  buffer.to_string()
}
