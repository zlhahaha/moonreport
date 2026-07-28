///|
/// Options for human-readable source reports.
pub struct RenderConfig {
  context_lines : Int
  tab_width : Int
  show_source_name : Bool
  show_code : Bool
} derive(Eq, Debug)

///|
pub fn RenderConfig::default() -> RenderConfig {
  { context_lines: 2, tab_width: 4, show_source_name: true, show_code: true }
}

///|
pub fn RenderConfig::new(
  context_lines? : Int = 2,
  tab_width? : Int = 4,
  show_source_name? : Bool = true,
  show_code? : Bool = true,
) -> RenderConfig {
  {
    context_lines: if context_lines < 0 {
      0
    } else {
      context_lines
    },
    tab_width: if tab_width < 1 {
      1
    } else {
      tab_width
    },
    show_source_name,
    show_code,
  }
}

///|
fn write_repeated(
  output : StringBuilder,
  character : Char,
  count : Int,
) -> Unit {
  let mut index = 0
  while index < count {
    output.write_char(character)
    index += 1
  }
}

///|
fn decimal_width(value : Int) -> Int {
  let mut number = if value < 0 { -value } else { value }
  let mut width = 1
  while number >= 10 {
    number /= 10
    width += 1
  }
  width
}

///|
fn write_line_number(output : StringBuilder, line : Int, width : Int) -> Unit {
  let text = "\{line + 1}"
  write_repeated(output, ' ', width - text.length())
  output.write_string(text)
}

///|
fn label_touches_line(source : Source, label : Label, line : Int) -> Bool {
  match source.line_span(line) {
    None => false
    Some(line_span) =>
      if label.span().is_empty() {
        let location = source.location(label.span().start())
        location.line() == line
      } else {
        label.span().start() < line_span.end() + 1 &&
        label.span().end() > line_span.start()
      }
  }
}

///|
fn label_columns(
  source : Source,
  label : Label,
  line : Int,
  display : DisplayConfig,
) -> (Int, Int) {
  let line_span = source.line_span(line).unwrap()
  let text = source.line_text(line).unwrap()
  let span = label.span()
  let byte_start = if span.start() > line_span.start() {
    span.start() - line_span.start()
  } else {
    0
  }
  let byte_end = if span.end() < line_span.end() {
    span.end() - line_span.start()
  } else {
    line_span.length()
  }
  let start = display_column(text, byte_start, config=display)
  let end = display_column(text, byte_end, config=display)
  (start, if end > start { end } else { start + 1 })
}

///|
fn source_labels(diagnostic : Diagnostic, source_id : SourceId) -> Array[Label] {
  diagnostic.labels().filter(fn(label) { label.source() == source_id })
}

///|
fn source_windows(
  source : Source,
  labels : Array[Label],
  context_lines : Int,
) -> Array[LineWindow] {
  let windows = labels.map(fn(label) {
    source.window(label.span(), context_lines~)
  })
  merge_windows(windows)
}

///|
fn render_annotation(
  output : StringBuilder,
  source : Source,
  labels : Array[Label],
  line : Int,
  number_width : Int,
  display : DisplayConfig,
) -> Unit {
  let active = labels.filter(fn(label) {
    label_touches_line(source, label, line)
  })
  for label in active {
    let (start, end) = label_columns(source, label, line, display)
    write_repeated(output, ' ', number_width)
    output.write_string(" | ")
    write_repeated(output, ' ', start)
    write_repeated(
      output,
      if label.is_primary() {
        '^'
      } else {
        '-'
      },
      end - start,
    )
    if label.message().length() > 0 {
      output.write_char(' ')
      output.write_string(label.message())
    }
    output.write_char('\n')
  }
}

///|
fn render_source_block(
  output : StringBuilder,
  source : Source,
  source_id : SourceId,
  labels : Array[Label],
  config : RenderConfig,
) -> Unit {
  let display = DisplayConfig::new(config.tab_width, 1)
  let windows = source_windows(source, labels, config.context_lines)
  let number_width = decimal_width(source.line_count())
  if config.show_source_name {
    let first = labels[0]
    let location = source.location(first.span().start())
    write_repeated(output, ' ', number_width)
    output.write_string(" --> ")
    output.write_string(source.name())
    output.write_string(":\{location.line() + 1}:\{location.column() + 1}")
    output.write_char('\n')
  }
  write_repeated(output, ' ', number_width)
  output.write_string(" |\n")
  for window_index, window in windows {
    if window_index > 0 {
      write_repeated(output, ' ', number_width)
      output.write_string(" :\n")
    }
    let mut line = window.first()
    while line <= window.last() {
      write_line_number(output, line, number_width)
      output.write_string(" | ")
      output.write_string(
        expand_tabs(source.line_text(line).unwrap(), config=display),
      )
      output.write_char('\n')
      render_annotation(output, source, labels, line, number_width, display)
      line += 1
    }
  }
  ignore(source_id)
}

///|
/// Renders a diagnostic with source context and aligned labels.
///
/// Invalid source IDs are omitted from source blocks but the diagnostic header,
/// notes, and help remain visible.
pub fn render(
  sources : SourceMap,
  diagnostic : Diagnostic,
  config? : RenderConfig = RenderConfig::default(),
) -> String {
  let output = StringBuilder::new()
  output.write_string(diagnostic.severity().name())
  if config.show_code {
    match diagnostic.code() {
      Some(code) => output.write_string("[\{code}]")
      None => ()
    }
  }
  output.write_string(": ")
  output.write_string(diagnostic.message())
  output.write_char('\n')
  let rendered_sources : Array[SourceId] = []
  for label in diagnostic.labels() {
    if rendered_sources.contains(label.source()) {
      continue
    }
    match sources.get(label.source()) {
      None => ()
      Some(source) => {
        let labels = source_labels(diagnostic, label.source())
        render_source_block(output, source, label.source(), labels, config)
        rendered_sources.push(label.source())
      }
    }
  }
  for note in diagnostic.notes() {
    output.write_string("  = note: ")
    output.write_string(note)
    output.write_char('\n')
  }
  match diagnostic.help() {
    Some(help) => {
      output.write_string("  = help: ")
      output.write_string(help)
      output.write_char('\n')
    }
    None => ()
  }
  output.to_string()
}

///|
/// Renders multiple reports with one blank line between them.
pub fn render_all(
  sources : SourceMap,
  diagnostics : Array[Diagnostic],
  config? : RenderConfig = RenderConfig::default(),
) -> String {
  let output = StringBuilder::new()
  for index, diagnostic in diagnostics {
    if index > 0 {
      output.write_char('\n')
    }
    output.write_string(render(sources, diagnostic, config~))
  }
  output.to_string()
}
