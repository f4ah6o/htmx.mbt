///|
/// Various attribute helpers for htmx

///|
/// Get substring after a given position
extern "js" fn substring_after(s : String, start : Int) -> String =
  #|(s, start) => { return s.substring(start); }

///|
/// Check if element matches CSS selector
extern "js" fn element_matches(el : @dom.Element, css : String) -> Bool =
  #|(el, css) => el.matches(css)

///|
/// Get attribute with data-hx- prefix fallback
pub fn get_attribute_with_prefix(elt : @dom.Element, attr : String) -> String? {
  let result = elt.getAttribute(attr)
  match result {
    Some(_) => result
    None => elt.getAttribute(with_data_prefix(attr))
  }
}

///|
/// Check if element has any htmx attribute
pub fn has_htmx_attribute(el : @dom.Element) -> Bool {
  let attrs = [
    "hx-get", "hx-post", "hx-put", "hx-delete", "hx-patch",
    "hx-trigger", "hx-target", "hx-swap", "hx-swap-oob",
    "hx-vals", "hx-vars", "hx-headers", "hx-include",
    "hx-params", "hx-encoding", "hx-confirm", "hx-prompt",
    "hx-disable", "hx-indicator", "hx-disabled-elt",
    "hx-push-url", "hx-select", "hx-select-oob",
    "hx-history-elt", "hx-boost", "hx-inherit",
    "hx-on", "hx-ext", "hx-validate", "hx-request",
    "hx-replace-url", "hx-disinherit", "hx-preserve"
  ]
  let mut index = 0
  while index < attrs.length() {
    let attr = attrs[index]
    match get_attribute_with_prefix(el, attr) {
      Some(_) => return true
      None => ()
    }
    index = index + 1
  }
  false
}

///|
pub fn with_data_prefix(s : String) -> String {
  "data-" + s
}

///|
pub fn hx_get() -> String { "hx-get" }

///|
pub fn hx_post() -> String { "hx-post" }

///|
pub fn hx_put() -> String { "hx-put" }

///|
pub fn hx_delete() -> String { "hx-delete" }

///|
pub fn hx_patch() -> String { "hx-patch" }

///|
/// Get all htmx method attribute names
pub fn get_hx_methods() -> Array[String] {
  ["hx-get", "hx-post", "hx-put", "hx-delete", "hx-patch"]
}

///|
pub fn hx_trigger() -> String { "hx-trigger" }

///|
pub fn hx_target() -> String { "hx-target" }

///|
pub fn hx_swap() -> String { "hx-swap" }

///|
pub fn hx_vals() -> String { "hx-vals" }

///|
pub fn hx_headers() -> String { "hx-headers" }

///|
pub fn hx_include() -> String { "hx-include" }

///|
pub fn hx_params() -> String { "hx-params" }

///|
pub fn hx_boost() -> String { "hx-boost" }

///|
pub fn hx_select() -> String { "hx-select" }

///|
pub fn hx_push_url() -> String { "hx-push-url" }

///|
pub fn hx_indicator() -> String { "hx-indicator" }

///|
pub fn hx_disabled_elt() -> String { "hx-disabled-elt" }

///|
pub fn hx_inherit() -> String { "hx-inherit" }

///|
pub fn hx_validate() -> String { "hx-validate" }

///|
extern "js" fn log_debug_attr(msg : String) -> Unit =
  #|(msg) => console.log("[htmx.mbt ATTR DEBUG] " + msg)

///|
/// Split string by comma
extern "js" fn split_by_comma(s : String) -> Array[String] =
  #|(s) => s.split(',').map(x => x.trim()).filter(x => x.length > 0)

///|
/// Parse extended target syntax (e.g., "closest div", "find .child", "this", etc.)
fn parse_extended_target(
  element : @dom.Element,
  selector : String,
) -> @dom.Element? {
  log_debug_attr("parse_extended_target: selector = '" + selector + "'")
  if selector == "this" {
    log_debug_attr("parse_extended_target: this -> returning element")
    Some(element)
  } else if selector.has_prefix("global ") {
    let css = substring_after(selector, 7)
    log_debug_attr("parse_extended_target: global '" + css + "'")
    @dom.document().querySelector(css)
  } else if selector.has_prefix("closest ") {
    let css = substring_after(selector, 8)
    log_debug_attr("parse_extended_target: closest '" + css + "'")
    element.closest(css)
  } else if selector.has_prefix("find ") {
    let css = substring_after(selector, 5)
    log_debug_attr("parse_extended_target: find '" + css + "'")
    element.querySelector(css)
  } else if selector.has_prefix("next") {
    parse_next_target(element, selector)
  } else {
    log_debug_attr("parse_extended_target: default querySelector '" + selector + "'")
    @dom.document().querySelector(selector)
  }
}

///|
/// Parse 'next' target syntax (e.g., "next", "next .sibling")
fn parse_next_target(element : @dom.Element, selector : String) -> @dom.Element? {
  log_debug_attr("parse_next_target: selector = '" + selector + "'")
  if selector == "next" {
    match element.nextElementSibling() {
      Some(el) => Some(el)
      None => None
    }
  } else {
    let css = substring_after(selector, 5)
    match element.nextElementSibling() {
      Some(next) => {
        if element_matches(next, css) {
          Some(next)
        } else {
          None
        }
      }
      None => None
    }
  }
}

