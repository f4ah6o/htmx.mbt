///|
/// Response processing for htmx (parsing, OOB, hx-select)

///|
/// Process HTTP response content
/// - Parses HTML
/// - Handles Out-Of-Band swaps (hx-swap-oob)
/// - Handles hx-select filtering
/// - Returns final content to be swapped into target
pub fn process_response(content : String, select : String?) -> String {
  // 1. Parse content into a temporary container
  let doc = @dom.document()
  let temp_div = doc.createElement("div")
  temp_div.setInnerHTML(content)

  // 2. Handle Out-Of-Band swaps
  process_oob_swaps(temp_div)

  // 3. Handle hx-select filtering
  match select {
    Some(selector) =>
      match temp_div.querySelector(selector) {
        Some(selected_el) => get_outer_html(selected_el)
        None =>
          // If selector matches nothing, return empty or full?
          // htmx default behavior is to do nothing or return empty if selector fails
          ""
      }
    None => get_inner_html(temp_div)
  }
}

///|
/// Process Out-Of-Band swaps
/// Finds elements with hx-swap-oob and swaps them into the main DOM
/// Supports both simple (hx-swap-oob="true") and complex (hx-swap-oob="innerHTML:#target") syntax
fn process_oob_swaps(container : @dom.Element) -> Unit {
  let oob_elements = container.querySelectorAll("[hx-swap-oob]")
  for el in oob_elements {
    let oob_val = el.getAttribute("hx-swap-oob").unwrap_or("true")

    // Parse OOB specification
    let spec = parse_oob_spec(oob_val)

    // Find target element
    match find_oob_target(el, spec) {
      Some(target_el) => {
        execute_oob_swap(el, target_el, spec)
        // Remove from response content
        el.remove()
      }
      None => {
        // Dispatch error event when target not found
        dispatch_oob_error_no_target(el)
        // Still remove OOB element from response content
        el.remove()
      }
    }
  }
}

///|
/// Get innerHTML property
extern "js" fn get_inner_html(element : @dom.Element) -> String =
  #|(el) => el.innerHTML

///|
/// Get outerHTML property
extern "js" fn get_outer_html(element : @dom.Element) -> String =
  #|(el) => el.outerHTML

///|
/// Dispatch htmx:oobErrorNoTarget event when OOB target not found
extern "js" fn dispatch_oob_error_no_target(oob_el : @dom.Element) -> Unit =
  #|(oobEl) => {
  #|  const evt = new CustomEvent('htmx:oobErrorNoTarget', {
  #|    bubbles: true,
  #|    cancelable: true,
  #|    detail: { content: oobEl }
  #|  });
  #|  document.body.dispatchEvent(evt);
  #|}
