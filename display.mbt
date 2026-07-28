///|
/// Rendering policy for tabs and non-ASCII source text.
pub struct DisplayConfig {
  tab_width : Int
  ambiguous_width : Int
} derive(Eq, Debug)

///|
pub fn DisplayConfig::default() -> DisplayConfig {
  { tab_width: 4, ambiguous_width: 1 }
}

///|
pub fn DisplayConfig::new(
  tab_width : Int,
  ambiguous_width : Int,
) -> DisplayConfig {
  {
    tab_width: if tab_width < 1 {
      1
    } else {
      tab_width
    },
    ambiguous_width: if ambiguous_width == 2 {
      2
    } else {
      1
    },
  }
}

///|
pub fn DisplayConfig::tab_width(self : DisplayConfig) -> Int {
  self.tab_width
}

///|
fn utf8_sequence_length(first : Byte) -> Int {
  let value = first.to_int()
  if value < 0x80 {
    1
  } else if value < 0xe0 {
    2
  } else if value < 0xf0 {
    3
  } else {
    4
  }
}

///|
fn decode_code_point(bytes : Bytes, offset : Int) -> (Int, Int) {
  let first = bytes[offset].to_int()
  let count = utf8_sequence_length(bytes[offset])
  if count == 1 || offset + count > bytes.length() {
    return (first, 1)
  }
  let mut value = first & (0x7f >> count)
  let mut index = 1
  while index < count {
    let next = bytes[offset + index].to_int()
    if (next & 0xc0) != 0x80 {
      return (0xfffd, 1)
    }
    value = (value << 6) | (next & 0x3f)
    index += 1
  }
  (value, count)
}

///|
fn is_combining(code : Int) -> Bool {
  (code >= 0x0300 && code <= 0x036f) ||
  (code >= 0x1ab0 && code <= 0x1aff) ||
  (code >= 0x1dc0 && code <= 0x1dff) ||
  (code >= 0x20d0 && code <= 0x20ff) ||
  (code >= 0xfe00 && code <= 0xfe0f) ||
  (code >= 0xfe20 && code <= 0xfe2f) ||
  code == 0x200d
}

///|
fn is_wide(code : Int) -> Bool {
  code >= 0x1100 &&
  (
    code <= 0x115f ||
    code == 0x2329 ||
    code == 0x232a ||
    (code >= 0x2e80 && code <= 0xa4cf && code != 0x303f) ||
    (code >= 0xac00 && code <= 0xd7a3) ||
    (code >= 0xf900 && code <= 0xfaff) ||
    (code >= 0xfe10 && code <= 0xfe19) ||
    (code >= 0xfe30 && code <= 0xfe6f) ||
    (code >= 0xff00 && code <= 0xff60) ||
    (code >= 0xffe0 && code <= 0xffe6) ||
    (code >= 0x1f300 && code <= 0x1faff) ||
    (code >= 0x20000 && code <= 0x3fffd)
  )
}

///|
fn is_ambiguous(code : Int) -> Bool {
  (code >= 0x00a1 && code <= 0x00ff) ||
  (code >= 0x2010 && code <= 0x2027) ||
  (code >= 0x2190 && code <= 0x21ff) ||
  (code >= 0x2460 && code <= 0x24ff) ||
  (code >= 0x2500 && code <= 0x259f)
}

///|
fn code_point_width(code : Int, config : DisplayConfig) -> Int {
  if code == 0 || is_combining(code) {
    0
  } else if code < 0x20 || (code >= 0x7f && code < 0xa0) {
    0
  } else if is_wide(code) {
    2
  } else if is_ambiguous(code) {
    config.ambiguous_width
  } else {
    1
  }
}

///|
/// Returns the number of terminal cells occupied by UTF-8 text.
pub fn display_width(
  text : String,
  config? : DisplayConfig = DisplayConfig::default(),
) -> Int {
  let bytes = @utf8.encode(text)
  let mut column = 0
  let mut offset = 0
  while offset < bytes.length() {
    if bytes[offset] == 9 {
      column += config.tab_width - column % config.tab_width
      offset += 1
    } else {
      let (code, count) = decode_code_point(bytes, offset)
      column += code_point_width(code, config)
      offset += count
    }
  }
  column
}

///|
/// Converts a UTF-8 byte offset into a terminal-cell column.
pub fn display_column(
  text : String,
  byte_offset : Int,
  config? : DisplayConfig = DisplayConfig::default(),
) -> Int {
  let bytes = @utf8.encode(text)
  let limit = if byte_offset < 0 {
    0
  } else if byte_offset > bytes.length() {
    bytes.length()
  } else {
    byte_offset
  }
  let mut column = 0
  let mut offset = 0
  while offset < limit {
    if bytes[offset] == 9 {
      column += config.tab_width - column % config.tab_width
      offset += 1
    } else {
      let (code, count) = decode_code_point(bytes, offset)
      column += code_point_width(code, config)
      offset += count
    }
  }
  column
}

///|
/// Replaces tabs with spaces while preserving tab-stop alignment.
pub fn expand_tabs(
  text : String,
  config? : DisplayConfig = DisplayConfig::default(),
) -> String {
  let bytes = @utf8.encode(text)
  let output = StringBuilder::new()
  let mut column = 0
  let mut offset = 0
  while offset < bytes.length() {
    if bytes[offset] == 9 {
      let count = config.tab_width - column % config.tab_width
      let mut spaces = 0
      while spaces < count {
        output.write_char(' ')
        spaces += 1
      }
      column += count
      offset += 1
    } else {
      let (code, count) = decode_code_point(bytes, offset)
      output.write_string(@utf8.decode_lossy(bytes[offset:offset + count]))
      column += code_point_width(code, config)
      offset += count
    }
  }
  output.to_string()
}
