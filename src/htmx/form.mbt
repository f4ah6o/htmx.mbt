///|
/// Form data collection utilities for htmx

///|
/// Create FormData from a form element using JS constructor
extern "js" fn form_data_from_element(element : @dom.Element) -> @http.FormData =
  #|(el) => new FormData(el)

///|
/// Create an empty FormData
extern "js" fn new_form_data() -> @http.FormData =
  #|() => new FormData()

///|
/// Get all form input values as key-value pairs (includes element itself if it's an input)
pub fn collect_input_values(form : @dom.Element) -> Array[(String, String)] {
  collect_input_values_inner(form)
}

///|
/// Internal FFI to collect input values
extern "js" fn collect_input_values_inner(
  form : @dom.Element,
) -> Array[(String, String)] =
  #|(form) => {
  #|  const result = [];
  #|
  #|  // Helper to process a single element
  #|  const processElement = (el) => {
  #|    if (!el || !el.getAttribute) return;
  #|    const name = el.getAttribute('name');
  #|    if (name && name.length > 0) {
  #|      const tag = el.tagName && el.tagName.toUpperCase();
  #|      if (tag === 'INPUT') {
  #|        const type = (el.getAttribute('type') || 'text').toLowerCase();
  #|        if (type === 'checkbox' || type === 'radio') {
  #|          if (el.checked) {
  #|            const value = el.getAttribute('value') || 'on';
  #|            result.push({ _0: name, _1: value });
  #|          }
  #|        } else if (type === 'file') {
  #|          // Skip file inputs
  #|        } else {
  #|          const value = el.value || '';
  #|          result.push([name, value]);
  #|        }
  #|      } else if (tag === 'SELECT' || tag === 'TEXTAREA') {
  #|        const value = el.value || '';
  #|        result.push([name, value]);
  #|      }
  #|    }
  #|  };
  #|
  #|  // Process the form element itself if it's an input
  #|  const formTag = form.tagName && form.tagName.toUpperCase();
  #|  if (formTag === 'INPUT' || formTag === 'SELECT' || formTag === 'TEXTAREA') {
  #|    processElement(form);
  #|  }
  #|
  #|  // Process all child input elements
  #|  const inputs = form.querySelectorAll('input, select, textarea');
  #|  console.log('[htmx.mbt FORM] collect_input_values on', form.tagName, 'found', inputs.length, 'inputs');
  #|  for (const el of inputs) {
  #|    processElement(el);
  #|  }
  #|
  #|  // NEW: Include elements with form attribute referencing this form
  #|  const formId = form.getAttribute('id');
  #|  if (formId) {
  #|    const externalInputs = document.querySelectorAll(`input[form="${formId}"], select[form="${formId}"], textarea[form="${formId}"], button[form="${formId}"]`);
  #|    for (const el of externalInputs) {
  #|      processElement(el);
  #|    }
  #|  }
  #|
  #|  console.log('[htmx.mbt FORM] collected result:', result);
  #|  // Return as MoonBit Array structure
  #|  return { buf: result, start: 0, end: result.length };
  #|}

///|
/// Get value from an input element
fn get_input_value(element : @dom.Element) -> String? {
  let tag = element.tagName().to_upper()
  match tag {
    "INPUT" => {
      let input_type = element.getAttribute("type").unwrap_or("text").to_lower()
      match input_type {
        "checkbox" | "radio" =>
          // Only include if checked
          if element.hasAttribute("checked") {
            Some(element.getAttribute("value").unwrap_or("on"))
          } else {
            // Check property instead of attribute for runtime state
            let checked = get_element_checked(element)
            if checked {
              Some(element.getAttribute("value").unwrap_or("on"))
            } else {
              None
            }
          }
        "file" => None // Skip file inputs for now
        _ => Some(get_element_value(element))
      }
    }
    "SELECT" | "TEXTAREA" => Some(get_element_value(element))
    _ => None
  }
}

///|
/// Get element.value property
extern "js" fn get_element_value(element : @dom.Element) -> String =
  #|(el) => el.value || ""

///|
/// Get element.checked property
extern "js" fn get_element_checked(element : @dom.Element) -> Bool =
  #|(el) => !!el.checked

///|
/// Convert values to URL-encoded string for GET requests
pub fn values_to_query_string(values : Array[(String, String)]) -> String {
  if values.length() == 0 {
    return ""
  }
  let parts : Array[String] = []
  for pair in values {
    let (name, value) = pair
    let encoded_name = url_encode(name)
    let encoded_value = url_encode(value)
    parts.push("\{encoded_name}=\{encoded_value}")
  }
  parts.join("&")
}

///|
/// Simple URL encoding
extern "js" fn url_encode(s : String) -> String =
  #|(s) => encodeURIComponent(s)

///|
/// Build FormData from key-value pairs
pub fn build_form_data(values : Array[(String, String)]) -> @http.FormData {
  let fd = new_form_data()
  for pair in values {
    let (name, value) = pair
    fd.append(name, value)
  }
  fd
}

///|
/// Get FormData from a form element  
pub fn get_form_data(element : @dom.Element) -> @http.FormData? {
  let tag = element.tagName().to_upper()
  if tag == "FORM" {
    return Some(form_data_from_element(element))
  }

  // Look for parent form
  match element.closest("form") {
    Some(form) => Some(form_data_from_element(form))
    None => None
  }
}

///|
/// Append query string to URL
pub fn append_query_string(url : String, query : String) -> String {
  if query.length() == 0 {
    return url
  }
  if url.contains("?") {
    "\{url}&\{query}"
  } else {
    "\{url}?\{query}"
  }
}

