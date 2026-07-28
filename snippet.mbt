///|
/// Inclusive source-line window selected for a diagnostic label.
pub struct LineWindow {
  first : Int
  last : Int
  focus_first : Int
  focus_last : Int
} derive(Eq, Debug)

///|
pub fn LineWindow::first(self : LineWindow) -> Int {
  self.first
}

///|
pub fn LineWindow::last(self : LineWindow) -> Int {
  self.last
}

///|
pub fn LineWindow::focus_first(self : LineWindow) -> Int {
  self.focus_first
}

///|
pub fn LineWindow::focus_last(self : LineWindow) -> Int {
  self.focus_last
}

///|
/// Selects a bounded context window around a span.
pub fn Source::window(
  self : Source,
  span : Span,
  context_lines? : Int = 2,
) -> LineWindow {
  let bounded = span.clamp(self.byte_length())
  let start = self.location(bounded.start()).line()
  let end_offset = if bounded.is_empty() {
    bounded.end()
  } else {
    bounded.end() - 1
  }
  let finish = self.location(end_offset).line()
  let context = if context_lines < 0 { 0 } else { context_lines }
  {
    first: if start > context {
      start - context
    } else {
      0
    },
    last: if finish + context < self.line_count() {
      finish + context
    } else {
      self.line_count() - 1
    },
    focus_first: start,
    focus_last: finish,
  }
}

///|
/// Merges windows that overlap or are separated by at most `gap` lines.
pub fn merge_windows(
  windows : Array[LineWindow],
  gap? : Int = 1,
) -> Array[LineWindow] {
  if windows.length() == 0 {
    return []
  }
  let sorted = windows.copy()
  sorted.sort_by(fn(a, b) { a.first.compare(b.first) })
  let output : Array[LineWindow] = []
  let allowed_gap = if gap < 0 { 0 } else { gap }
  for current in sorted {
    if output.length() == 0 {
      output.push(current)
      continue
    }
    let previous = output[output.length() - 1]
    if current.first <= previous.last + allowed_gap + 1 {
      output[output.length() - 1] = {
        first: previous.first,
        last: if current.last > previous.last {
          current.last
        } else {
          previous.last
        },
        focus_first: if current.focus_first < previous.focus_first {
          current.focus_first
        } else {
          previous.focus_first
        },
        focus_last: if current.focus_last > previous.focus_last {
          current.focus_last
        } else {
          previous.focus_last
        },
      }
    } else {
      output.push(current)
    }
  }
  output
}
