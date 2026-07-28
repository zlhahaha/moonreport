///|
/// Named ANSI color used by terminal themes.
pub(all) enum Color {
  Default
  Black
  Red
  Green
  Yellow
  Blue
  Magenta
  Cyan
  White
  BrightBlack
  BrightRed
  BrightYellow
  BrightBlue
  BrightCyan
  BrightWhite
} derive(Eq, Debug)

///|
fn Color::ansi(self : Color) -> Int {
  match self {
    Default => 39
    Black => 30
    Red => 31
    Green => 32
    Yellow => 33
    Blue => 34
    Magenta => 35
    Cyan => 36
    White => 37
    BrightBlack => 90
    BrightRed => 91
    BrightYellow => 93
    BrightBlue => 94
    BrightCyan => 96
    BrightWhite => 97
  }
}

///|
/// Semantic terminal colors for a diagnostic report.
pub struct Theme {
  error : Color
  warning : Color
  advice : Color
  line_number : Color
  primary : Color
  secondary : Color
  note : Color
  help : Color
  bold_header : Bool
} derive(Eq, Debug)

///|
/// A legible theme for dark terminal backgrounds.
pub fn Theme::dark() -> Theme {
  {
    error: BrightRed,
    warning: BrightYellow,
    advice: BrightCyan,
    line_number: BrightBlue,
    primary: BrightRed,
    secondary: BrightCyan,
    note: BrightWhite,
    help: Green,
    bold_header: true,
  }
}

///|
/// A lower-intensity theme for light terminal backgrounds.
pub fn Theme::light() -> Theme {
  {
    error: Red,
    warning: Yellow,
    advice: Blue,
    line_number: Blue,
    primary: Red,
    secondary: Cyan,
    note: Black,
    help: Green,
    bold_header: true,
  }
}

///|
pub fn Theme::severity(self : Theme, severity : Severity) -> Color {
  match severity {
    Error => self.error
    Warning => self.warning
    Advice => self.advice
  }
}

///|
fn ansi_start(color : Color, bold : Bool) -> String {
  if bold {
    "\u{001b}[1;\{color.ansi()}m"
  } else {
    "\u{001b}[\{color.ansi()}m"
  }
}

///|
fn ansi_wrap(text : String, color : Color, bold : Bool) -> String {
  "\{ansi_start(color, bold)}\{text}\u{001b}[0m"
}

///|
fn colorize_report_line(
  line : String,
  severity : Severity,
  theme : Theme,
) -> String {
  if line.has_prefix("error") ||
    line.has_prefix("warning") ||
    line.has_prefix("advice") {
    ansi_wrap(line, theme.severity(severity), theme.bold_header)
  } else if line.contains(" | ") && line.contains("^") {
    ansi_wrap(line, theme.primary, false)
  } else if line.contains(" | ") && line.contains("-") {
    ansi_wrap(line, theme.secondary, false)
  } else if line.contains("= help:") {
    ansi_wrap(line, theme.help, false)
  } else if line.contains("= note:") {
    ansi_wrap(line, theme.note, false)
  } else if line.contains(" |") || line.contains(" --> ") {
    ansi_wrap(line, theme.line_number, false)
  } else {
    line
  }
}

///|
/// Adds ANSI color to a plain report. When `enabled` is false, the output is
/// byte-for-byte identical to `render`.
pub fn render_ansi(
  sources : SourceMap,
  diagnostic : Diagnostic,
  enabled? : Bool = true,
  theme? : Theme = Theme::dark(),
  config? : RenderConfig = RenderConfig::default(),
) -> String {
  let plain = render(sources, diagnostic, config~)
  if !enabled {
    return plain
  }
  let output = StringBuilder::new()
  let lines = plain.split("\n")
  for index, line in lines {
    if index > 0 {
      output.write_char('\n')
    }
    output.write_string(
      colorize_report_line(line.to_owned(), diagnostic.severity(), theme),
    )
  }
  output.to_string()
}

///|
/// Removes common Select Graphic Rendition sequences emitted by MoonReport.
/// This is useful for snapshot tests and log sanitization.
pub fn strip_ansi(text : String) -> String {
  let bytes = @utf8.encode(text)
  let output = StringBuilder::new()
  let mut offset = 0
  while offset < bytes.length() {
    if bytes[offset] == 0x1b &&
      offset + 1 < bytes.length() &&
      bytes[offset + 1] == 0x5b {
      offset += 2
      while offset < bytes.length() && bytes[offset] != 0x6d {
        offset += 1
      }
      if offset < bytes.length() {
        offset += 1
      }
    } else {
      let count = utf8_sequence_length(bytes[offset])
      let end = if offset + count <= bytes.length() {
        offset + count
      } else {
        offset + 1
      }
      output.write_string(@utf8.decode_lossy(bytes[offset:end]))
      offset = end
    }
  }
  output.to_string()
}
