///|
/// Swap styles for DOM updates
pub enum SwapStyle {
  InnerHTML
  OuterHTML
  BeforeBegin
  AfterBegin
  BeforeEnd
  AfterEnd
  Delete
  Morph
  None
}

///|
/// Show implementation for SwapStyle
pub impl Show for SwapStyle with output(self, logger) {
  let name = match self {
    InnerHTML => "InnerHTML"
    OuterHTML => "OuterHTML"
    BeforeBegin => "BeforeBegin"
    AfterBegin => "AfterBegin"
    BeforeEnd => "BeforeEnd"
    AfterEnd => "AfterEnd"
    Delete => "Delete"
    Morph => "Morph"
    None => "None"
  }
  logger.write_string(name)
}

///|
/// Scroll direction for swap modifier
pub enum ScrollDirection {
  Top
  Bottom
}

///|
/// Show implementation for ScrollDirection
pub impl Show for ScrollDirection with output(self, logger) {
  let name = match self {
    Top => "Top"
    Bottom => "Bottom"
  }
  logger.write_string(name)
}

///|
/// Scroll specification for swap modifier
pub struct ScrollSpec {
  direction : ScrollDirection
  target : String?
}

///|
/// Show specification for swap modifier
pub struct ShowSpec {
  direction : ScrollDirection
  target : String?
}

///|
/// Complete swap specification with modifiers
pub struct SwapSpec {
  style : SwapStyle
  swap_delay_ms : Int
  settle_delay_ms : Int
  scroll : ScrollSpec?
  show : ShowSpec?
  focus_scroll : Bool
  ignore_title : Bool
}

///|
/// FFI helpers for swap parsing
extern "js" fn substring_before(s : String, end : Int) -> String =
  #|(s, end) => { return s.substring(0, end); }

///|
extern "js" fn substring_after_js(s : String, start : Int) -> String =
  #|(s, start) => { return s.substring(start); }

///|
extern "js" fn has_suffix_js(s : String, suffix : String) -> Bool =
  #|(s, suffix) => { return s.endsWith(suffix); }

///|
extern "js" fn split_spaces(s : String) -> Array[String] =
  #|(s) => { return s.trim().split(/\s+/); }

///|
extern "js" fn js_parse_int_or(s : String, def : Int) -> Int =
  #|(s, def) => { let n = parseInt(s, 10); return isNaN(n) ? def : n; }

///|
extern "js" fn starts_with_js(s : String, prefix : String) -> Bool =
  #|(s, prefix) => { return s.startsWith(prefix); }

///|
/// Create default SwapSpec with InnerHTML style
pub fn SwapSpec::default() -> SwapSpec {
  SwapSpec::new(InnerHTML, 0, 0, Option::None, Option::None, true, false)
}

///|
/// Create SwapSpec from just a SwapStyle
pub fn SwapSpec::from_style(style : SwapStyle) -> SwapSpec {
  SwapSpec::new(style, 0, 0, Option::None, Option::None, true, false)
}

///|
/// Constructor for SwapSpec
pub fn SwapSpec::new(
  style : SwapStyle,
  swap_delay_ms : Int,
  settle_delay_ms : Int,
  scroll : ScrollSpec?,
  show : ShowSpec?,
  focus_scroll : Bool,
  ignore_title : Bool,
) -> SwapSpec {
  {
    style,
    swap_delay_ms,
    settle_delay_ms,
    scroll,
    show,
    focus_scroll,
    ignore_title,
  }
}

