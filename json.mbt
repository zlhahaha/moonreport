///|
/// Escapes a string for embedding in JSON while preserving valid UTF-8.
fn hex_digit(value : Byte) -> Char {
  match value {
    0 => '0'
    1 => '1'
    2 => '2'
    3 => '3'
    4 => '4'
    5 => '5'
    6 => '6'
    7 => '7'
    8 => '8'
    9 => '9'
    10 => 'a'
    11 => 'b'
    12 => 'c'
    13 => 'd'
    14 => 'e'
    _ => 'f'
  }
}

///|
/// Escapes a string for embedding in JSON while preserving valid UTF-8.
fn write_json_string(output : StringBuilder, text : String) -> Unit {
  let bytes = @utf8.encode(text)
  output.write_char('"')
  let mut offset = 0
  while offset < bytes.length() {
    let byte = bytes[offset]
    match byte {
      0x22 => {
        output.write_string("\\\"")
        offset += 1
      }
      0x5c => {
        output.write_string("\\\\")
        offset += 1
      }
      0x08 => {
        output.write_string("\\b")
        offset += 1
      }
      0x0c => {
        output.write_string("\\f")
        offset += 1
      }
      0x0a => {
        output.write_string("\\n")
        offset += 1
      }
      0x0d => {
        output.write_string("\\r")
        offset += 1
      }
      0x09 => {
        output.write_string("\\t")
        offset += 1
      }
      _ =>
        if byte < 0x20 {
          output.write_string("\\u00")
          output.write_char(hex_digit(byte / 16))
          output.write_char(hex_digit(byte % 16))
          offset += 1
        } else {
          let count = utf8_sequence_length(byte)
          let end = if offset + count <= bytes.length() {
            offset + count
          } else {
            offset + 1
          }
          output.write_string(@utf8.decode_lossy(bytes[offset:end]))
          offset = end
        }
    }
  }
  output.write_char('"')
}

///|
fn write_optional_json_string(output : StringBuilder, value : String?) -> Unit {
  match value {
    Some(text) => write_json_string(output, text)
    None => output.write_string("null")
  }
}

///|
fn write_json_string_array(
  output : StringBuilder,
  values : Array[String],
) -> Unit {
  output.write_char('[')
  for index, value in values {
    if index > 0 {
      output.write_char(',')
    }
    write_json_string(output, value)
  }
  output.write_char(']')
}

///|
fn write_json_label(
  output : StringBuilder,
  sources : SourceMap,
  label : Label,
) -> Unit {
  output.write_string("{\"source_id\":")
  output.write_string(label.source().value().to_string())
  output.write_string(",\"source_name\":")
  match sources.get(label.source()) {
    Some(source) => write_json_string(output, source.name())
    None => output.write_string("null")
  }
  output.write_string(",\"start\":")
  output.write_string(label.span().start().to_string())
  output.write_string(",\"end\":")
  output.write_string(label.span().end().to_string())
  output.write_string(",\"primary\":")
  output.write_string(if label.is_primary() { "true" } else { "false" })
  output.write_string(",\"message\":")
  write_json_string(output, label.message())
  match sources.get(label.source()) {
    Some(source) => {
      let start = source.location(label.span().start())
      let end = source.location(label.span().end())
      output.write_string(",\"start_line\":")
      output.write_string((start.line() + 1).to_string())
      output.write_string(",\"start_column\":")
      output.write_string((start.column() + 1).to_string())
      output.write_string(",\"end_line\":")
      output.write_string((end.line() + 1).to_string())
      output.write_string(",\"end_column\":")
      output.write_string((end.column() + 1).to_string())
    }
    None => ()
  }
  output.write_char('}')
}

///|
/// Serializes one diagnostic to a stable, compact JSON object.
///
/// Byte offsets are zero-based. Human-facing line and column values are
/// one-based. Unknown source IDs remain representable with a null name.
pub fn render_json(sources : SourceMap, diagnostic : Diagnostic) -> String {
  let output = StringBuilder::new()
  output.write_string("{\"severity\":")
  write_json_string(output, diagnostic.severity().name())
  output.write_string(",\"message\":")
  write_json_string(output, diagnostic.message())
  output.write_string(",\"code\":")
  write_optional_json_string(output, diagnostic.code())
  output.write_string(",\"help\":")
  write_optional_json_string(output, diagnostic.help())
  output.write_string(",\"notes\":")
  write_json_string_array(output, diagnostic.notes())
  output.write_string(",\"labels\":[")
  for index, label in diagnostic.labels() {
    if index > 0 {
      output.write_char(',')
    }
    write_json_label(output, sources, label)
  }
  output.write_string("]}")
  output.to_string()
}

///|
/// Emits newline-delimited JSON for streaming into editors and CI systems.
pub fn render_json_lines(
  sources : SourceMap,
  diagnostics : Array[Diagnostic],
) -> String {
  let output = StringBuilder::new()
  for index, diagnostic in diagnostics {
    if index > 0 {
      output.write_char('\n')
    }
    output.write_string(render_json(sources, diagnostic))
  }
  output.to_string()
}
