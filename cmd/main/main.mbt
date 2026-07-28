///|
fn main {
  let source = @report.Source::new("demo.mbt", "let answer = 42")
  println(
    "moonreport: indexed \{source.line_count()} line from \{source.name()}",
  )
}
