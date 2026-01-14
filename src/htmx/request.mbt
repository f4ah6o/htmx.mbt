///|
/// HTTP methods supported by htmx
pub enum HttpMethod {
  Get
  Post
  Put
  Delete
  Patch
}

///|
/// Convert method to string
pub fn HttpMethod::to_string(self : HttpMethod) -> String {
  match self {
    Get => "GET"
    Post => "POST"
    Put => "PUT"
    Delete => "DELETE"
    Patch => "PATCH"
  }
}

///|
pub impl Show for HttpMethod with output(self, logger) {
  logger.write_string(self.to_string())
}

///|
/// Check if method sends a body
pub fn HttpMethod::has_body(self : HttpMethod) -> Bool {
  match self {
    Post | Put | Patch => true
    Get | Delete => false
  }
}

///|
/// Parse method from htmx attribute name
pub fn HttpMethod::from_attr(attr : String) -> HttpMethod? {
  match attr {
    "hx-get" => Some(Get)
    "hx-post" => Some(Post)
    "hx-put" => Some(Put)
    "hx-delete" => Some(Delete)
    "hx-patch" => Some(Patch)
    _ => Option::None
  }
}

///|
/// XMLHttpRequest FFI bindings for Sinon compatibility
extern "js" fn create_xhr() -> @core.Any =
  #|() => new XMLHttpRequest()

///|
extern "js" fn xhr_open(
  xhr : @core.Any,
  method_ : String,
  url : String,
  async_ : Bool,
) -> Unit =
  #|(xhr, method_, url, async_) => xhr.open(method_, url, async_)

///|
extern "js" fn xhr_set_header(
  xhr : @core.Any,
  name : String,
  value : String,
) -> Unit =
  #|(xhr, name, value) => xhr.setRequestHeader(name, value)

///|
extern "js" fn xhr_send(xhr : @core.Any, body : @core.Any) -> Unit =
  #|(xhr, body) => xhr.send(body)

///|
extern "js" fn xhr_send_no_body(xhr : @core.Any) -> Unit =
  #|(xhr) => xhr.send()

///|
extern "js" fn xhr_get_response(xhr : @core.Any) -> String =
  #|(xhr) => xhr.responseText || ''

///|
extern "js" fn xhr_get_status(xhr : @core.Any) -> Int =
  #|(xhr) => xhr.status

///|
/// Standard htmx request headers
fn get_htmx_headers(trigger_element : @dom.Element?) -> Map[String, String] {
  let headers : Map[String, String] = { "HX-Request": "true" }
  match trigger_element {
    Some(el) => {
      match el.getAttribute("id") {
        Some(id) => headers["HX-Trigger"] = id
        None => ()
      }
      match el.getAttribute("name") {
        Some(name) => headers["HX-Trigger-Name"] = name
        None => ()
      }
    }
    None => ()
  }
  headers
}

///|
/// Perform synchronous XHR request (for Sinon mock server compatibility)
pub fn request_sync(
  url : String,
  http_method : HttpMethod,
  trigger_element : @dom.Element?,
) -> String? {
  let xhr = create_xhr()
  xhr_open(xhr, http_method.to_string(), url, false)
  let headers = get_htmx_headers(trigger_element)
  headers.each(fn(name, value) { xhr_set_header(xhr, name, value) })
  xhr_send_no_body(xhr)
  let status = xhr_get_status(xhr)
  if status >= 200 && status < 300 {
    Some(xhr_get_response(xhr))
  } else {
    None
  }
}

///|
/// Perform synchronous XHR request with FormData body
pub fn request_with_form_sync(
  url : String,
  http_method : HttpMethod,
  form_data : @http.FormData?,
  trigger_element : @dom.Element?,
) -> String? {
  let xhr = create_xhr()
  xhr_open(xhr, http_method.to_string(), url, false)
  let headers = get_htmx_headers(trigger_element)
  headers.each(fn(name, value) { xhr_set_header(xhr, name, value) })
  match form_data {
    Some(fd) => xhr_send(xhr, fd.as_any())
    None => xhr_send_no_body(xhr)
  }
  let status = xhr_get_status(xhr)
  if status >= 200 && status < 300 {
    Some(xhr_get_response(xhr))
  } else {
    None
  }
}