///|
/// Get targets by selector (handles extended syntax like "closest", "find", "next", "global")
pub fn find_targets_by_selector(
  element : @dom.Element,
  selector : String,
) -> Array[@dom.Element] {
  log_debug_attr("find_targets_by_selector: selector = '" + selector + "'")
  if selector == "this" || selector == "window" {
    [element]
  } else if selector.has_prefix("closest ") {
    let css = substring_after(selector, 8)
    match element.closest(css) {
      Some(el) => [el]
      None => []
    }
  } else if selector.has_prefix("find ") {
    let css = substring_after(selector, 5)
    element.querySelectorAll(css)
  } else if selector.has_prefix("next") {
    match parse_next_target(element, selector) {
      Some(el) => [el]
      None => []
    }
  } else if selector.has_prefix("global ") {
    let css = substring_after(selector, 7)
    @dom.document().querySelectorAll(css)
  } else {
    @dom.document().querySelectorAll(selector)
  }
}

///|
/// Get parent element
extern "js" fn get_parent_element(el : @dom.Element) -> @dom.Element? =
  #|(el) => { const parent = el.parentElement; return parent ? { $tag: 1, _0: parent } : { $tag: 0 }; }

///|
/// Get hx-inherit attribute value (checks both hx-inherit and data-hx-inherit)
pub fn get_hx_inherit(el : @dom.Element) -> String? {
  get_attribute_with_prefix(el, hx_inherit())
}

///|
/// Parse hx-inherit value into array
fn parse_hx_inherit(value : String) -> Array[String] {
  let trimmed = value.trim().to_string()
  if trimmed == "all" {
    ["*"]
  } else if trimmed == "none" {
    []
  } else {
    split_by_comma(trimmed)
  }
}

///|
/// Get disableInheritance configuration
extern "js" fn get_disable_inheritance() -> Bool =
  #|() => {
  #|  try {
  #|    return window.htmx && window.htmx.config && window.htmx.config.disableInheritance === true;
  #|  } catch(e) {
  #|    return false;
  #|  }
  #|}

///|
/// Check if hx-inherit array contains '*' (inherit all)
extern "js" fn check_inherits_all(arr : Array[String]) -> Bool =
  #|(arr) => {
  #|  if (!arr || !Array.isArray(arr)) return false;
  #|  return arr.includes('*');
  #|}

///|
/// Check if hx-inherit array includes a specific attribute
extern "js" fn check_includes_attribute(arr : Array[String], attr : String) -> Bool =
  #|(arr, attr) => {
  #|  if (!arr || !Array.isArray(arr)) return false;
  #|  return arr.includes(attr);
  #|}

///|
/// Check if a specific attribute should be inherited from parent
/// Returns Some(value) if the attribute should be inherited, None otherwise
fn should_inherit_attribute(
  element : @dom.Element,
  attr_name : String,
) -> String? {
  // If disableInheritance is false, inheritance is enabled by default
  let disabled = get_disable_inheritance()
  if not(disabled) {
    // Inheritance is enabled by default, check parents
    return find_inherited_attribute(element, attr_name)
  }

  // Inheritance is disabled by default, only inherit if parent has hx-inherit
  find_inherited_attribute_with_check(element, attr_name)
}

///|
/// Find inherited attribute from parent (when disableInheritance = false)
fn find_inherited_attribute(
  element : @dom.Element,
  attr_name : String,
) -> String? {
  match get_parent_element(element) {
    Some(parent) =>
      // Check if parent has the attribute
      match parent.getAttribute(attr_name) {
        Some(value) => Some(value)
        Option::None => {
          // Check for data-hx-* prefix
          let data_attr = with_data_prefix(attr_name)
          match parent.getAttribute(data_attr) {
            Some(value) => Some(value)
            Option::None => find_inherited_attribute(parent, attr_name)
          }
        }
      }
    Option::None => Option::None
  }
}

///|
/// Find inherited attribute with hx-inherit check (when disableInheritance = true)
fn find_inherited_attribute_with_check(
  element : @dom.Element,
  attr_name : String,
) -> String? {
  match get_parent_element(element) {
    Some(parent) =>
      // Check if parent has hx-inherit
      match get_hx_inherit(parent) {
        Some(inherit_value) => {
          // Parse hx-inherit value
          let inherit_array = parse_hx_inherit(inherit_value)
          let inherits_all = check_inherits_all(inherit_array)
          let inherits_this = check_includes_attribute(inherit_array, attr_name)
          if inherits_all || inherits_this {
            // Parent allows inheriting this attribute
            match parent.getAttribute(attr_name) {
              Some(value) => Some(value)
              Option::None => {
                // Check for data-hx-* prefix
                let data_attr = with_data_prefix(attr_name)
                match parent.getAttribute(data_attr) {
                  Some(value) => Some(value)
                  Option::None =>
                    find_inherited_attribute_with_check(parent, attr_name)
                }
              }
            }
          } else {
            // Parent doesn't allow inheriting this attribute, keep searching up
            find_inherited_attribute_with_check(parent, attr_name)
          }
        }
        Option::None => find_inherited_attribute_with_check(parent, attr_name)
      }
    Option::None => Option::None
  }
}

