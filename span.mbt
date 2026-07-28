///|
/// A half-open byte range in a source file.
pub struct Span {
  start : Int
  end : Int
} derive(Eq, Debug)

///|
/// Creates a span when both offsets are non-negative and ordered.
pub fn Span::new(start : Int, end : Int) -> Span? {
  if start < 0 || end < start {
    None
  } else {
    Some({ start, end })
  }
}

///|
pub fn Span::at(offset : Int) -> Span? {
  Span::new(offset, offset)
}

///|
pub fn Span::start(self : Span) -> Int {
  self.start
}

///|
pub fn Span::end(self : Span) -> Int {
  self.end
}

///|
pub fn Span::length(self : Span) -> Int {
  self.end - self.start
}

///|
pub fn Span::is_empty(self : Span) -> Bool {
  self.start == self.end
}

///|
pub fn Span::contains(self : Span, offset : Int) -> Bool {
  self.start <= offset && offset < self.end
}

///|
pub fn Span::touches(self : Span, other : Span) -> Bool {
  self.start <= other.end && other.start <= self.end
}

///|
pub fn Span::intersects(self : Span, other : Span) -> Bool {
  self.start < other.end && other.start < self.end
}

///|
pub fn Span::cover(self : Span, other : Span) -> Span {
  {
    start: if self.start < other.start {
      self.start
    } else {
      other.start
    },
    end: if self.end > other.end {
      self.end
    } else {
      other.end
    },
  }
}

///|
pub fn Span::clamp(self : Span, length : Int) -> Span {
  let upper = if length < 0 { 0 } else { length }
  let start = if self.start > upper { upper } else { self.start }
  let end = if self.end > upper { upper } else { self.end }
  { start, end: if end < start { start } else { end } }
}
