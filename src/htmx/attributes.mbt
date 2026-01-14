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
    Some(selector) =>
      match parse_extended_target(element, selector) {
        Some(target) => target
        None => element
      }
    None => element
  }
}

///|
/// FFI helpers for DOM traversal and string operations
extern "js" fn get_next_sibling(el : @dom.Element) -> @dom.Element? =
  #|(el) => { const next = el.nextElementSibling; return next ? { $tag: 1, _0: next } : { $tag: 0 }; }

///|
extern "js" fn get_previous_sibling(el : @dom.Element) -> @dom.Element? =
  #|(el) => { const prev = el.previousElementSibling; return prev ? { $tag: 1, _0: prev } : { $tag: 0 }; }

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
/// Parse extended target selector and return the target element (or None if not found)
fn parse_extended_target(
  element : @dom.Element,
  selector : String,
) -> @dom.Element? {
  log_debug_attr("parse_extended_target: selector = '" + selector + "'")
  if selector == "this" {
    log_debug_attr("parse_extended_target: this -> returning element")
    Some(element)
  } else if selector.has_prefix("closest ") {
    let css = substring_after(selector, 8)
    log_debug_attr("parse_extended_target: closest '" + css + "'")
    element.closest(css)
  } else if selector.has_prefix("find ") {
    let css = substring_after(selector, 5)
    log_debug_attr("parse_extended_target: find '" + css + "'")
    element.querySelector(css)
  } else if selector.has_prefix("next") {
    let rest = trim_string(substring_after(selector, 4))
    log_debug_attr("parse_extended_target: next with rest = '" + rest + "'")
    let result = find_next_sibling_opt(element, rest)
    match result {
      Some(_) => log_debug_attr("parse_extended_target: next found element")
      None => log_debug_attr("parse_extended_target: next NOT found")
    }
    result
  } else if selector.has_prefix("previous") {
    let rest = trim_string(substring_after(selector, 8))
    log_debug_attr("parse_extended_target: previous with rest = '" + rest + "'")
    find_previous_sibling_opt(element, rest)
  } else {
    // Default CSS selector query on document
    log_debug_attr("parse_extended_target: default selector '" + selector + "'")
    @dom.document().querySelector(selector)
  }
}

///|
/// Find the next sibling element, optionally matching a selector (returns None if not found)
fn find_next_sibling_opt(
  element : @dom.Element,
  selector : String,
) -> @dom.Element? {
  match get_next_sibling(element) {
    Some(next) =>
      if selector == "" || element_matches(next, selector) {
        Some(next)
      } else {
        // Try next siblings until we find a match or run out
        find_next_matching_opt(next, selector)
      }
    Option::None => Option::None
  }
}

///|
/// Recursively find next matching sibling (returns None if not found)
fn find_next_matching_opt(
  element : @dom.Element,
  selector : String,
) -> @dom.Element? {
  match get_next_sibling(element) {
    Some(next) =>
      if selector == "" || element_matches(next, selector) {
        Some(next)
      } else {
        find_next_matching_opt(next, selector)
      }
    Option::None => Option::None
  }
}

///|
/// Find the previous sibling element, optionally matching a selector (returns None if not found)
fn find_previous_sibling_opt(
  element : @dom.Element,
  selector : String,
) -> @dom.Element? {
  match get_previous_sibling(element) {
    Some(prev) =>
      if selector == "" || element_matches(prev, selector) {
        Some(prev)
      } else {
        // Try previous siblings until we find a match or run out
        find_previous_matching_opt(prev, selector)
      }
    Option::None => Option::None
  }
}