///|
/// Get target element with inheritance support
pub fn get_target_with_inherit(element : @dom.Element) -> @dom.Element {
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
    None =>
      // Try to inherit hx-target from parent
      match should_inherit_attribute(element, target_attr) {
        Some(inherited_selector) => {
          // When inheriting "this" selector, "this" refers to the parent with the attribute
          // We need to find the parent element that has the attribute and return that
          if inherited_selector == "this" {
            match find_element_with_attribute(element, target_attr) {
              Some(parent_with_attr) => parent_with_attr
              None => element
            }
          } else {
            match parse_extended_target(element, inherited_selector) {
              Some(target) => target
              None => element
            }
          }
        }
        None => element
      }
  }
}

///|
/// Find the first parent element (including the element itself) that has the given attribute
extern "js" fn find_element_with_attribute(element : @dom.Element, attr_name : String) -> @dom.Element? =
  #|(element, attr_name) => {
  #|  let el = element;
  #|  while (el) {
  #|    if (el.hasAttribute && el.hasAttribute(attr_name)) {
  #|      return { $tag: 1, _0: el };
  #|    }
  #|    const dataAttr = 'data-' + attr_name;
  #|    if (el.hasAttribute && el.hasAttribute(dataAttr)) {
  #|      return { $tag: 1, _0: el };
  #|    }
  #|    el = el.parentElement;
  #|  }
  #|  return { $tag: 0 };
  #|}

///|
/// Get swap style with inheritance support
pub fn get_swap_style_with_inherit(element : @dom.Element) -> SwapStyle {
  let swap_attr = hx_swap()
  match element.getAttribute(swap_attr) {
    Some(value) => SwapStyle::parse(value)
    Option::None =>
      match element.getAttribute(with_data_prefix(swap_attr)) {
        Some(value) => SwapStyle::parse(value)
        Option::None =>
          // Try to inherit hx-swap from parent
          match should_inherit_attribute(element, swap_attr) {
            Some(inherited_value) => SwapStyle::parse(inherited_value)
            None => SwapStyle::InnerHTML
          }
      }
  }
}

///|
/// Check if attribute value is true (handles various true representations)
extern "js" fn is_attr_true(elt : @dom.Element, attr : String) -> Bool =
  #|(elt, attr) => {
  #|  const value = elt.getAttribute(attr) || elt.getAttribute('data-' + attr);
  #|  return value === 'true' || value === '';
  #|}

///|
/// Get the closest match value from data-hx-* prefix or hx-* attribute
extern "js" fn get_closest_match_value(elt : @dom.Element, attr_name : String) -> String? =
  #|(elt, attr_name) => {
  #|  const value = elt.getAttribute(attr_name);
  #|  if (value) return { $tag: 1, _0: value };
  #|  const dataValue = elt.getAttribute('data-' + attr_name);
  #|  if (dataValue) return { $tag: 1, _0: dataValue };
  #|  return { $tag: 0 };
  #|}

///|
/// Get closest element with attribute value
extern "js" fn get_closest_attr_value(elt : @dom.Element, attribute : String) -> String? =
  #|(elt, attribute) => {
  #|  const closest = elt.closest('[' + attribute + ']');
  #|  if (closest && closest.hasAttribute(attribute)) {
  #|    return { $tag: 1, _0: closest.getAttribute(attribute) };
  #|  }
  #|  return { $tag: 0 };
  #|}

///|
/// Get the swap delay value from element or ancestors
extern "js" fn get_swap_delay(elt : @dom.Element) -> Int =
  #|(elt) => {
  #|  const delayStr = elt.getAttribute('hx-swap-delay') || elt.getAttribute('data-hx-swap-delay');
  #|  if (delayStr) {
  #|    const delay = parseInt(delayStr);
  #|    if (!isNaN(delay)) return delay;
  #|  }
  #|  // Check parent for inheritance
  #|  if (elt.parentElement) {
  #|    const parentDelay = elt.parentElement.getAttribute('hx-swap-delay') || elt.parentElement.getAttribute('data-hx-swap-delay');
  #|    if (parentDelay) {
  #|      const delay = parseInt(parentDelay);
  #|      if (!isNaN(delay)) return delay;
  #|    }
  #|  }
  #|  // Check config default
  #|  if (window.htmx && window.htmx.config && typeof window.htmx.config.defaultSwapDelay === 'number') {
  #|    return window.htmx.config.defaultSwapDelay;
  #|  }
  #|  return 0;
  #|}

///|
/// Get the settle delay value from element or ancestors
extern "js" fn get_settle_delay(elt : @dom.Element) -> Int =
  #|(elt) => {
  #|  const delayStr = elt.getAttribute('hx-settle-delay') || elt.getAttribute('data-hx-settle-delay');
  #|  if (delayStr) {
  #|    const delay = parseInt(delayStr);
  #|    if (!isNaN(delay)) return delay;
  #|  }
  #|  // Check parent for inheritance
  #|  if (elt.parentElement) {
  #|    const parentDelay = elt.parentElement.getAttribute('hx-settle-delay') || elt.parentElement.getAttribute('data-hx-settle-delay');
  #|    if (parentDelay) {
  #|      const delay = parseInt(parentDelay);
  #|      if (!isNaN(delay)) return delay;
  #|    }
  #|  }
  #|  // Check config default
  #|  if (window.htmx && window.htmx.config && typeof window.htmx.config.defaultSettleDelay === 'number') {
  #|    return window.htmx.config.defaultSettleDelay;
  #|  }
  #|  return 0;
  #|}