///|
/// Perform async XHR request with callback (for proper disabled-elt behavior)
/// The callback receives a String? (the response text or null on error)
extern "js" fn request_async_callback(
  url : String,
  method_str : String,
  trigger_element : @dom.Element?,
  headers_map : @core.Any,
  callback : @core.Any,
) -> Unit =
  #|(url, method_str, trigger_element, headers_map, callback) => {
  #|  const xhr = new XMLHttpRequest();
  #|  xhr.open(method_str, url, true);
  #|
  #|  // Set headers from map
  #|  const headers = headers_map;
  #|  for (const [key, value] of Object.entries(headers)) {
  #|    xhr.setRequestHeader(key, value);
  #|  }
  #|
  #|  xhr.onload = function() {
  #|    if (xhr.status >= 200 && xhr.status < 300) {
  #|      callback(xhr.responseText || '');
  #|    } else {
  #|      callback(null);
  #|    }
  #|  };
  #|
  #|  xhr.onerror = function() {
  #|    callback(null);
  #|  };
  #|
  #|  xhr.send();
  #|}

///|
/// Perform async XHR request with FormData body and callback
extern "js" fn request_with_form_async_callback(
  url : String,
  method_str : String,
  form_data_any : @core.Any,
  trigger_element : @dom.Element?,
  headers_map : @core.Any,
  callback : @core.Any,
) -> Unit =
  #|(url, method_str, form_data_any, trigger_element, headers_map, callback) => {
  #|  const xhr = new XMLHttpRequest();
  #|  xhr.open(method_str, url, true);
  #|
  #|  // Set headers from map
  #|  const headers = headers_map;
  #|  for (const [key, value] of Object.entries(headers)) {
  #|    xhr.setRequestHeader(key, value);
  #|  }
  #|
  #|  xhr.onload = function() {
  #|    if (xhr.status >= 200 && xhr.status < 300) {
  #|      callback(xhr.responseText || '');
  #|    } else {
  #|      callback(null);
  #|    }
  #|  };
  #|
  #|  xhr.onerror = function() {
  #|    callback(null);
  #|  };
  #|
  #|  xhr.send(form_data_any);
  #|}

///|
/// Convert headers Map to JavaScript object for passing to extern functions
extern "js" fn map_to_js_object(m : Map[String, String]) -> @core.Any =
  #|(m) => {
  #|  const obj = {};
  #|  // MoonBit Map has { buf: [{_0: key, _1: value}, ...], start, end } structure
  #|  if (m && m.buf) {
  #|    for (let i = m.start || 0; i < (m.end || m.buf.length); i++) {
  #|      const entry = m.buf[i];
  #|      if (entry && entry._0 !== undefined) {
  #|        obj[entry._0] = entry._1;
  #|      }
  #|    }
  #|  }
  #|  return obj;
  #|}

///|
/// Async request without body using callback
pub fn request_async(
  url : String,
  http_method : HttpMethod,
  trigger_element : @dom.Element?,
  callback : @core.Any,
) -> Unit {
  let headers = get_htmx_headers(trigger_element)
  let headers_obj = map_to_js_object(headers)
  request_async_callback(url, http_method.to_string(), trigger_element, headers_obj, callback)
}

///|
/// Async request with FormData body using callback
pub fn request_with_form_async(
  url : String,
  http_method : HttpMethod,
  form_data : @http.FormData?,
  trigger_element : @dom.Element?,
  callback : @core.Any,
) -> Unit {
  let headers = get_htmx_headers(trigger_element)
  let headers_obj = map_to_js_object(headers)
  match form_data {
    Some(fd) => request_with_form_async_callback(url, http_method.to_string(), fd.as_any(), trigger_element, headers_obj, callback)
    None => request_async_callback(url, http_method.to_string(), trigger_element, headers_obj, callback)
  }
}

///|
/// Perform HTTP request with optional FormData body (async version)
pub async fn request_with_form(
  url : String,
  http_method : HttpMethod,
  form_data : @http.FormData?,
  trigger_element : @dom.Element?,
) -> String {
  let headers = get_htmx_headers(trigger_element)
  match form_data {
    Some(fd) => {
      let body = fd.as_any()
      let response = @http.fetch(
        url,
        method_=http_method.to_string(),
        headers~,
        body~,
      )
      response.text()
    }
    None => {
      let response = @http.fetch(url, method_=http_method.to_string(), headers~)
      response.text()
    }
  }
}

///|
/// Perform HTTP request (simple version without body)
pub async fn request(url : String, http_method : HttpMethod) -> String {
  let headers : Map[String, String] = { "HX-Request": "true" }
  let response = @http.fetch(url, method_=http_method.to_string(), headers~)
  response.text()
}

///|
/// Wrapper that converts request to a noraise async by catching errors
pub async fn request_safe(
  url : String,
  http_method : HttpMethod,
) -> String? noraise {
  Some(request(url, http_method)) catch {
    _ => None
  }
}

///|
/// Safe version of request_with_form
pub async fn request_with_form_safe(
  url : String,
  http_method : HttpMethod,
  form_data : @http.FormData?,
  trigger_element : @dom.Element?,
) -> String? noraise {
  Some(request_with_form(url, http_method, form_data, trigger_element)) catch {
    _ => None
  }
}