///|
/// Parse swap specification from string (e.g., "innerHTML swap:100ms settle:200ms scroll:top")
pub fn SwapSpec::parse(value : String) -> SwapSpec {
  let parts = split_spaces(value)
  let mut style = InnerHTML
  let mut swap_delay = 0
  let mut settle_delay = 0
  let mut scroll_spec = Option::None
  let mut show_spec = Option::None
  let mut focus_scroll = true
  let mut ignore_title = false
  let mut i = 0
  while i < parts.length() {
    let part = parts[i]
    if part != "" {
      let result = parse_swap_spec_part(
        part, style, swap_delay, settle_delay, scroll_spec, show_spec, focus_scroll,
        ignore_title,
      )
      style = result.0
      swap_delay = result.1
      settle_delay = result.2
      scroll_spec = result.3
      show_spec = result.4
      focus_scroll = result.5
      ignore_title = result.6
    }
    i = i + 1
  }
  SwapSpec::new(
    style, swap_delay, settle_delay, scroll_spec, show_spec, focus_scroll, ignore_title,
  )
}

///|
/// Parse a single part of the swap specification and return tuple of values
fn parse_swap_spec_part(
  part : String,
  style : SwapStyle,
  swap_delay : Int,
  settle_delay : Int,
  scroll_spec : ScrollSpec?,
  show_spec : ShowSpec?,
  focus_scroll : Bool,
  ignore_title : Bool,
) -> (SwapStyle, Int, Int, ScrollSpec?, ShowSpec?, Bool, Bool) {
  if is_swap_modifier(part, "swap:") {
    let ms_str = substring_after_js(part, 5)
    let ms = parse_swap_duration_ms(ms_str)
    (
      style, ms, settle_delay, scroll_spec, show_spec, focus_scroll, ignore_title,
    )
  } else if is_swap_modifier(part, "settle:") {
    let ms_str = substring_after_js(part, 7)
    let ms = parse_swap_duration_ms(ms_str)
    (style, swap_delay, ms, scroll_spec, show_spec, focus_scroll, ignore_title)
  } else if is_swap_modifier(part, "scroll:") {
    let scroll_value = substring_after_js(part, 7)
    (
      style,
      swap_delay,
      settle_delay,
      Some(parse_scroll_spec(scroll_value)),
      show_spec,
      focus_scroll,
      ignore_title,
    )
  } else if is_swap_modifier(part, "show:") {
    let show_value = substring_after_js(part, 5)
    (
      style,
      swap_delay,
      settle_delay,
      scroll_spec,
      Some(parse_show_spec(show_value)),
      focus_scroll,
      ignore_title,
    )
  } else if part == "focus-scroll:true" {
    (
      style, swap_delay, settle_delay, scroll_spec, show_spec, true, ignore_title,
    )
  } else if part == "focus-scroll:false" {
    (
      style, swap_delay, settle_delay, scroll_spec, show_spec, false, ignore_title,
    )
  } else if part == "ignoreTitle:true" {
    (
      style, swap_delay, settle_delay, scroll_spec, show_spec, focus_scroll, true,
    )
  } else if part == "ignoreTitle:false" {
    (
      style, swap_delay, settle_delay, scroll_spec, show_spec, focus_scroll, false,
    )
  } else {
    // Try to parse as swap style
    (
      SwapStyle::parse(part),
      swap_delay,
      settle_delay,
      scroll_spec,
      show_spec,
      focus_scroll,
      ignore_title,
    )
  }
}

///|
/// Check if string starts with prefix
fn is_swap_modifier(s : String, prefix : String) -> Bool {
  starts_with_js(s, prefix)
}

///|
/// Parse scroll specification (e.g., "top", "bottom", "top:window", "bottom:#target")
fn parse_scroll_spec(value : String) -> ScrollSpec {
  if is_swap_modifier(value, "top") {
    let rest = substring_after_js(value, 3)
    if rest == "" || is_swap_modifier(rest, ":") {
      let target = if rest == "" {
        Option::None
      } else {
        Some(substring_after_js(rest, 1))
      }
      ScrollSpec::new(Top, target)
    } else {
      ScrollSpec::new(Top, Option::None)
    }
  } else if is_swap_modifier(value, "bottom") {
    let rest = substring_after_js(value, 6)
    if rest == "" || is_swap_modifier(rest, ":") {
      let target = if rest == "" {
        Option::None
      } else {
        Some(substring_after_js(rest, 1))
      }
      ScrollSpec::new(Bottom, target)
    } else {
      ScrollSpec::new(Bottom, Option::None)
    }
  } else {
    // Default to top for invalid values
    ScrollSpec::new(Top, Option::None)
  }
}