///|
/// Get the transition flag from element or config
extern "js" fn get_transition(elt : @dom.Element) -> Bool =
  #|(elt) => {
  #|  const transitionStr = elt.getAttribute('hx-transition') || elt.getAttribute('data-hx-transition');
  #|  if (transitionStr) {
  #|    return transitionStr !== 'false' && transitionStr !== 'null';
  #|  }
  #|  // Check config default
  #|  if (window.htmx && window.htmx.config && window.htmx.config.defaultTransition !== undefined) {
  #|    return window.htmx.config.defaultTransition === true;
  #|  }
  #|  return false;
  #|}

///|
/// Get title attribute from element
extern "js" fn get_title_attribute(elt : @dom.Element) -> String? =
  #|(elt) => {
  #|  const title = elt.getAttribute('title');
  #|  if (title) return { $tag: 1, _0: title };
  #|  return { $tag: 0 };
  #|}

///|
/// Get the anchor target from element or closest anchor
extern "js" fn get_anchor_target(elt : @dom.Element) -> String? =
  #|(elt) => {
  #|  if (elt.getAttribute) {
  #|    const target = elt.getAttribute('target');
  #|    if (target) return { $tag: 1, _0: target };
  #|  }
  #|  if (elt.closest) {
  #|    const anchor = elt.closest('a[href]');
  #|    if (anchor && anchor.getAttribute) {
  #|      const target = anchor.getAttribute('target');
  #|      if (target) return { $tag: 1, _0: target };
  #|    }
  #|  }
  #|  return { $tag: 0 };
  #|}

///|
/// Get the closest ID-based target from element or ancestors
extern "js" fn get_closest_id_target(elt : @dom.Element) -> String? =
  #|(elt) => {
  #|  const getClosestId = (el) => {
  #|    while (el && el.id) {
  #|      if (el.id) return '#' + el.id;
  #|      el = el.parentElement;
  #|    }
  #|    return null;
  #|  };
  #|  const id = getClosestId(elt);
  #|  if (id) return { $tag: 1, _0: id };
  #|  return { $tag: 0 };
  #|}

///|
/// Get the indicator element(s) by selector
extern "js" fn get_indicator_elements(elt : @dom.Element) -> Array[@dom.Element] =
  #|(elt) => {
  #|  // Get hx-indicator attribute value
  #|  let indicatorAttr = 'hx-indicator';
  #|  const indicatorValue = elt.getAttribute(indicatorAttr) || elt.getAttribute('data-' + indicatorAttr);
  #|
  #|  if (indicatorValue) {
  #|    // Find elements by selector
  #|    if (indicatorValue === 'this') {
  #|      return [elt];
  #|    } else if (indicatorValue === 'closest') {
  #|      return [elt];
  #|    } else if (indicatorValue === 'previous') {
  #|      return [elt.previousElementSibling].filter(e => e != null);
  #|    } else if (indicatorValue === 'next') {
  #|      return [elt.nextElementSibling].filter(e => e != null);
  #|    } else {
  #|      // Use querySelectorAll for CSS selectors
  #|      try {
  #|        return Array.from(document.querySelectorAll(indicatorValue));
  #|      } catch (e) {
  #|        return [];
  #|      }
  #|    }
  #|  }
  #|
  #|  // No indicator attribute, return the element itself
  #|  return [elt];
  #|}

///|
/// Resolve 'inherit' keyword in indicator selector by expanding it with parent's indicator
extern "js" fn resolve_inherit(element : @dom.Element, selector : String) -> String =
  #|(element, selector) => {
  #|  const parts = selector.split(',').map(s => s.trim());
  #|  const results = [];
  #|  for (const part of parts) {
  #|    if (part === 'inherit') {
  #|      const parent = element.parentElement;
  #|      if (parent) {
  #|        const parentIndicator = parent.getAttribute('hx-indicator') || parent.getAttribute('data-hx-indicator');
  #|        if (parentIndicator) {
  #|          results.push(parentIndicator);
  #|        } else {
  #|          results.push(resolve_inherit(parent, selector));
  #|        }
  #|      } else {
  #|        results.push('this');
  #|      }
  #|    } else {
  #|      results.push(part);
  #|    }
  #|  }
  #|  return results.join(', ');
  #|}

///|
/// Split string by semicolon
extern "js" fn split_by_semicolon(s : String) -> Array[String] =
  #|(s) => s.split(';').map(x => x.trim()).filter(x => x.length > 0)

