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
/// Parse method from HTTP method string (GET, POST, etc.)
pub fn HttpMethod::from_string(method : String) -> HttpMethod? {
  match method {
    "GET" => Some(Get)
    "POST" => Some(Post)
    "PUT" => Some(Put)
    "DELETE" => Some(Delete)
    "PATCH" => Some(Patch)
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
extern "js" fn get_htmx_headers(
  trigger_element : @dom.Element?,
  prompt_response : String?,
) -> Map[String, String] =
  #|(trigger_element, prompt_response) => {
  #|  // Unwrap MoonBit Option types
  #|  const element = (trigger_element && trigger_element.$tag === 1) ? trigger_element._0 : null;
  #|
  #|  // Start with default HX headers
  #|  const headers = { "HX-Request": "true" };
  #|
  #|  if (element) {
  #|    // Add HX-Trigger header from element id
  #|    const id = element.getAttribute("id");
  #|    if (id) {
  #|      headers["HX-Trigger"] = id;
  #|    }
  #|
  #|    // Add HX-Trigger-Name header from element name
  #|    const name = element.getAttribute("name");
  #|    if (name) {
  #|      headers["HX-Trigger-Name"] = name;
  #|    }
  #|
  #|    // Collect custom headers from hx-headers attribute (with inheritance)
  #|    // This logic is inlined here because get_headers_from_element is not accessible from FFI
  #|    const getAttributeValue = (el, attr) => {
  #|      if (!el) return null;
  #|      return el.getAttribute(attr) || el.getAttribute('data-' + attr);
  #|    };
  #|
  #|    const parseAttribute = (str) => {
  #|      // Wrap in braces if not already present
  #|      if (str.indexOf('{') !== 0) {
  #|        str = '{' + str + '}';
  #|      }
  #|      try {
  #|        return JSON.parse(str);
  #|      } catch (e) {
  #|        return {};
  #|      }
  #|    };
  #|
  #|    const evaluateAttribute = (elt, str) => {
  #|      // Wrap in braces if not already present
  #|      if (str.indexOf('{') !== 0) {
  #|        str = '{' + str + '}';
  #|      }
  #|      try {
  #|        return new Function('return (' + str + ')').call(elt);
  #|      } catch (e) {
  #|        return {};
  #|      }
  #|    };
  #|
  #|    const getHeadersForElement = (elt, hdrs, visited) => {
  #|      if (hdrs == null) {
  #|        hdrs = {};
  #|      }
  #|      if (elt == null) {
  #|        return hdrs;
  #|      }
  #|
  #|      // Safety check to prevent infinite loops using visited Set
  #|      if (!visited) {
  #|        visited = new Set();
  #|      }
  #|      if (visited.has(elt)) {
  #|        return hdrs;
  #|      }
  #|      visited.add(elt);
  #|
  #|      // First, collect from parent (so parent values come first)
  #|      const parent = elt.parentElement;
  #|      if (parent) {
  #|        getHeadersForElement(parent, hdrs, visited);
  #|      }
  #|
  #|      // Then, process current element (child values override parent values)
  #|      const attributeValue = getAttributeValue(elt, 'hx-headers');
  #|      if (attributeValue) {
  #|        let str = attributeValue.trim();
  #|        let evaluateValue = false;
  #|
  #|        // Check for 'unset' keyword
  #|        if (str === 'unset') {
  #|          // Clear all headers
  #|          for (const key in hdrs) {
  #|            if (hdrs.hasOwnProperty(key)) {
  #|              delete hdrs[key];
  #|            }
  #|          }
  #|          return hdrs;
  #|        }
  #|
  #|        // Check for javascript: or js: prefix (forces evaluation)
  #|        if (str.indexOf('javascript:') === 0) {
  #|          str = str.slice(11);
  #|          evaluateValue = true;
  #|        } else if (str.indexOf('js:') === 0) {
  #|          str = str.slice(3);
  #|          evaluateValue = true;
  #|        }
  #|
  #|        let headersValues;
  #|        if (evaluateValue) {
  #|          headersValues = evaluateAttribute(elt, str);
  #|        } else {
  #|          headersValues = parseAttribute(str);
  #|        }
  #|
  #|        // Child values override parent values
  #|        if (headersValues) {
  #|          for (const key in headersValues) {
  #|            if (headersValues.hasOwnProperty(key)) {
  #|              hdrs[key] = headersValues[key];
  #|            }
  #|          }
  #|        }
  #|      }
  #|      return hdrs;
  #|    };
  #|
  #|    const customHeaders = getHeadersForElement(element, {});
  #|
  #|    // Merge custom headers (custom headers override HX headers in case of conflict)
  #|    for (const key in customHeaders) {
  #|      if (customHeaders.hasOwnProperty(key)) {
  #|        headers[key] = customHeaders[key];
  #|      }
  #|    }
  #|  }
  #|
  #|  // Add HX-Prompt header if prompt response exists
  #|  const promptResponse = (prompt_response && prompt_response.$tag === 1) ? prompt_response._0 : null;
  #|  if (promptResponse !== null) {
  #|    headers["HX-Prompt"] = String(promptResponse);
  #|  }
  #|
  #|  // Convert to MoonBit Map format
  #|  return moonbitlang$core$builtin$$Map$from_array$14$(
  #|    Object.entries(headers).map(([k, v]) => ({ _0: k, _1: v }))
  #|  );
  #|}

///|
/// Perform synchronous XHR request (for Sinon mock server compatibility)
pub fn request_sync(
  url : String,
  http_method : HttpMethod,
  trigger_element : @dom.Element?,
  prompt_response : String?,
) -> String? {
  let xhr = create_xhr()
  xhr_open(xhr, http_method.to_string(), url, false)
  let headers = get_htmx_headers(trigger_element, prompt_response)
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
  prompt_response : String?,
) -> String? {
  let xhr = create_xhr()
  xhr_open(xhr, http_method.to_string(), url, false)
  let headers = get_htmx_headers(trigger_element, prompt_response)
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
/// Fire htmx:config-request event and return potentially modified parameters
pub extern "js" fn fire_config_request_event(
  element : @dom.Element,
  parameters : @core.Any,
  headers : @core.Any,
) -> Bool =
  #|(element, parameters, headers) => {
  #|  // Log for delay test debugging
  #|  if (element.id === 'test') {
  #|    console.log('[htmx.mbt CONFIG] ========== DELAY TEST: fire_config_request_event called! ==========');
  #|    console.log('[htmx.mbt CONFIG] element.id:', element.id);
  #|    console.log('[htmx.mbt CONFIG] parameters:', parameters);
  #|  }
  #|  // Create a plain JavaScript object for parameters
  #|  const plainParams = {};
  #|  if (parameters && parameters.buf && Array.isArray(parameters.buf)) {
  #|    // Moonbit Map structure
  #|    for (let i = parameters.start || 0; i < (parameters.end || parameters.buf.length); i++) {
  #|      const entry = parameters.buf[i];
  #|      if (entry && entry._0 !== undefined) {
  #|        plainParams[entry._0] = entry._1;
  #|      }
  #|    }
  #|  } else if (parameters && typeof parameters === 'object') {
  #|    for (const key in parameters) {
  #|      if (parameters.hasOwnProperty(key)) {
  #|        plainParams[key] = parameters[key];
  #|      }
  #|    }
  #|  }
  #|  // Create a plain JavaScript object for headers
  #|  const plainHeaders = {};
  #|  if (headers && headers.buf && Array.isArray(headers.buf)) {
  #|    // Moonbit Map structure
  #|    for (let i = headers.start || 0; i < (headers.end || headers.buf.length); i++) {
  #|      const entry = headers.buf[i];
  #|      if (entry && entry._0 !== undefined) {
  #|        plainHeaders[entry._0] = entry._1;
  #|      }
  #|    }
  #|  } else if (headers && typeof headers === 'object') {
  #|    for (const key in headers) {
  #|      if (headers.hasOwnProperty(key)) {
  #|        plainHeaders[key] = headers[key];
  #|      }
  #|    }
  #|  }
  #|  // Create detail object for the event
  #|  const detail = {
  #|    parameters: plainParams,
  #|    headers: plainHeaders,
  #|    target: element
  #|  };
  #|
  #|  // Dispatch kebab-case version
  #|  const evt1 = new CustomEvent('htmx:config-request', {
  #|    bubbles: true,
  #|    cancelable: true,
  #|    detail: detail
  #|  });
  #|  const result1 = element.dispatchEvent(evt1);
  #|
  #|  // Dispatch camelCase version (htmx:configRequest)
  #|  const evt2 = new CustomEvent('htmx:configRequest', {
  #|    bubbles: true,
  #|    cancelable: true,
  #|    detail: detail
  #|  });
  #|  const result2 = element.dispatchEvent(evt2);
  #|
  #|  // Return false only if BOTH were prevented (htmx.org behavior)
  #|  const result = result1 && result2;
  #|  // Copy modified parameters back to the original parameters object
  #|  // Clear the buf and add new entries
  #|  if (parameters && parameters.buf !== undefined) {
  #|    parameters.buf = [];
  #|    parameters.start = 0;
  #|    let idx = 0;
  #|    for (const key in plainParams) {
  #|      if (plainParams.hasOwnProperty(key)) {
  #|        parameters.buf[idx] = { _0: key, _1: plainParams[key] };
  #|        idx++;
  #|      }
  #|    }
  #|    parameters.end = idx;
  #|  }
  #|  // Return false if event was prevented
  #|  return result;
  #|}

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
  #|  // Set headers from map
  #|  const headers = headers_map;
  #|  for (const [key, value] of Object.entries(headers)) {
  #|    xhr.setRequestHeader(key, value);
  #|  }
  #|  xhr.onload = function() {
  #|    if (xhr.status >= 200 && xhr.status < 300) {
  #|      callback(xhr.responseText || '');
  #|    } else {
  #|      callback(null);
  #|    }
  #|  };
  #|  xhr.onerror = function() {
  #|    callback(null);
  #|  };
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
  #|  // Convert FormData to URL-encoded string for Sinon compatibility
  #|  let body = form_data_any;
  #|  if (form_data_any && typeof form_data_any.append === 'function') {
  #|    // This is a FormData object, convert to URL-encoded string
  #|    const params = [];
  #|    for (const [key, value] of form_data_any.entries()) {
  #|      params.push(encodeURIComponent(key) + '=' + encodeURIComponent(value));
  #|    }
  #|    body = params.join('&');
  #|    // Set Content-Type for URL-encoded body
  #|    xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
  #|  }
  #|
  #|  xhr.send(body);
  #|}

///|
/// Convert headers Map to JavaScript object for passing to extern functions
extern "js" fn map_to_js_object(m : Map[String, String]) -> @core.Any =
  #|(m) => {
  #|  const obj = {};
  #|  // MoonBit Map structure: { buf: [{_0: key, _1: value}, ...], start, end }
  #|  if (m && m.buf && Array.isArray(m.buf)) {
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
  prompt_response : String?,
  callback : @core.Any,
) -> Unit {
  let headers = get_htmx_headers(trigger_element, prompt_response)
  let headers_obj = map_to_js_object(headers)
  request_async_callback(
    url,
    http_method.to_string(),
    trigger_element,
    headers_obj,
    callback,
  )
}

///|
/// Async request with FormData body using callback
pub fn request_with_form_async(
  url : String,
  http_method : HttpMethod,
  form_data : @http.FormData?,
  trigger_element : @dom.Element?,
  prompt_response : String?,
  callback : @core.Any,
) -> Unit {
  let headers = get_htmx_headers(trigger_element, prompt_response)
  let headers_obj = map_to_js_object(headers)
  match form_data {
    Some(fd) =>
      request_with_form_async_callback(
        url,
        http_method.to_string(),
        fd.as_any(),
        trigger_element,
        headers_obj,
        callback,
      )
    None =>
      request_async_callback(
        url,
        http_method.to_string(),
        trigger_element,
        headers_obj,
        callback,
      )
  }
}

///|
/// Perform HTTP request with optional FormData body (async version)
pub async fn request_with_form(
  url : String,
  http_method : HttpMethod,
  form_data : @http.FormData?,
  trigger_element : @dom.Element?,
  prompt_response : String?,
) -> String {
  let headers = get_htmx_headers(trigger_element, prompt_response)
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
  prompt_response : String?,
) -> String? noraise {
  Some(
    request_with_form(
      url, http_method, form_data, trigger_element, prompt_response,
    ),
  ) catch {
    _ => None
  }
}
