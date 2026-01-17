///|
/// SSE specification for hx-sse attribute
pub struct SseSpec {
  connect_url : String?
  swap_events : Array[String]
}

///|
/// Get substring after a given position
extern "js" fn substring_after_attr(s : String, start : Int) -> String =
  #|(s, start) => { return s.substring(start); }

///|
/// Split SSE attribute value by spaces
extern "js" fn split_sse_value(value : String) -> Array[String] =
  #|(value) => {
  #|  if (!value) return [];
  #|  return value.split(/\s+/).filter(s => s.length > 0);
  #|}

///|
/// Parse hx-sse attribute value into SseSpec
/// Syntax: "connect:<url> swap:<event1> swap:<event2>"
pub fn parse_sse_attr(value : String) -> SseSpec {
  let parts = split_sse_value(value)
  let mut connect_url = Option::None
  let mut swap_events = Array::new()

  // Parse each part
  let mut index = 0
  while index < parts.length() {
    let part = parts[index]
    if part.has_prefix("connect:") {
      connect_url = Option::Some(substring_after_attr(part, 8))
    } else if part.has_prefix("swap:") {
      swap_events = append_event(swap_events, substring_after_attr(part, 5))
    }
    index = index + 1
  }
  { connect_url, swap_events }
}

///|
/// Append an event to the events array
extern "js" fn append_event(
  events : Array[String],
  event : String,
) -> Array[String] =
  #|(events, event) => {
  #|  const result = events.slice();
  #|  result.push(event);
  #|  return result;
  #|}

///|
/// Get SSE spec from element (checks both hx-sse and data-hx-sse)
pub fn get_sse_spec(element : @dom.Element) -> SseSpec? {
  match element.getAttribute("hx-sse") {
    Option::Some(value) => Option::Some(parse_sse_attr(value))
    Option::None =>
      match element.getAttribute("data-hx-sse") {
        Option::Some(value) => Option::Some(parse_sse_attr(value))
        Option::None => Option::None
      }
  }
}

///|
/// Check if element has hx-sse attribute
pub fn has_sse_attribute(element : @dom.Element) -> Bool {
  match element.getAttribute("hx-sse") {
    Option::Some(_) => true
    Option::None => element.getAttribute("data-hx-sse") is Option::Some(_)
  }
}

///|
/// Find the closest parent with hx-sse attribute
pub fn find_sse_parent(element : @dom.Element) -> @dom.Element? {
  if has_sse_attribute(element) {
    Option::Some(element)
  } else {
    match element.parentElement() {
      Option::Some(parent) => find_sse_parent(parent)
      Option::None => Option::None
    }
  }
}
