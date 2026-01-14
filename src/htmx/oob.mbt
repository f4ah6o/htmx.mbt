///|
/// Out-Of-Band (OOB) swap support for htmx
/// Elements with hx-swap-oob are swapped into different targets

///|
/// OOB swap specification
pub struct OobSpec {
  style : SwapStyle
  target : String? // Custom target selector (None = use element's id)
}

///|
/// Create OobSpec from just a SwapStyle
pub fn OobSpec::from_style(style : SwapStyle) -> OobSpec {
  { style, target: None }
}

///|
/// Create OobSpec with style and custom target
pub fn OobSpec::new(style : SwapStyle, target : String?) -> OobSpec {
  { style, target }
}

///|
/// Insert adjacent HTML
extern "js" fn insert_adjacent(
  element : @dom.Element,
  position : String,
  html : String,
) -> Unit =
  #|(el, pos, html) => el.insertAdjacentHTML(pos, html)

///|
/// Remove element
extern "js" fn remove_element(element : @dom.Element) -> Unit =
  #|(el) => el.remove()

///|
/// Set inner HTML
extern "js" fn set_inner_html(element : @dom.Element, html : String) -> Unit =
  #|(el, html) => el.innerHTML = html

///|
/// Set outer HTML
extern "js" fn set_outer_html(element : @dom.Element, html : String) -> Unit =
  #|(el, html) => el.outerHTML = html

///|
/// Parse OOB specification from string
/// Supported formats:
/// - "true" -> outerHTML (default)
/// - "innerHTML" -> innerHTML
/// - "outerHTML" -> outerHTML
/// - "beforebegin" -> beforebegin
/// - "afterbegin" -> afterbegin
/// - "beforeend" -> beforeend
/// - "afterend" -> afterend
/// - "delete" -> delete
/// - "innerHTML:#target" -> innerHTML with custom target
/// - "beforeend:.class" -> beforeend with custom target
pub fn parse_oob_spec(value : String) -> OobSpec {
  let trimmed = value.trim().to_string()
  if trimmed == "true" {
    return OobSpec::from_style(OuterHTML)
  }

  // Check for colon separator (style:target format)
  let colon_idx = find_char(trimmed, ':')
  if colon_idx > 0 {
    let style_str = substr_to(trimmed, colon_idx)
    let target = substr_from(trimmed, colon_idx + 1)
    let style = SwapStyle::parse(style_str)
    OobSpec::new(style, Some(target))
  } else {
    // Simple style without target
    let style = SwapStyle::parse(trimmed)
    OobSpec::from_style(style)
  }
}

///|
/// Execute OOB swap
/// - new_el: The element from the response containing the new content
/// - target_el: The target element in the main document
/// - spec: The OOB specification
pub fn execute_oob_swap(
  new_el : @dom.Element,
  target_el : @dom.Element,
  spec : OobSpec,
) -> Unit {
  match spec.style {
    Delete => remove_element(target_el)
    None => ()
    InnerHTML => {
      let content = get_inner_html(new_el)
      set_inner_html(target_el, content)
    }
    OuterHTML => {
      let content = get_outer_html(new_el)
      set_outer_html(target_el, content)
    }
    BeforeBegin => {
      let content = get_outer_html(new_el)
      insert_adjacent(target_el, "beforebegin", content)
    }
    AfterBegin => {
      let content = get_inner_html(new_el)
      insert_adjacent(target_el, "afterbegin", content)
    }
    BeforeEnd => {
      let content = get_inner_html(new_el)
      insert_adjacent(target_el, "beforeend", content)
    }
    AfterEnd => {
      let content = get_outer_html(new_el)
      insert_adjacent(target_el, "afterend", content)
    }
    Morph => {
      // Direct element-to-element morphing
      morph_element(target_el, new_el)
    }
  }
}

///|
/// Find OOB target element
/// If spec has a custom target, use querySelector on document
/// Otherwise, use the new_el's id to find the target
pub fn find_oob_target(new_el : @dom.Element, spec : OobSpec) -> @dom.Element? {
  match spec.target {
    Some(selector) => @dom.document().querySelector(selector)
    None =>
      match new_el.getAttribute("id") {
        Some(id) => {
          let doc_selector = "#\{id}"
          @dom.document().querySelector(doc_selector)
        }
        None => None
      }
  }
}
