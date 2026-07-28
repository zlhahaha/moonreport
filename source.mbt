///|
/// A zero-based line and byte column.
pub struct Location {
  line : Int
  column : Int
  offset : Int
} derive(Eq, Debug)

///|
pub fn Location::line(self : Location) -> Int {
  self.line
}

///|
pub fn Location::column(self : Location) -> Int {
  self.column
}

///|
pub fn Location::offset(self : Location) -> Int {
  self.offset
}

///|
/// Immutable source text with a precomputed line-start index.
pub struct Source {
  name : String
  text : String
  bytes : Bytes
  line_starts : Array[Int]
}

///|
pub fn Source::new(name : String, text : String) -> Source {
  let bytes = @utf8.encode(text)
  let starts = [0]
  let mut index = 0
  while index < bytes.length() {
    if bytes[index] == 10 {
      starts.push(index + 1)
    }
    index += 1
  }
  { name, text, bytes, line_starts: starts }
}

///|
pub fn Source::name(self : Source) -> String {
  self.name
}

///|
pub fn Source::text(self : Source) -> String {
  self.text
}

///|
pub fn Source::byte_length(self : Source) -> Int {
  self.bytes.length()
}

///|
pub fn Source::line_count(self : Source) -> Int {
  self.line_starts.length()
}

///|
fn Source::line_index_at(self : Source, offset : Int) -> Int {
  let target = if offset < 0 {
    0
  } else if offset > self.bytes.length() {
    self.bytes.length()
  } else {
    offset
  }
  let mut low = 0
  let mut high = self.line_starts.length()
  while low + 1 < high {
    let middle = low + (high - low) / 2
    if self.line_starts[middle] <= target {
      low = middle
    } else {
      high = middle
    }
  }
  low
}

///|
pub fn Source::location(self : Source, offset : Int) -> Location {
  let bounded = if offset < 0 {
    0
  } else if offset > self.bytes.length() {
    self.bytes.length()
  } else {
    offset
  }
  let line = self.line_index_at(bounded)
  { line, column: bounded - self.line_starts[line], offset: bounded }
}

///|
pub fn Source::line_span(self : Source, line : Int) -> Span? {
  if line < 0 || line >= self.line_starts.length() {
    return None
  }
  let start = self.line_starts[line]
  let raw_end = if line + 1 < self.line_starts.length() {
    self.line_starts[line + 1]
  } else {
    self.bytes.length()
  }
  let mut end = raw_end
  if end > start && self.bytes[end - 1] == 10 {
    end -= 1
  }
  if end > start && self.bytes[end - 1] == 13 {
    end -= 1
  }
  Some({ start, end })
}

///|
pub fn Source::slice(self : Source, span : Span) -> String {
  let bounded = span.clamp(self.bytes.length())
  @utf8.decode_lossy(self.bytes[bounded.start():bounded.end()])
}

///|
pub fn Source::line_text(self : Source, line : Int) -> String? {
  match self.line_span(line) {
    Some(span) => Some(self.slice(span))
    None => None
  }
}
