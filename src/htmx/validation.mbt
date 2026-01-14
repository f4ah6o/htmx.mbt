///|
/// Form validation support for htmx
/// Implements HTML5 form validation with htmx events

///|
/// FFI for form validation
extern "js" fn form_check_validity(form : @dom.Element) -> Bool =
  #|(form) => form.checkValidity ? form.checkValidity() : true

///|
extern "js" fn form_report_validity(form : @dom.Element) -> Bool =
  #|(form) => form.reportValidity ? form.reportValidity() : true

///|
extern "js" fn element_check_validity(el : @dom.Element) -> Bool =
  #|(el) => el.checkValidity ? el.checkValidity() : true

///|
extern "js" fn has_novalidate(form : @dom.Element) -> Bool =
  #|(form) => form.hasAttribute('novalidate')

///|
extern "js" fn has_hx_validate(el : @dom.Element) -> Bool =
  #|(el) => el.hasAttribute('hx-validate') || el.hasAttribute('data-hx-validate')

///|
/// Dispatch htmx:validation:validate event on each input element in form
extern "js" fn dispatch_validate_events(form : @dom.Element) -> Unit =
  #|(form) => {
  #|  // Get all form inputs and dispatch validation:validate event on each
  #|  const inputs = form.querySelectorAll('input, select, textarea');
  #|  for (let i = 0; i < inputs.length; i++) {
  #|    const evt = new CustomEvent('htmx:validation:validate', { bubbles: true, cancelable: true });
  #|    inputs[i].dispatchEvent(evt);
  #|  }
  #|}

///|
/// Dispatch htmx:validation:validate event on a single element
extern "js" fn dispatch_validate_event(el : @dom.Element) -> Unit =
  #|(el) => {
  #|  const evt = new CustomEvent('htmx:validation:validate', { bubbles: true, cancelable: true });
  #|  el.dispatchEvent(evt);
  #|}

///|
/// Get invalid elements from form after validate events have been dispatched
extern "js" fn get_invalid_elements(form : @dom.Element) -> Array[@dom.Element] =
  #|(form) => {
  #|  if (!form.querySelectorAll) return [];
  #|  const invalids = [];
  #|  const inputs = form.querySelectorAll('input, select, textarea');
  #|  for (let i = 0; i < inputs.length; i++) {
  #|    if (inputs[i].checkValidity && !inputs[i].checkValidity()) {
  #|      invalids.push(inputs[i]);
  #|    }
  #|  }
  #|  return invalids;
  #|}

///|
/// Get validation message from an element
extern "js" fn get_validation_message(el : @dom.Element) -> String =
  #|(el) => el.validationMessage || ''

///|
/// Dispatch htmx:validation:failed event on an invalid element
extern "js" fn dispatch_validation_failed_event(
  target : @dom.Element,
  detail : @core.Any,
) -> Bool =
  #|(target, detail) => {
  #|  const evt = new CustomEvent('htmx:validation:failed', {
  #|    bubbles: true,
  #|    cancelable: true,
  #|    detail: detail
  #|  });
  #|  return target.dispatchEvent(evt);
  #|}

///|
/// Dispatch htmx:validation:failed event on form with errors array
extern "js" fn dispatch_validation_failed_on_form(form : @dom.Element, errors : @core.Any) -> Bool =
  #|(form, errors) => {
  #|  const evt = new CustomEvent('htmx:validation:failed', {
  #|    bubbles: true,
  #|    cancelable: true,
  #|    detail: { errors: errors }
  #|  });
  #|  return form.dispatchEvent(evt);
  #|}

///|
/// Dispatch htmx:validation:halted event on form with errors array
extern "js" fn dispatch_validation_halted(form : @dom.Element, errors : @core.Any) -> Unit =
  #|(form, errors) => {
  #|  const evt = new CustomEvent('htmx:validation:halted', {
  #|    bubbles: true,
  #|    cancelable: true,
  #|    detail: { errors: errors }
  #|  });
  #|  form.dispatchEvent(evt);
  #|}

///|
extern "js" fn get_element_validity(el : @dom.Element) -> @core.Any =
  #|(el) => el.validity || {}

///|
extern "js" fn focus_element(el : @dom.Element) -> Unit =
  #|(el) => { if (el.focus) el.focus(); }

///|
extern "js" fn dispatch_validation_event(
  target : @dom.Element,
  event_name : String,
  detail : @core.Any,
) -> Bool =
  #|(target, event_name, detail) => {
  #|  const evt = new CustomEvent(event_name, {
  #|    bubbles: true,
  #|    cancelable: true,
  #|    detail: detail
  #|  });
  #|  return target.dispatchEvent(evt);
  #|}

///|
extern "js" fn create_errors_array(invalids : Array[@dom.Element]) -> @core.Any =
  #|(invalids) => {
  #|  return invalids.map(el => ({
  #|    elt: el,
  #|    message: el.validationMessage || '',
  #|    validity: el.validity || {}
  #|  }));
  #|}

///|
extern "js" fn get_config_report_validity() -> Bool =
  #|() => window.htmx && window.htmx.config && window.htmx.config.reportValidityOfForms === true

///|
/// Validate an htmx element before making a request
/// Returns true if validation passes (or is skipped), false if validation fails
pub fn validate_element(element : @dom.Element) -> Bool {
  let tag = element.tagName().to_lower()

  // For non-form elements with hx-validate, check the element itself
  if tag != "form" && has_hx_validate(element) {
    // Dispatch validation:validate event first
    dispatch_validate_event(element)
    // Then check validity
    if not(element_check_validity(element)) {
      // Dispatch validation:failed event on the element
      let detail = @core.new_object()
      detail._set("elt", element.as_any())
      detail._set("message", @core.new_object())
      let _ = dispatch_validation_failed_event(element, detail)
      return false
    }
    return true
  }

  // For form elements, check novalidate first
  if tag == "form" {
    if has_novalidate(element) {
      return true
    }

    // Step 1: Dispatch htmx:validation:validate event for each input
    // This allows scripts (like hyperscript) to modify validity via setCustomValidity
    dispatch_validate_events(element)

    // Step 2: Check which inputs are now invalid
    let invalids = get_invalid_elements(element)
    if invalids.length() > 0 {
      // Create errors array for htmx:validation:halted
      let errors = create_errors_array(invalids)

      // Step 3: Dispatch htmx:validation:halted on the form with errors array
      dispatch_validation_halted(element, errors)

      // Report validity if configured
      if get_config_report_validity() {
        // Focus first invalid element
        let first = invalids[0]
        focus_element(first)
        let _ = form_report_validity(element)
      }
      return false
    }
  }
  true
}

///|
/// Check if the triggering element has formnovalidate
extern "js" fn has_formnovalidate(trigger_el : @dom.Element) -> Bool =
  #|(el) => { try { return el && (el.hasAttribute('formnovalidate') || el.formnovalidate === true); } catch(e) { return false; } }

///|
/// Validate an htmx element before making a request
/// trigger_el is the element that triggered the action (may have formnovalidate)
/// Returns true if validation passes (or is skipped), false if validation fails
pub fn validate_element_with_trigger(
  element : @dom.Element,
  trigger_el : @dom.Element?,
) -> Bool {
  // Check if trigger element has formnovalidate
  match trigger_el {
    Some(trig) => if has_formnovalidate(trig) { return true }
    None => ()
  }
  validate_element(element)
}
