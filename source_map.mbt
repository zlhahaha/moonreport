///|
/// Registry that assigns stable IDs to source files used by diagnostics.
pub struct SourceMap {
  sources : Array[Source]
}

///|
pub fn SourceMap::new() -> SourceMap {
  { sources: [] }
}

///|
pub fn SourceMap::add(
  self : SourceMap,
  name : String,
  text : String,
) -> SourceId {
  let id = SourceId::new(self.sources.length()).unwrap()
  self.sources.push(Source::new(name, text))
  id
}

///|
pub fn SourceMap::length(self : SourceMap) -> Int {
  self.sources.length()
}

///|
pub fn SourceMap::is_empty(self : SourceMap) -> Bool {
  self.sources.length() == 0
}

///|
pub fn SourceMap::get(self : SourceMap, id : SourceId) -> Source? {
  let index = id.value()
  if index < 0 || index >= self.sources.length() {
    None
  } else {
    Some(self.sources[index])
  }
}

///|
pub fn SourceMap::find_by_name(self : SourceMap, name : String) -> SourceId? {
  for index, source in self.sources {
    if source.name() == name {
      return SourceId::new(index)
    }
  }
  None
}

///|
pub fn SourceMap::contains(self : SourceMap, id : SourceId) -> Bool {
  id.value() >= 0 && id.value() < self.sources.length()
}

///|
pub fn SourceMap::validate_label(self : SourceMap, label : Label) -> Bool {
  match self.get(label.source()) {
    None => false
    Some(source) => label.span().end() <= source.byte_length()
  }
}

///|
pub fn SourceMap::validate(self : SourceMap, diagnostic : Diagnostic) -> Bool {
  diagnostic.is_valid() &&
  diagnostic.labels().all(fn(label) { self.validate_label(label) })
}