///|
/// Constructor for ScrollSpec
pub fn ScrollSpec::new(
  direction : ScrollDirection,
  target : String?,
) -> ScrollSpec {
  { direction, target }
}

///|
/// Parse show specification (same format as scroll)
fn parse_show_spec(value : String) -> ShowSpec {
  if is_swap_modifier(value, "top") {
    let rest = substring_after_js(value, 3)
    if rest == "" || is_swap_modifier(rest, ":") {
      let target = if rest == "" {
        Option::None
      } else {
        Some(substring_after_js(rest, 1))
      }
      ShowSpec::new(Top, target)
    } else {
      ShowSpec::new(Top, Option::None)
    }
  } else if is_swap_modifier(value, "bottom") {
    let rest = substring_after_js(value, 6)
    if rest == "" || is_swap_modifier(rest, ":") {
      let target = if rest == "" {
        Option::None
      } else {
        Some(substring_after_js(rest, 1))
      }
      ShowSpec::new(Bottom, target)
    } else {
      ShowSpec::new(Bottom, Option::None)
    }
  } else {
    // Default to top for invalid values
    ShowSpec::new(Top, Option::None)
  }
}

///|
/// Constructor for ShowSpec
pub fn ShowSpec::new(direction : ScrollDirection, target : String?) -> ShowSpec {
  { direction, target }
}

///|
/// Parse duration string to milliseconds (e.g., "100ms", "1s", "500")
fn parse_swap_duration_ms(value : String) -> Int {
  if has_suffix_js(value, "ms") {
    let num_str = substring_before(value, value.length() - 2)
    js_parse_int_or(num_str, 0)
  } else if has_suffix_js(value, "s") {
    let num_str = substring_before(value, value.length() - 1)
    let seconds = js_parse_int_or(num_str, 0)
    seconds * 1000
  } else {
    // Assume milliseconds if no unit
    js_parse_int_or(value, 0)
  }
}

///|
/// Parse swap style from string
pub fn SwapStyle::parse(value : String) -> SwapStyle {
  match value {
    "innerHTML" => InnerHTML
    "outerHTML" => OuterHTML
    "beforebegin" => BeforeBegin
    "afterbegin" => AfterBegin
    "beforeend" => BeforeEnd
    "afterend" => AfterEnd
    "delete" => Delete
    "none" => None
    "morph" => Morph
    _ => InnerHTML // default
  }
}

///|
/// Convert SwapStyle to lowercase string for htmx compatibility
pub fn SwapStyle::to_htmx_string(self : SwapStyle) -> String {
  match self {
    InnerHTML => "innerHTML"
    OuterHTML => "outerHTML"
    BeforeBegin => "beforebegin"
    AfterBegin => "afterbegin"
    BeforeEnd => "beforeend"
    AfterEnd => "afterend"
    Delete => "delete"
    None => "none"
    Morph => "morph"
  }
}

///|
/// Get position string for insertAdjacentHTML
fn SwapStyle::to_position(self : SwapStyle) -> String? {
  match self {
    BeforeBegin => Some("beforebegin")
    AfterBegin => Some("afterbegin")
    BeforeEnd => Some("beforeend")
    AfterEnd => Some("afterend")
    _ => Option::None
  }
}

///|
/// Perform DOM swap operation
pub fn swap(target : @dom.Element, content : String, style : SwapStyle) -> Unit {
  match style {
    InnerHTML => target.setInnerHTML(content)
    OuterHTML => target.setOuterHTML(content)
    Morph => morph(target, content)
    Delete => target.remove()
    None => ()
    _ =>
      match style.to_position() {
        Some(pos) => target.insertAdjacentHTML(pos, content)
        None => () // Should not happen for remaining cases
      }
  }
}