///|
/// Recursively find previous matching sibling (returns None if not found)
fn find_previous_matching_opt(
  element : @dom.Element,
  selector : String,
) -> @dom.Element? {
  match get_previous_sibling(element) {
    Some(prev) =>
      if selector == "" || element_matches(prev, selector) {
        Some(prev)
      } else {
        find_previous_matching_opt(prev, selector)
      }
    Option::None => Option::None
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

///|
/// Split string by comma and trim each part
extern "js" fn split_by_comma(s : String) -> Array[String] =
  #|(s) => {
  #|  return s.split(',').map(str => str.trim());
  #|}

///|
/// Find multiple elements by comma-separated selector
pub fn find_targets_by_selector(
  element : @dom.Element,
  selector : String,
) -> Array[@dom.Element] {
  let parts = split_by_comma(selector)
  let results : Array[@dom.Element] = []
  for part in parts {
    if part != "" {
      match parse_extended_target(element, part) {
        Some(target) => results.push(target)
        None => ()
      }
    }
  }
  results
}

///|
/// Debug log for attributes (uses processor's log_debug)
extern "js" fn log_debug_attr(msg : String) -> Unit =
  #|(msg) => console.log("[htmx.mbt ATTR DEBUG] " + msg)

///|
/// Get the hx-disabled-elt value (checks both hx-disabled-elt and data-hx-disabled-elt)
pub fn get_disabled_elt(element : @dom.Element) -> String? {
  match element.getAttribute("hx-disabled-elt") {
    Some(value) => Some(value)
    Option::None =>
      match element.getAttribute("data-hx-disabled-elt") {
        Some(value) => Some(value)
        Option::None => Option::None
      }
  }
}

///|
/// Get the hx-indicator value (checks both hx-indicator and data-hx-indicator)
pub fn get_indicator(element : @dom.Element) -> String? {
  match element.getAttribute("hx-indicator") {
    Some(value) => Some(value)
    Option::None =>
      match element.getAttribute("data-hx-indicator") {
        Some(value) => Some(value)
        Option::None => Option::None
      }
  }
}

///|
/// Get parent element using FFI
extern "js" fn get_parent_element(el : @dom.Element) -> @dom.Element? =
  #|(el) => { const parent = el.parentElement; return parent ? { $tag: 1, _0: parent } : { $tag: 0 }; }

///|
/// Resolve inherit keyword in indicator selector
/// Expands 'inherit' with parent's hx-indicator value recursively
fn resolve_inherit(element : @dom.Element, selector : String) -> String {
  log_debug_attr("resolve_inherit: selector = '" + selector + "'")
  let parts = split_by_comma(selector)
  let results : Array[String] = []
  for part in parts {
    log_debug_attr(
      "resolve_inherit: part = '" +
      part +
      "', trim = '" +
      trim_string(part) +
      "'",
    )
    if part == "inherit" {
      log_debug_attr(
        "resolve_inherit: part is inherit, calling resolve_inherit_from_parent",
      )
      // Walk up parent chain to find hx-indicator
      match resolve_inherit_from_parent(element) {
        Some(inherited) => {
          log_debug_attr("resolve_inherit: inherited = '" + inherited + "'")
          // Add inherited selectors
          let inherited_parts = split_by_comma(inherited)
          for p in inherited_parts {
            if p != "" {
              results.push(p)
            }
          }
        }
        Option::None => log_debug_attr("resolve_inherit: inherited is None")
      }
    } else if part != "" {
      results.push(part)
    }
  }
  let result = join_with_comma(results)
  log_debug_attr("resolve_inherit: result = '" + result + "'")
  result
}

///|
/// Recursively resolve inherit from parent elements
/// Returns None if no parent has hx-indicator (chain breaks)
fn resolve_inherit_from_parent(element : @dom.Element) -> String? {
  // Get parent element
  match get_parent_element(element) {
    Some(parent) => {
      log_debug_attr("resolve_inherit_from_parent: found parent")
      // Use closest to find parent with hx-indicator (including parent itself)
      match parent.closest("[hx-indicator], [data-hx-indicator]") {
        Some(indicator_owner) => {
          log_debug_attr(
            "resolve_inherit_from_parent: closest found indicator_owner",
          )
          match get_indicator(indicator_owner) {
            Some(selector) => {
              log_debug_attr(
                "resolve_inherit_from_parent: selector = '" + selector + "'",
              )
              // Check if selector also has inherit
              if selector.contains("inherit") {
                // Recursively resolve inherit from indicator owner's parent
                match resolve_inherit_from_parent(indicator_owner) {
                  Some(inherited) =>
                    Some(combine_selectors(inherited, selector))
                  None => Some(extract_non_inherit(selector))
                }
              } else {
                Some(selector)
              }
            }
            None => None
          }
        }
        None => {
          log_debug_attr(
            "resolve_inherit_from_parent: closest not found, trying grandparent",
          )
          // No indicator found in parent's ancestry, try grandparent
          resolve_inherit_from_parent(parent)
        }
      }
    }
    None => {
      log_debug_attr("resolve_inherit_from_parent: no parent found")
      None
    }
  }
}

///|
/// Combine two selector strings, handling inherit in the second selector
fn combine_selectors(base : String, with_inherit : String) -> String {
  let parts = split_by_comma(with_inherit)
  let results : Array[String] = []
  for part in parts {
    if part == "inherit" {
      // Expand with base selectors
      let base_parts = split_by_comma(base)
      for bp in base_parts {
        if bp != "" {
          results.push(bp)
        }
      }
    } else if part != "" {
      results.push(part)
    }
  }
  join_with_comma(results)
}

///|
/// Extract non-inherit parts from a selector string
fn extract_non_inherit(selector : String) -> String {
  let parts = split_by_comma(selector)
  let results : Array[String] = []
  for part in parts {
    if part != "inherit" && part != "" {
      results.push(part)
    }
  }
  join_with_comma(results)
}

///|
/// Join array of strings with comma
extern "js" fn join_with_comma(arr : Array[String]) -> String =
  #|(arr) => arr.filter(s => s !== "").join(", ")

///|
/// Get indicator selector with inherit resolution
/// If element doesn't have hx-indicator, searches parent elements
pub fn get_indicator_with_inherit(element : @dom.Element) -> String? {
  match get_indicator(element) {
    Some(selector) => Some(resolve_inherit(element, selector))
    None =>
      // Element doesn't have hx-indicator, try parent
      match get_parent_element(element) {
        Some(parent) => get_indicator_with_inherit(parent)
        None => None
      }
  }
}

///|
/// Find the element that has hx-indicator attribute
/// Returns the element that owns the indicator selector
/// Uses closest to find any ancestor with hx-indicator
fn find_indicator_owner(element : @dom.Element) -> (@dom.Element, String)? {
  // First check if element itself has hx-indicator
  match get_indicator(element) {
    Some(selector) => Some((element, selector))
    None =>
      // Use closest to find ancestor with hx-indicator
      // This searches element itself and all ancestors
      match element.closest("[hx-indicator], [data-hx-indicator]") {
        Some(owner) =>
          // Get the indicator value from the owner
          match get_indicator(owner) {
            Some(selector) => Some((owner, selector))
            None => None
          }
        None => None
      }
  }
}

///|
/// Get indicator elements with inherit resolution
/// Returns array of indicator elements, searching parent elements if needed
pub fn get_indicator_elements(element : @dom.Element) -> Array[@dom.Element] {
  match find_indicator_owner(element) {
    Some((owner, selector)) => {
      log_debug_attr(
        "get_indicator_elements: found owner with selector '" + selector + "'",
      )
      // Resolve inherit in selector
      let resolved = resolve_inherit(owner, selector)
      log_debug_attr(
        "get_indicator_elements: resolved selector '" + resolved + "'",
      )
      // Find targets relative to the owner of hx-indicator
      let result = find_targets_by_selector(owner, resolved)
      log_debug_attr(
        "get_indicator_elements: found " +
        result.length().to_string() +
        " targets",
      )
      // If no targets found, fall back to element itself
      if result.length() == 0 {
        [element]
      } else {
        result
      }
    }
    None => {
      log_debug_attr(
        "get_indicator_elements: no indicator found, using element itself",
      )
      [element]
    }
  }
}
