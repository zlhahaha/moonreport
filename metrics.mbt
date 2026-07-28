///|
/// A stable count associated with one diagnostic code.
pub struct CodeCount {
  code : String
  count : Int
} derive(Eq, Debug)

///|
pub fn CodeCount::code(self : CodeCount) -> String {
  self.code
}

///|
pub fn CodeCount::count(self : CodeCount) -> Int {
  self.count
}

///|
/// A stable count associated with one source.
pub struct SourceCount {
  source : SourceId
  diagnostics : Int
  labels : Int
} derive(Eq, Debug)

///|
pub fn SourceCount::source(self : SourceCount) -> SourceId {
  self.source
}

///|
pub fn SourceCount::diagnostics(self : SourceCount) -> Int {
  self.diagnostics
}

///|
pub fn SourceCount::labels(self : SourceCount) -> Int {
  self.labels
}

///|
/// Aggregate information for dashboards, CI summaries, and batch reports.
///
/// Code and source groups preserve first-seen order, which makes output stable
/// without imposing a sorting policy on callers.
pub struct DiagnosticMetrics {
  summary : Summary
  coded : Int
  labels : Int
  primary_labels : Int
  secondary_labels : Int
  code_counts : Array[CodeCount]
  source_counts : Array[SourceCount]
} derive(Eq, Debug)

///|
pub fn DiagnosticMetrics::summary(self : DiagnosticMetrics) -> Summary {
  self.summary
}

///|
pub fn DiagnosticMetrics::coded(self : DiagnosticMetrics) -> Int {
  self.coded
}

///|
pub fn DiagnosticMetrics::uncoded(self : DiagnosticMetrics) -> Int {
  self.summary.total() - self.coded
}

///|
pub fn DiagnosticMetrics::labels(self : DiagnosticMetrics) -> Int {
  self.labels
}

///|
pub fn DiagnosticMetrics::primary_labels(self : DiagnosticMetrics) -> Int {
  self.primary_labels
}

///|
pub fn DiagnosticMetrics::secondary_labels(self : DiagnosticMetrics) -> Int {
  self.secondary_labels
}

///|
pub fn DiagnosticMetrics::code_counts(
  self : DiagnosticMetrics,
) -> Array[CodeCount] {
  self.code_counts.copy()
}

///|
pub fn DiagnosticMetrics::source_counts(
  self : DiagnosticMetrics,
) -> Array[SourceCount] {
  self.source_counts.copy()
}

///|
pub fn DiagnosticMetrics::unique_codes(self : DiagnosticMetrics) -> Int {
  self.code_counts.length()
}

///|
pub fn DiagnosticMetrics::unique_sources(self : DiagnosticMetrics) -> Int {
  self.source_counts.length()
}

///|
pub fn DiagnosticMetrics::count_for_code(
  self : DiagnosticMetrics,
  code : String,
) -> Int {
  for item in self.code_counts {
    if item.code() == code {
      return item.count()
    }
  }
  0
}

///|
pub fn DiagnosticMetrics::diagnostics_for_source(
  self : DiagnosticMetrics,
  source : SourceId,
) -> Int {
  for item in self.source_counts {
    if item.source() == source {
      return item.diagnostics()
    }
  }
  0
}

///|
pub fn DiagnosticMetrics::labels_for_source(
  self : DiagnosticMetrics,
  source : SourceId,
) -> Int {
  for item in self.source_counts {
    if item.source() == source {
      return item.labels()
    }
  }
  0
}

///|
fn increment_code(counts : Array[CodeCount], code : String) -> Unit {
  for index, item in counts {
    if item.code() == code {
      counts[index] = { code, count: item.count() + 1 }
      return
    }
  }
  counts.push({ code, count: 1 })
}

///|
fn find_source(counts : Array[SourceCount], source : SourceId) -> Int? {
  for index, item in counts {
    if item.source() == source {
      return Some(index)
    }
  }
  None
}

///|
fn record_source_diagnostic(
  counts : Array[SourceCount],
  source : SourceId,
) -> Unit {
  match find_source(counts, source) {
    Some(index) => {
      let current = counts[index]
      counts[index] = {
        source,
        diagnostics: current.diagnostics() + 1,
        labels: current.labels(),
      }
    }
    None => counts.push({ source, diagnostics: 1, labels: 0 })
  }
}

///|
fn record_source_label(counts : Array[SourceCount], source : SourceId) -> Unit {
  match find_source(counts, source) {
    Some(index) => {
      let current = counts[index]
      counts[index] = {
        source,
        diagnostics: current.diagnostics(),
        labels: current.labels() + 1,
      }
    }
    None => counts.push({ source, diagnostics: 0, labels: 1 })
  }
}

///|
/// Computes metrics without changing the bag or its diagnostics.
///
/// A diagnostic contributes at most once to a source's diagnostic count, even
/// when it has several labels in that source. Every label still contributes to
/// the corresponding label count.
pub fn DiagnosticBag::metrics(self : DiagnosticBag) -> DiagnosticMetrics {
  let code_counts : Array[CodeCount] = []
  let source_counts : Array[SourceCount] = []
  let mut coded = 0
  let mut labels = 0
  let mut primary_labels = 0
  let mut secondary_labels = 0
  for diagnostic in self.to_array() {
    match diagnostic.code() {
      Some(code) => {
        coded += 1
        increment_code(code_counts, code)
      }
      None => ()
    }
    let seen_sources : Array[SourceId] = []
    for label in diagnostic.labels() {
      labels += 1
      if label.is_primary() {
        primary_labels += 1
      } else {
        secondary_labels += 1
      }
      record_source_label(source_counts, label.source())
      if !seen_sources.any(fn(source) { source == label.source() }) {
        seen_sources.push(label.source())
        record_source_diagnostic(source_counts, label.source())
      }
    }
  }
  {
    summary: self.summary(),
    coded,
    labels,
    primary_labels,
    secondary_labels,
    code_counts,
    source_counts,
  }
}
