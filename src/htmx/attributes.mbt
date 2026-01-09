///|
/// htmx attribute constants - using functions to avoid unused warnings
fn hx_trigger() -> String {
  "hx-trigger"
}

///|
fn hx_target() -> String {
  "hx-target"
}

///|
fn hx_swap() -> String {
  "hx-swap"
}

///|
/// All htmx method attributes for checking
fn get_hx_methods() -> Array[String] {
  ["hx-get", "hx-post", "hx-put", "hx-delete", "hx-patch"]
}

///|
/// Find the method attribute and URL from an element
pub fn find_method_url(element : @dom.Element) -> (HttpMethod, String)? {
  let methods = get_hx_methods()
  for method_attr in methods {
    if element.hasAttribute(method_attr) {
      match element.getAttribute(method_attr) {
        Some(url) =>
          match HttpMethod::from_attr(method_attr) {
            Some(m) => return Some((m, url))
            Option::None => continue
          }
        Option::None => continue
      }
    }
  }
  Option::None
}

///|
/// Get the target element for an htmx element
pub fn get_target(element : @dom.Element) -> @dom.Element {
  match element.getAttribute(hx_target()) {
    Some(selector) =>
      if selector == "this" {
        element
      } else {
        match @dom.document().querySelector(selector) {
          Some(target) => target
          Option::None => element
        }
      }
    Option::None => element
  }
}

///|
/// Get the swap style for an htmx element
pub fn get_swap_style(element : @dom.Element) -> SwapStyle {
  match element.getAttribute(hx_swap()) {
    Some(value) => SwapStyle::parse(value)
    Option::None => SwapStyle::InnerHTML
  }
}

///|
/// Get the trigger event for an element (defaults based on element type)
pub fn get_trigger_event(element : @dom.Element) -> String {
  match element.getAttribute(hx_trigger()) {
    Some(trigger) =>
      // Simple parsing - just get the event name before any space/modifier
      // Use contains check to see if there's a space
      if trigger.contains(" ") {
        // Find space and split manually
        let chars = trigger.to_array()
        let mut end_idx = chars.length()
        for i, c in chars {
          if c == ' ' {
            end_idx = i
            break
          }
        }
        String::from_array(chars[0:end_idx])
      } else {
        trigger
      }
    Option::None => get_default_trigger(element)
  }
}

///|
/// Get default trigger based on element tag name
fn get_default_trigger(element : @dom.Element) -> String {
  let tag = element.tagName().to_lower()
  match tag {
    "input" | "textarea" | "select" => "change"
    "form" => "submit"
    _ => "click"
  }
}

///|
/// Find closest htmx element from event target
pub fn find_htmx_element(element : @dom.Element) -> @dom.Element? {
  // Check current element
  let methods = get_hx_methods()
  for method_attr in methods {
    if element.hasAttribute(method_attr) {
      return Some(element)
    }
  }
  // Check ancestors
  element.closest("[hx-get], [hx-post], [hx-put], [hx-delete], [hx-patch]")
}
