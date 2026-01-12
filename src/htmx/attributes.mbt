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
/// Get data-hx-* prefixed version of an attribute
fn with_data_prefix(attr : String) -> String {
  "data-" + attr
}

///|
/// Find the method attribute and URL from an element (checks both hx-* and data-hx-*)
pub fn find_method_url(element : @dom.Element) -> (HttpMethod, String)? {
  let methods = get_hx_methods()
  for method_attr in methods {
    // Check hx-* attribute
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
    // Check data-hx-* attribute
    let data_attr = with_data_prefix(method_attr)
    if element.hasAttribute(data_attr) {
      match element.getAttribute(data_attr) {
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
/// Get the target element for an htmx element (checks both hx-target and data-hx-target)
/// Supports extended selectors: this, closest <selector>, find <selector>, next, next <selector>, previous, previous <selector>
pub fn get_target(element : @dom.Element) -> @dom.Element {
  // First try hx-target, then data-hx-target
  let target_attr = hx_target()
  let result = match element.getAttribute(target_attr) {
    Some(selector) => Some(selector)
    Option::None => element.getAttribute(with_data_prefix(target_attr))
  }
  match result {
    Some(selector) => parse_extended_target(element, selector)
    Option::None => element
  }
}

///|
/// FFI helpers for DOM traversal and string operations
extern "js" fn get_next_sibling(el : @dom.Element) -> @dom.Element? =
  #|(el) => { let next = el.nextElementSibling; return next || null; }

///|
extern "js" fn get_previous_sibling(el : @dom.Element) -> @dom.Element? =
  #|(el) => { let prev = el.previousElementSibling; return prev || null; }

///|
extern "js" fn element_matches(el : @dom.Element, sel : String) -> Bool =
  #|(el, sel) => { return el.matches(sel); }

///|
extern "js" fn substring_after(s : String, start : Int) -> String =
  #|(s, start) => { return s.substring(start); }

///|
extern "js" fn trim_string(s : String) -> String =
  #|(s) => { return s.trim(); }

///|
/// Parse extended target selector and return the target element
fn parse_extended_target(
  element : @dom.Element,
  selector : String,
) -> @dom.Element {
  if selector == "this" {
    element
  } else if selector.has_prefix("closest ") {
    let css = substring_after(selector, 8)
    match element.closest(css) {
      Some(target) => target
      Option::None => element
    }
  } else if selector.has_prefix("find ") {
    let css = substring_after(selector, 5)
    match element.querySelector(css) {
      Some(target) => target
      Option::None => element
    }
  } else if selector.has_prefix("next") {
    let rest = trim_string(substring_after(selector, 4))
    find_next_sibling(element, rest)
  } else if selector.has_prefix("previous") {
    let rest = trim_string(substring_after(selector, 8))
    find_previous_sibling(element, rest)
  } else {
    // Default CSS selector query on document
    match @dom.document().querySelector(selector) {
      Some(target) => target
      Option::None => element
    }
  }
}

///|
/// Find the next sibling element, optionally matching a selector
fn find_next_sibling(element : @dom.Element, selector : String) -> @dom.Element {
  match get_next_sibling(element) {
    Some(next) =>
      if selector == "" || element_matches(next, selector) {
        next
      } else {
        // Try next siblings until we find a match or run out
        find_next_matching(next, selector)
      }
    Option::None => element
  }
}

///|
/// Recursively find next matching sibling
fn find_next_matching(
  element : @dom.Element,
  selector : String,
) -> @dom.Element {
  match get_next_sibling(element) {
    Some(next) =>
      if selector == "" || element_matches(next, selector) {
        next
      } else {
        find_next_matching(next, selector)
      }
    Option::None => element
  }
}

///|
/// Find the previous sibling element, optionally matching a selector
fn find_previous_sibling(
  element : @dom.Element,
  selector : String,
) -> @dom.Element {
  match get_previous_sibling(element) {
    Some(prev) =>
      if selector == "" || element_matches(prev, selector) {
        prev
      } else {
        // Try previous siblings until we find a match or run out
        find_previous_matching(prev, selector)
      }
    Option::None => element
  }
}

///|
/// Recursively find previous matching sibling
fn find_previous_matching(
  element : @dom.Element,
  selector : String,
) -> @dom.Element {
  match get_previous_sibling(element) {
    Some(prev) =>
      if selector == "" || element_matches(prev, selector) {
        prev
      } else {
        find_previous_matching(prev, selector)
      }
    Option::None => element
  }
}

///|
/// Get the swap style for an htmx element (checks both hx-swap and data-hx-swap)
pub fn get_swap_style(element : @dom.Element) -> SwapStyle {
  let swap_attr = hx_swap()
  match element.getAttribute(swap_attr) {
    Some(value) => SwapStyle::parse(value)
    Option::None =>
      match element.getAttribute(with_data_prefix(swap_attr)) {
        Some(value) => SwapStyle::parse(value)
        Option::None => SwapStyle::InnerHTML
      }
  }
}

///|
/// Get the trigger event for an element (checks both hx-trigger and data-hx-trigger)
pub fn get_trigger_event(element : @dom.Element) -> String {
  let trigger_attr = hx_trigger()
  let result = match element.getAttribute(trigger_attr) {
    Some(value) => Some(value)
    Option::None => element.getAttribute(with_data_prefix(trigger_attr))
  }
  match result {
    Some(trigger) =>
      // Simple parsing - just get the event name before any space/modifier
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
/// Find closest htmx element from event target (checks both hx-* and data-hx-*)
pub fn find_htmx_element(element : @dom.Element) -> @dom.Element? {
  // Check current element
  let methods = get_hx_methods()
  for method_attr in methods {
    if element.hasAttribute(method_attr) {
      return Some(element)
    }
    let data_attr = with_data_prefix(method_attr)
    if element.hasAttribute(data_attr) {
      return Some(element)
    }
  }
  // Check ancestors with CSS selector (hx-* only, but data-hx-* is handled by our loop)
  element.closest(
    "[hx-get], [hx-post], [hx-put], [hx-delete], [hx-patch], [data-hx-get], [data-hx-post], [data-hx-put], [data-hx-delete], [data-hx-patch]",
  )
}

///|
/// Get the selector for the content to be swapped from the response (checks both hx-select and data-hx-select)
pub fn get_select(element : @dom.Element) -> String? {
  match element.getAttribute("hx-select") {
    Some(value) => Some(value)
    Option::None => element.getAttribute("data-hx-select")
  }
}

///|
/// Get push URL value (checks both hx-push-url and data-hx-push-url)
pub fn get_push_url(element : @dom.Element) -> String? {
  match element.getAttribute("hx-push-url") {
    Some(value) => Some(value)
    Option::None => element.getAttribute("data-hx-push-url")
  }
}