///|
/// Get trigger event for element
extern "js" fn get_trigger_event(elt : @dom.Element) -> String =
  #|(elt) => {
  #|  const trigger = elt.getAttribute('hx-trigger') || elt.getAttribute('data-hx-trigger');
  #|  if (trigger) {
  #|    // Parse modifiers (changed, once, delay, throttle, from, consume)
  #|    const parts = trigger.split(' ').filter(p => p.length > 0);
  #|    const eventPart = parts.find(p => !p.startsWith('changed.'));
  #|    return eventPart || 'click';  // Default to click if not specified
  #|  }
  #|  return 'click';  // Default to click for GET/POST/etc without trigger
  #|}

///|
/// Resolve the modifier keywords in trigger attribute
extern "js" fn resolve_trigger_modifiers(elt : @dom.Element, trigger : String) -> String =
  #|(elt, trigger) => {
  #|  // If trigger doesn't contain modifiers, return as-is
  #|  if (!trigger.includes('changed') && !trigger.includes('once')) {
  #|    return trigger;
  #|  }
  #|
  #|  // Parse and resolve modifiers
  #|  const parts = trigger.split(' ').filter(p => p.length > 0);
  #|  const result = [];
  #|
  #|  for (const part of parts) {
  #|    if (part === 'once') {
  #|      // Add marker for one-time trigger
  #|      result.push('once');
  #|    } else if (part === 'changed') {
  #|      // For input elements, use 'change' event
  #|      result.push('change');
  #|    } else if (part.startsWith('delay:')) {
  #|      result.push(part);  // Keep delay as-is
  #|    } else if (part.startsWith('throttle:')) {
  #|      result.push(part);  // Keep throttle as-is
  #|    } else if (part.startsWith('from:')) {
  #|      result.push(part);  // Keep from as-is
  #|    } else if (!result.includes('change') && !result.includes('click')) {
  #|      result.push(part);  // Add event type if not already added
  #|    }
  #|  }
  #|
  #|  return result.join(' ') || 'click';
  #|}

///|
/// Check if the specified event should be filtered (used with changed/once modifiers)
extern "js" fn should_filter_event(elt : @dom.Element, eventType : String) -> Bool =
  #|(elt, eventType) => {
  #|  const trigger = elt.getAttribute('hx-trigger') || elt.getAttribute('data-hx-trigger');
  #|  if (!trigger) return false;
  #|
  #|  // For 'changed' modifier on input elements
  #|  if (trigger.includes('changed')) {
  #|    // Only trigger on 'change' event, not 'input'
  #|    return eventType !== 'change';
  #|  }
  #|
  #|  // For 'once' modifier
  #|  if (trigger.includes('once')) {
  #|    // Check if event was already triggered
  #|    const key = 'htmx-triggered-' + eventType;
  #|    if (elt[key]) {
  #|      return true;  // Filter out (already triggered)
  #|    }
  #|  }
  #|
  #|  return false;
  #|}

///|
/// Mark event as triggered (used with 'once' modifier)
extern "js" fn mark_event_triggered(elt : @dom.Element, eventType : String) -> Unit =
  #|(elt, eventType) => {
  #|  const key = 'htmx-triggered-' + eventType;
  #|  elt[key] = true;
  #|}

///|
/// Get the swap style string from element
extern "js" fn get_swap_style_string(elt : @dom.Element) -> String =
  #|(elt) => {
  #|  const swap = elt.getAttribute('hx-swap') || elt.getAttribute('data-hx-swap');
  #|  if (swap) return swap;
  #|
  #|  // Check config default
  #|  if (window.htmx && window.htmx.config && window.htmx.config.defaultSwapStyle) {
  #|    return window.htmx.config.defaultSwapStyle;
  #|  }
  #|
  #|  return 'innerHTML';
  #|}

///|
/// Get disabled elements by selector
extern "js" fn get_disabled_elements(elt : @dom.Element, selector : String) -> Array[@dom.Element] =
  #|(elt, selector) => {
  #|  if (!selector) return [];
  #|
  #|  // Handle extended syntax: this, closest, find, next
  #|  if (selector === 'this') {
  #|    return [elt];
  #|  } else if (selector.startsWith('closest ')) {
  #|    const css = selector.substring(8);
  #|    const closest = elt.closest(css);
  #|    return closest ? [closest] : [];
  #|  } else if (selector.startsWith('find ')) {
  #|    const css = selector.substring(5);
  #|    try {
  #|      return Array.from(elt.querySelectorAll(css));
  #|    } catch (e) {
  #|      return [];
  #|    }
  #|  } else if (selector === 'next') {
  #|    const next = elt.nextElementSibling;
  #|    return next ? [next] : [];
  #|  } else if (selector === 'previous') {
  #|    const prev = elt.previousElementSibling;
  #|    return prev ? [prev] : [];
  #|  } else {
  #|    // Default: use querySelectorAll
  #|    try {
  #|      return Array.from(document.querySelectorAll(selector));
  #|    } catch (e) {
  #|      return [];
  #|    }
  #|  }
  #|}

///|
/// Get the preserve attribute value from element or ancestors
extern "js" fn get_preserve_transparency_attr(elt : @dom.Element) -> Bool =
  #|(elt) => {
  #|  const value = elt.getAttribute('hx-preserve') || elt.getAttribute('data-hx-preserve');
  #|  if (value != null) {
  #|    return value !== 'false';
  #|  }
  #|
  #|  // Check config default
  #|  if (window.htmx && window.htmx.config && window.htmx.config.defaultPreservedTransparency !== undefined) {
  #|    return window.htmx.config.defaultPreservedTransparency === true;
  #|  }
  #|
  #|  return false;
  #|}