///|
/// Append hx-vars values to FormData (vars override form values)
extern "js" fn append_vars_to_form_data(
  form_data : @http.FormData,
  vars_map : @core.Any,
) -> Unit =
  #|(form_data, vars_map) => {
  #|  // vars_map is a MoonBit Map with { buf: [{_0: key, _1: value}, ...], start, end }
  #|  if (vars_map && vars_map.buf) {
  #|    for (let i = vars_map.start || 0; i < (vars_map.end || vars_map.buf.length); i++) {
  #|      const entry = vars_map.buf[i];
  #|      if (entry && entry._0 !== undefined) {
  #|        const key = entry._0;
  #|        const value = entry._1;
  #|        // Remove existing value (vars override form values)
  #|        form_data.delete(key);
  #|        // Add the vars value
  #|        form_data.append(key, value);
  #|      }
  #|    }
  #|  }
  #|}

///|
/// Append hx-vars values to URL query string (vars override form values)
extern "js" fn append_vars_to_url(url : String, vars_map : @core.Any) -> String =
  #|(url, vars_map) => {
  #|  // vars_map is a MoonBit Map with { buf: [{_0: key, _1: value}, ...], start, end }
  #|  let params = [];
  #|  if (vars_map && vars_map.buf) {
  #|    for (let i = vars_map.start || 0; i < (vars_map.end || vars_map.buf.length); i++) {
  #|      const entry = vars_map.buf[i];
  #|      if (entry && entry._0 !== undefined) {
  #|        const key = encodeURIComponent(entry._0);
  #|        const value = encodeURIComponent(entry._1);
  #|        params.push(key + '=' + value);
  #|      }
  #|    }
  #|  }
  #|  if (params.length === 0) return url;
  #|  const separator = url.includes('?') ? '&' : '?';
  #|  return url + separator + params.join('&');
  #|}

///|
/// Create FormData from vars_map
extern "js" fn create_form_data_from_vars(
  vars_map : @core.Any,
) -> @http.FormData =
  #|(vars_map) => {
  #|  const fd = new FormData();
  #|  // vars_map is a MoonBit Map with { buf: [{_0: key, _1: value}, ...], start, end }
  #|  if (vars_map && vars_map.buf) {
  #|    for (let i = vars_map.start || 0; i < (vars_map.end || vars_map.buf.length); i++) {
  #|      const entry = vars_map.buf[i];
  #|      if (entry && entry._0 !== undefined) {
  #|        fd.append(entry._0, entry._1);
  #|      }
  #|    }
  #|  }
  #|  return fd;
  #|}

///|
/// Create FormData from input values and vars (vars override input values)
extern "js" fn create_form_data_from_inputs_and_vars(
  element : @dom.Element,
  vars_map : @core.Any,
) -> @http.FormData =
  #|(element, vars_map) => {
  #|  const fd = new FormData();
  #|
  #|  // Collect input values from element
  #|  // First, check if element itself is an input/select/textarea
  #|  const tag = element.tagName.toUpperCase();
  #|  if (tag === 'INPUT' || tag === 'SELECT' || tag === 'TEXTAREA') {
  #|    const name = element.getAttribute('name');
  #|    if (name && name.length > 0) {
  #|      let value = null;
  #|      if (tag === 'INPUT') {
  #|        const type = element.getAttribute('type') || 'text';
  #|        if (type === 'checkbox' || type === 'radio') {
  #|          if (element.checked) {
  #|            value = element.value || 'on';
  #|          }
  #|        } else if (type !== 'file') {
  #|          value = element.value || '';
  #|        }
  #|      } else {
  #|        value = element.value || '';
  #|      }
  #|      if (value !== null) {
  #|        fd.append(name, value);
  #|      }
  #|    }
  #|  }
  #|
  #|  // Then collect from child elements
  #|  const inputs = element.querySelectorAll('input, select, textarea');
  #|  for (const input of inputs) {
  #|    const name = input.getAttribute('name');
  #|    if (name && name.length > 0) {
  #|      let value = null;
  #|      const tag = input.tagName.toUpperCase();
  #|      if (tag === 'INPUT') {
  #|        const type = input.getAttribute('type') || 'text';
  #|        if (type === 'checkbox' || type === 'radio') {
  #|          if (input.checked) {
  #|            value = input.value || 'on';
  #|          }
  #|        } else if (type === 'file') {
  #|          // Skip file inputs
  #|          continue;
  #|        } else {
  #|          value = input.value || '';
  #|        }
  #|      } else if (tag === 'SELECT') {
  #|        value = input.value || '';
  #|      } else if (tag === 'TEXTAREA') {
  #|        value = input.value || '';
  #|      }
  #|      if (value !== null) {
  #|        fd.append(name, value);
  #|      }
  #|    }
  #|  }
  #|
  #|  // Add vars values (vars override input values)
  #|  if (vars_map && vars_map.buf) {
  #|    for (let i = vars_map.start || 0; i < (vars_map.end || vars_map.buf.length); i++) {
  #|      const entry = vars_map.buf[i];
  #|      if (entry && entry._0 !== undefined) {
  #|        const key = entry._0;
  #|        const value = entry._1;
  #|        // Remove existing value (vars override input values)
  #|        fd.delete(key);
  #|        // Add the vars value
  #|        fd.append(key, value);
  #|      }
  #|    }
  #|  }
  #|
  #|  return fd;
  #|}
