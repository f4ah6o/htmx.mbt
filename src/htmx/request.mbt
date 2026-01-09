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
/// Standard htmx request headers
fn get_htmx_headers(trigger_element : @dom.Element?) -> Map[String, String] {
  let headers : Map[String, String] = { "HX-Request": "true" }

  // Add trigger element info if provided
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
/// Perform HTTP request with optional FormData body
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
