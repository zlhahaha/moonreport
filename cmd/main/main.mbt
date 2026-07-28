///|
fn main {
  let text =
    #|[server]
    #|host = "127.0.0.1"
    #|port = 70000
  let sources = @report.SourceMap::new()
  let source_id = sources.add("app.conf", text)
  // A parser normally supplies this UTF-8 byte range with the failed token.
  let port_start = 35
  let diagnostic = @report.Diagnostic::new(
      Error,
      "port must be between 1 and 65535",
    )
    .with_code("CFG002")
    .with_label(
      @report.Label::primary(
        source_id,
        @report.Span::new(port_start, port_start + 5).unwrap(),
        "70000 is outside the valid TCP port range",
      ),
    )
    .with_note("configuration values are checked before the server starts")
    .with_help("choose an unused port such as 8080")
  println(@report.render_ansi(sources, diagnostic))
}