///|
/// Get confirm message from element or closest ancestor
extern "js" fn get_confirm_message(elt : @dom.Element) -> String? =
  #|(elt) => {
  #|  const message = elt.getAttribute('hx-confirm') || elt.getAttribute('data-hx-confirm');
  #|  if (message) return { $tag: 1, _0: message };
  #|
  #|  // Check ancestors
  #|  const closest = elt.closest('[hx-confirm], [data-hx-confirm]');
  #|  if (closest && closest !== elt) {
  #|    const msg = closest.getAttribute('hx-confirm') || closest.getAttribute('data-hx-confirm');
  #|    if (msg) return { $tag: 1, _0: msg };
  #|  }
  #|
  #|  return { $tag: 0 };
  #|}

///|
/// Get prompt message from element or closest ancestor
extern "js" fn get_prompt_message(elt : @dom.Element) -> String? =
  #|(elt) => {
  #|  const message = elt.getAttribute('hx-prompt') || elt.getAttribute('data-hx-prompt');
  #|  if (message) return { $tag: 1, _0: message };
  #|
  #|  // Check ancestors
  #|  const closest = elt.closest('[hx-prompt], [data-hx-prompt]');
  #|  if (closest && closest !== elt) {
  #|    const msg = closest.getAttribute('hx-prompt') || closest.getAttribute('data-hx-prompt');
  #|    if (msg) return { $tag: 1, _0: msg };
  #|  }
  #|
  #|  return { $tag: 0 };
  #|}

///|
/// Get validate attribute from element
extern "js" fn get_validate_attribute(elt : @dom.Element) -> Bool =
  #|(elt) => {
  #|  const validate = elt.getAttribute('hx-validate') || elt.getAttribute('data-hx-validate');
  #|  if (validate) {
  #|    return validate !== 'false' && validate !== 'null';
  #|  }
  #|
  #|  // Check config default
  #|  if (window.htmx && window.htmx.config && window.htmx.config.defaultValidate !== undefined) {
  #|    return window.htmx.config.defaultValidate === true;
  #|  }
  #|
  #|  return false;
  #|}

///|
/// Get the value attribute for an element
extern "js" fn get_value_attribute(elt : @dom.Element) -> String? =
  #|(elt) => {
  #|  if (elt.value !== undefined) {
  #|    return { $tag: 1, _0: String(elt.value) };
  #|  }
  #|  return { $tag: 0 };
  #|}

///|
/// Get the hx-include attribute value from element
extern "js" fn get_include_attribute(elt : @dom.Element) -> String? =
  #|(elt) => {
  #|  const include = elt.getAttribute('hx-include') || elt.getAttribute('data-hx-include');
  #|  if (include) {
  #|    return { $tag: 1, _0: include };
  #|  }
  #|  return { $tag: 0 };
  #|}

///|
/// Get elements matching the hx-include selector
extern "js" fn get_included_elements(elt : @dom.Element, selector : String) -> Array[@dom.Element] =
  #|(elt, selector) => {
  #|  if (!selector) return [];
  #|
  #|  // Handle special selectors
  #|  if (selector === 'this') {
  #|    return [elt];
  #|  } else if (selector === 'closest') {
  #|    return [elt];
  #|  } else if (selector.startsWith('closest ')) {
  #|    const css = selector.substring(8);
  #|    const closest = elt.closest(css);
  #|    return closest ? [closest] : [];
  #|  } else if (selector === 'previous') {
  #|    const prev = elt.previousElementSibling;
  #|    return prev ? [prev] : [];
  #|  } else if (selector === 'next') {
  #|    const next = elt.nextElementSibling;
  #|    return next ? [next] : [];
  #|  } else {
  #|    // Use querySelectorAll
  #|    try {
  #|      return Array.from(document.querySelectorAll(selector));
  #|    } catch (e) {
  #|      return [];
  #|    }
  #|  }
  #|}

///|
/// Get the hx-params attribute value from element
extern "js" fn get_params_attribute(elt : @dom.Element) -> String? =
  #|(elt) => {
  #|  const params = elt.getAttribute('hx-params') || elt.getAttribute('data-hx-params');
  #|  if (params) {
  #|    return { $tag: 1, _0: params };
  #|  }
  #|  return { $tag: 0 };
  #|}

///|
/// Get the hx-select attribute value from element
extern "js" fn get_select_attribute(elt : @dom.Element) -> String? =
  #|(elt) => {
  #|  const select = elt.getAttribute('hx-select') || elt.getAttribute('data-hx-select');
  #|  if (select) {
  #|    return { $tag: 1, _0: select };
  #|  }
  #|  return { $tag: 0 };
  #|}

///|
/// Get the hx-select-oob attribute value from element
extern "js" fn get_select_oob_attribute(elt : @dom.Element) -> String? =
  #|(elt) => {
  #|  const select = elt.getAttribute('hx-select-oob') || elt.getAttribute('data-hx-select-oob');
  #|  if (select) {
  #|    return { $tag: 1, _0: select };
  #|  }
  #|  return { $tag: 0 };
  #|}

