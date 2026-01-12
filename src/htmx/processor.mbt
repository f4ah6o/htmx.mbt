///|
/// Process a single htmx element - perform request and swap (noraise version)
async fn process_element_internal(element : @dom.Element) -> Unit noraise {
  // Find method and URL
  let method_url = find_method_url(element)
  guard method_url is Some((http_method, url)) else { return }

  // Get target and swap style
  let target = get_target(element)
  let swap_style = get_swap_style(element)

  // Handle form data for POST/PUT/PATCH
  @core.log(
    @core.any(
      "Processing element: \{element.tagName()} Method: \{http_method} URL: \{url}",
    ),
  )
  let response = if http_method.has_body() {
    // Collect form data for methods that have a body
    let form_data = get_form_data(element)
    request_with_form_safe(url, http_method, form_data, Some(element))
  } else {
    // For GET/DELETE, append form values as query params
    let actual_url = match get_form_data(element) {
      Some(fd) => {
        // Collect values and append to URL
        let values = collect_input_values(element)
        let query = values_to_query_string(values)
        let _ = fd // We don't use FormData for GET, just values
        append_query_string(url, query)
      }
      None => url
    }
    @core.log(@core.any("Sending request to: \{actual_url}"))
    request_safe(actual_url, http_method)
  }

  // Swap content if we got a response
  match response {
    Some(content) => {
      let select_val = get_select(element)
      let final_content = process_response(content, select_val)
      swap(target, final_content, swap_style)

      // Handle history API
      match get_push_url(element) {
        Some(push_val) =>
          if push_val != "false" {
            let dest_url = if push_val == "true" { url } else { push_val }
            push_url(dest_url)
          }
        None => ()
      }
    }
    None => @core.log(@core.any("htmx request failed"))
  }
}

///|
/// Wrapper to process element with no-raise for run_async
fn process_element(element : @dom.Element) -> Unit {
  @core.run_async(async fn() noraise { process_element_internal(element) })
}

///|
/// FFI to get event target directly
extern "js" fn get_event_target(evt : @core.Any) -> @dom.Element =
  #|(evt) => evt.target

///|
/// Handle click events for htmx elements
fn handle_click(evt : @core.Any) -> Unit {
  // Get event target directly via FFI
  let event : @event.Event = @core.identity(evt)
  let target_el = get_event_target(evt)

  // Find htmx element
  match find_htmx_element(target_el) {
    Some(htmx_el) => {
      // Check if trigger is click
      let trigger = get_trigger_event(htmx_el)
      if trigger == "click" {
        event.preventDefault()
        process_element(htmx_el)
      }
    }
    Option::None => ()
  }
}

///|
/// Handle change events for htmx elements
fn handle_change(evt : @core.Any) -> Unit {
  let event : @event.Event = @core.identity(evt)
  let target_el = get_event_target(evt)
  match find_htmx_element(target_el) {
    Some(htmx_el) => {
      let trigger = get_trigger_event(htmx_el)
      if trigger == "change" {
        event.preventDefault()
        process_element(htmx_el)
      }
    }
    Option::None => ()
  }
}

///|
/// Handle submit events for htmx forms
fn handle_submit(evt : @core.Any) -> Unit {
  let event : @event.Event = @core.identity(evt)
  let target_el = get_event_target(evt)
  match find_htmx_element(target_el) {
    Some(htmx_el) => {
      let trigger = get_trigger_event(htmx_el)
      if trigger == "submit" {
        event.preventDefault()
        process_element(htmx_el)
      }
    }
    Option::None => ()
  }
}

///|
/// Initialize htmx - set up global event listeners using event delegation
pub fn htmx_init() -> Unit {
  let doc = @dom.document()
  let doc_target = doc.as_event_target()

  // Use event delegation - listen on document for all events
  doc_target.addEventListener("click", handle_click)
  doc_target.addEventListener("change", handle_change)
  doc_target.addEventListener("submit", handle_submit)
  @core.log(@core.any("htmx.mbt initialized"))
}
