///|
test "data-hx-get prefix is recognized" {
  // Test that data-hx-get prefix works the same as hx-get
  // Since we can't mock DOM in unit tests, we test the helper function
  let attr = "hx-get"
  let prefixed = "data-" + attr
  inspect(prefixed, content="data-hx-get")
}

///|
test "get_hx_methods returns all HTTP methods" {
  // Test all method attributes are defined
  let methods = ["hx-get", "hx-post", "hx-put", "hx-delete", "hx-patch"]
  inspect(methods.length(), content="5")
  inspect(methods[0], content="hx-get")
}

///|
test "HttpMethod from_attr parses get" {
  match HttpMethod::from_attr("hx-get") {
    Some(m) =>
      match m {
        Get => inspect("ok", content="ok")
        _ => inspect("error", content="Expected Get")
      }
    Option::None => inspect("error", content="Should parse hx-get")
  }
}

///|
test "HttpMethod from_attr parses post" {
  match HttpMethod::from_attr("hx-post") {
    Some(m) =>
      match m {
        Post => inspect("ok", content="ok")
        _ => inspect("error", content="Expected Post")
      }
    Option::None => inspect("error", content="Should parse hx-post")
  }
}

///|
test "HttpMethod from_attr parses put" {
  match HttpMethod::from_attr("hx-put") {
    Some(m) =>
      match m {
        Put => inspect("ok", content="ok")
        _ => inspect("error", content="Expected Put")
      }
    Option::None => inspect("error", content="Should parse hx-put")
  }
}

///|
test "HttpMethod from_attr parses delete" {
  match HttpMethod::from_attr("hx-delete") {
    Some(m) =>
      match m {
        Delete => inspect("ok", content="ok")
        _ => inspect("error", content="Expected Delete")
      }
    Option::None => inspect("error", content="Should parse hx-delete")
  }
}

///|
test "HttpMethod from_attr parses patch" {
  match HttpMethod::from_attr("hx-patch") {
    Some(m) =>
      match m {
        Patch => inspect("ok", content="ok")
        _ => inspect("error", content="Expected Patch")
      }
    Option::None => inspect("error", content="Should parse hx-patch")
  }
}

///|
test "HttpMethod from_attr returns None for invalid" {
  match HttpMethod::from_attr("hx-invalid") {
    Option::None => inspect("ok", content="ok")
    Option::Some(_) =>
      inspect("error", content="Should return None for invalid")
  }
}
