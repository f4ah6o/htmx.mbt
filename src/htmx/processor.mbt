///|
/// Process a single htmx element - perform request and swap (synchronous for Sinon compatibility)
fn process_element_with_trigger(
  element : @dom.Element,
  trigger_el : @dom.Element?,
) -> Unit {
  // Find method and URL
  let method_url = find_method_url(element)
  guard method_url is Some((http_method, url)) else { return }

  // Validate form before making request (pass trigger element for formnovalidate check)
  if not(validate_element_with_trigger(element, trigger_el)) {
    return
  }

  // Get target and swap style
  let target = get_target(element)
  let swap_style = get_swap_style(element)

  // Handle form data for POST/PUT/PATCH
  let response = if http_method.has_body() {
    // Collect form data for methods that have a body
    let form_data = get_form_data(element)
    request_with_form_sync(url, http_method, form_data, Some(element))
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
    request_sync(actual_url, http_method, Some(element))
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
    None => ()
  }
}

///|
/// Wrapper for process element (kept for API compatibility)
fn process_element(element : @dom.Element) -> Unit {
  process_element_with_trigger(element, None)
}

///|
/// FFI to get event target directly
extern "js" fn get_event_target(evt : @core.Any) -> @dom.Element =
  #|(evt) => evt.target

///|
/// Check if element is a submit button
extern "js" fn is_submit_button(el : @dom.Element) -> Bool =
  #|(el) => el && el.tagName === 'BUTTON' && (el.type === 'submit' || !el.type)

///|
/// Find the closest form ancestor using FFI
extern "js" fn find_closest_form(el : @dom.Element) -> @dom.Element =
  #|(el) => el.form || el.closest('form')

///|
/// Check if element has a containing form
extern "js" fn has_containing_form(el : @dom.Element) -> Bool =
  #|(el) => !!(el.form || el.closest('form'))

///|
/// Handle click events for htmx elements
fn handle_click(evt : @core.Any) -> Unit {
  let event : @event.Event = @core.identity(evt)
  let target_el = get_event_target(evt)

  // Check if clicking a submit button inside an htmx form
  if is_submit_button(target_el) {
    if has_containing_form(target_el) {
      let form = find_closest_form(target_el)
      // Check if form itself has an htmx method attribute
      match find_method_url(form) {
        Some(_) => {
          // Submit buttons should always submit the form, regardless of hx-trigger
          // The form's hx-trigger only affects what events automatically trigger,
          // not explicit user action of clicking a submit button
          event.preventDefault()
          // Pass the button as submitter for formnovalidate check
          process_element_with_trigger(form, Some(target_el))
          return
        }
        None => ()
      }
    }
  }

  // Find htmx element and handle click trigger
  match find_htmx_element(target_el) {
    Some(htmx_el) => {
      let trigger = get_trigger_event(htmx_el)
      if trigger == "click" {
        event.preventDefault()
        process_element_with_trigger(htmx_el, Some(target_el))
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
/// Get submitter from submit event
extern "js" fn get_event_submitter(evt : @core.Any) -> @dom.Element? =
  #|(evt) => evt.submitter || null

///|
/// Handle submit events for htmx forms
fn handle_submit(evt : @core.Any) -> Unit {
  let event : @event.Event = @core.identity(evt)
  let target_el = get_event_target(evt)
  let submitter = get_event_submitter(evt)
  match find_htmx_element(target_el) {
    Some(htmx_el) => {
      let trigger = get_trigger_event(htmx_el)
      if trigger == "submit" {
        event.preventDefault()
        // Pass submitter for formnovalidate check
        process_element_with_trigger(htmx_el, submitter)
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
}