///|
/// Get the hx-encoding attribute value from element
extern "js" fn get_encoding_attribute(elt : @dom.Element) -> String? =
  #|(elt) => {
  #|  const encoding = elt.getAttribute('hx-encoding') || elt.getAttribute('data-hx-encoding');
  #|  if (encoding) {
  #|    return { $tag: 1, _0: encoding };
  #|  }
  #|  return { $tag: 0 };
  #|}

///|
/// Get the hx-headers attribute value from element
extern "js" fn get_headers_attribute(elt : @dom.Element) -> String? =
  #|(elt) => {
  #|  const headers = elt.getAttribute('hx-headers') || elt.getAttribute('data-hx-headers');
  #|  if (headers) {
  #|    return { $tag: 1, _0: headers };
  #|  }
  #|  return { $tag: 0 };
  #|}

///|
/// Get the hx-request attribute value from element
extern "js" fn get_request_attribute(elt : @dom.Element) -> @core.Any =
  #|(elt) => {
  #|  const request = elt.getAttribute('hx-request') || elt.getAttribute('data-hx-request');
  #|  if (request) {
  #|    try {
  #|      return JSON.parse(request);
  #|    } catch (e) {
  #|      return null;
  #|    }
  #|  }
  #|  return null;
  #|}

///|
/// Get the hx-ext attribute value from element
extern "js" fn get_ext_attribute(elt : @dom.Element) -> String? =
  #|(elt) => {
  #|  const ext = elt.getAttribute('hx-ext') || elt.getAttribute('data-hx-ext');
  #|  if (ext) {
  #|    return { $tag: 1, _0: ext };
  #|  }
  #|  return { $tag: 0 };
  #|}

///|
/// Get the hx-disinherit attribute value from element
extern "js" fn get_disinherit_attribute(elt : @dom.Element) -> String? =
  #|(elt) => {
  #|  const disinherit = elt.getAttribute('hx-disinherit') || elt.getAttribute('data-hx-disinherit');
  #|  if (disinherit) {
  #|    return { $tag: 1, _0: disinherit };
  #|  }
  #|  return { $tag: 0 };
  #|}

///|
/// Get the hx-replace-url attribute value from element
extern "js" fn get_replace_url_attribute(elt : @dom.Element) -> String? =
  #|(elt) => {
  #|  const replaceUrl = elt.getAttribute('hx-replace-url') || elt.getAttribute('data-hx-replace-url');
  #|  if (replaceUrl) {
  #|    return { $tag: 1, _0: replaceUrl };
  #|  }
  #|  return { $tag: 0 };
  #|}

///|
/// Check if the element has the hx-boost attribute
extern "js" fn has_boost_attribute(elt : @dom.Element) -> Bool =
  #|(elt) => {
  #|  return elt.hasAttribute('hx-boost') || elt.hasAttribute('data-hx-boost');
  #|}

///|
/// Get the hx-on attribute for a specific event
extern "js" fn get_hx_on_for_event(elt : @dom.Element, event : String) -> String? =
  #|(elt, event) => {
  #|  const hxOn = elt.getAttribute('hx-on::' + event) || elt.getAttribute('data-hx-on::' + event);
  #|  if (hxOn) {
  #|    return { $tag: 1, _0: hxOn };
  #|  }
  #|  return { $tag: 0 };
  #|}

///|
/// Get the hx-on-* attribute for any event on element
extern "js" fn get_all_hx_on_attributes(elt : @dom.Element) -> @core.Any =
  #|(elt) => {
  #|  const result = {};
  #|  if (!elt.attributes) return result;
  #|
  #|  for (let i = 0; i < elt.attributes.length; i++) {
  #|    const attr = elt.attributes[i];
  #|    const name = attr.name;
  #|
  #|    // Match hx-on:* or data-hx-on:*
  #|    const match = name.match(/^(?:data-)?hx-on::(.+)$/);
  #|    if (match) {
  #|      result[match[1]] = attr.value;
  #|    }
  #|  }
  #|
  #|  return result;
  #|}

///|
/// Get dataset attribute value
extern "js" fn get_dataset_attribute(elt : @dom.Element, name : String) -> String? =
  #|(elt, name) => {
  #|  if (elt.dataset && elt.dataset[name] !== undefined) {
  #|    return { $tag: 1, _0: String(elt.dataset[name]) };
  #|  }
  #|  return { $tag: 0 };
  #|}

///|
/// Get any attribute value by name
extern "js" fn get_any_attribute(elt : @dom.Element, name : String) -> String? =
  #|(elt, name) => {
  #|  const value = elt.getAttribute(name);
  #|  if (value) return { $tag: 1, _0: value };
  #|  return { $tag: 0 };
  #|}

///|
/// Get hx-swap-oob attribute value from element
extern "js" fn get_swap_oob_attribute(elt : @dom.Element) -> String? =
  #|(elt) => {
  #|  const swap = elt.getAttribute('hx-swap-oob') || elt.getAttribute('data-hx-swap-oob');
  #|  if (swap) {
  #|    return { $tag: 1, _0: swap };
  #|  }
  #|  return { $tag: 0 };
  #|}

