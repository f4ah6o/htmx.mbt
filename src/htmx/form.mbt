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
/// Get all form input values as key-value pairs
pub fn collect_input_values(form : @dom.Element) -> Array[(String, String)] {
  let result : Array[(String, String)] = []

  // Query all input, select, textarea elements
  let inputs = form.querySelectorAll("input, select, textarea")
  for element in inputs {
    match element.getAttribute("name") {
      Some(name) if name.length() > 0 => {
        // Get value based on element type
        let value = get_input_value(element)
        match value {
          Some(v) => result.push((name, v))
          None => ()
        }
      }
      _ => ()
    }
  }
  result
}

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
