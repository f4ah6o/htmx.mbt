///|
/// Module for managing disabled elements during htmx requests
/// Tracks reference counts so multiple concurrent requests can properly
/// enable/disable elements

///|
/// Increment the request count for an element
extern "js" fn inc_request_count(el : @dom.Element) -> Unit =
  #|(el) => {
  #|  const key = "htmx-internal-data";
  #|  let data = el[key];
  #|  if (!data) {
  #|    data = {};
  #|    el[key] = data;
  #|  }
  #|  data.requestCount = (data.requestCount || 0) + 1;
  #|}

///|
/// Decrement the request count for an element
extern "js" fn dec_request_count(el : @dom.Element) -> Unit =
  #|(el) => {
  #|  const key = "htmx-internal-data";
  #|  const data = el[key];
  #|  if (data) {
  #|    data.requestCount = (data.requestCount || 1) - 1;
  #|  }
  #|}

///|
/// Set the disabled attribute on an element
extern "js" fn set_disabled_attr(el : @dom.Element) -> Unit =
  #|(el) => el.setAttribute("disabled", "disabled")

///|
/// Remove the disabled attribute from an element if request count is zero
extern "js" fn remove_disabled_if_zero(el : @dom.Element) -> Unit =
  #|(el) => {
  #|  const key = "htmx-internal-data";
  #|  const data = el[key];
  #|  const count = data ? (data.requestCount || 0) : 0;
  #|  if (count === 0) {
  #|    el.removeAttribute("disabled");
  #|  }
  #|}

///|
/// Disable elements - adds disabled attribute and tracks reference count
pub fn disable_elements(elements : Array[@dom.Element]) -> Unit {
  for el in elements {
    inc_request_count(el)
    set_disabled_attr(el)
  }
}

///|
/// Enable elements - decrements reference count and removes disabled attribute when count reaches 0
pub fn enable_elements(elements : Array[@dom.Element]) -> Unit {
  for el in elements {
    dec_request_count(el)
    remove_disabled_if_zero(el)
  }
}