///|
/// Get hx-error-url attribute value from element
extern "js" fn get_error_url_attribute(elt : @dom.Element) -> String? =
  #|(elt) => {
  #|  const url = elt.getAttribute('hx-error-url') || elt.getAttribute('data-hx-error-url');
  #|  if (url) {
  #|    return { $tag: 1, _0: url };
  #|  }
  #|  return { $tag: 0 };
  #|}

///|
/// Get hx-push-url attribute value from element
extern "js" fn get_push_url_attribute(elt : @dom.Element) -> String? =
  #|(elt) => {
  #|  const url = elt.getAttribute('hx-push-url') || elt.getAttribute('data-hx-push-url');
  #|  if (url) {
  #|    return { $tag: 1, _0: url };
  #|  }
  #|  return { $tag: 0 };
  #|}

///|
/// Get hx-history-elt attribute from element
extern "js" fn get_history_elt_attribute(elt : @dom.Element) -> Bool =
  #|(elt) => {
  #|  const history = elt.getAttribute('hx-history-elt') || elt.getAttribute('data-hx-history-elt');
  #|  return history === '' || history === 'true';
  #|}

///|
/// Get hx-history attribute from element
extern "js" fn get_history_attribute(elt : @dom.Element) -> Bool =
  #|(elt) => {
  #|  const history = elt.getAttribute('hx-history') || elt.getAttribute('data-hx-history');
  #|  return history === 'true' || history === '' || history === null;
  #|}

///|
/// Get hx-on-wildcard attribute from element
extern "js" fn get_on_wildcard_attribute(elt : @dom.Element) -> String? =
  #|(elt) => {
  #|  const wildcard = elt.getAttribute('hx-on') || elt.getAttribute('data-hx-on');
  #|  if (wildcard) {
  #|    return { $tag: 1, _0: wildcard };
  #|  }
  #|  return { $tag: 0 };
  #|}

///|
/// Get hx-sse attribute value from element
extern "js" fn get_sse_attribute(elt : @dom.Element) -> String? =
  #|(elt) => {
  #|  const sse = elt.getAttribute('hx-sse') || elt.getAttribute('data-hx-sse');
  #|  if (sse) {
  #|    return { $tag: 1, _0: sse };
  #|  }
  #|  return { $tag: 0 };
  #|}

///|
/// Get hx-ws attribute value from element
extern "js" fn get_ws_attribute(elt : @dom.Element) -> String? =
  #|(elt) => {
  #|  const ws = elt.getAttribute('hx-ws') || elt.getAttribute('data-hx-ws');
  #|  if (ws) {
  #|    return { $tag: 1, _0: ws };
  #|  }
  #|  return { $tag: 0 };
  #|}

///|
/// Get hx-sync attribute value from element
extern "js" fn get_sync_attribute(elt : @dom.Element) -> String? =
  #|(elt) => {
  #|  const sync = elt.getAttribute('hx-sync') || elt.getAttribute('data-hx-sync');
  #|  if (sync) {
  #|    return { $tag: 1, _0: sync };
  #|  }
  #|  return { $tag: 0 };
  #|}

///|
/// Get hx-disable attribute from element
extern "js" fn get_disable_attribute(elt : @dom.Element) -> Bool =
  #|(elt) => {
  #|  const disable = elt.getAttribute('hx-disable');
  #|  return disable === '' || disable === 'true';
  #|}

///|
/// Get method attribute value as string (for finding htmx method attributes)
pub fn get_method_attribute(element : @dom.Element, attr : String) -> String? {
  match element.getAttribute(attr) {
    Some(url) => Some(url)
    None => element.getAttribute(with_data_prefix(attr))
  }
}

///|
/// Find htmx method URL attribute on element (e.g., hx-get, hx-post, etc.)
/// Returns (method, url) as tuple strings if found, None otherwise
pub fn find_method_url(element : @dom.Element) -> (String, String)? {
  // Check for hx-get
  match get_method_attribute(element, "hx-get") {
    Some(url) => Some(("GET", url))
    None => {
      // Check for hx-post
      match get_method_attribute(element, "hx-post") {
        Some(url) => Some(("POST", url))
        None => {
          // Check for hx-put
          match get_method_attribute(element, "hx-put") {
            Some(url) => Some(("PUT", url))
            None => {
              // Check for hx-delete
              match get_method_attribute(element, "hx-delete") {
                Some(url) => Some(("DELETE", url))
                None => {
                  // Check for hx-patch
                  match get_method_attribute(element, "hx-patch") {
                    Some(url) => Some(("PATCH", url))
                    None => Option::None
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}

///|
/// Get hx-disabled-elt attribute value from element
pub fn get_disabled_elt(elt : @dom.Element) -> String? {
  get_attribute_with_prefix(elt, hx_disabled_elt())
}

///|
/// Find the closest element with htmx attributes
pub fn find_htmx_element(target_el : @dom.Element) -> @dom.Element? {
  if has_htmx_attribute(target_el) {
    Some(target_el)
  } else {
    match get_parent_element(target_el) {
      Some(parent) => find_htmx_element(parent)
      None => Option::None
    }
  }
}
