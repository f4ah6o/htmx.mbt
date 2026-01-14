///|
/// Module for managing indicator elements during htmx requests
/// Tracks reference counts so multiple concurrent requests can properly
/// show/hide the htmx-request class on indicator elements

///|
/// Increment the request count for an element
extern "js" fn inc_indicator_count(el : @dom.Element) -> Unit =
  #|(el) => {
  #|  const key = "htmx-internal-data";
  #|  let data = el[key];
  #|  if (!data) {
  #|    data = {};
  #|    el[key] = data;
  #|  }
  #|  data.indicatorCount = (data.indicatorCount || 0) + 1;
  #|}

///|
/// Decrement the request count for an element
extern "js" fn dec_indicator_count(el : @dom.Element) -> Unit =
  #|(el) => {
  #|  const key = "htmx-internal-data";
  #|  const data = el[key];
  #|  if (data) {
  #|    data.indicatorCount = (data.indicatorCount || 1) - 1;
  #|  }
  #|}

///|
/// Add the htmx-request class to an element
extern "js" fn add_request_class(el : @dom.Element) -> Unit =
  #|(el) => el.classList.add("htmx-request")

///|
/// Remove the htmx-request class from an element if request count is zero
extern "js" fn remove_request_class_if_zero(el : @dom.Element) -> Unit =
  #|(el) => {
  #|  const key = "htmx-internal-data";
  #|  const data = el[key];
  #|  const count = data ? (data.indicatorCount || 0) : 0;
  #|  if (count === 0) {
  #|    el.classList.remove("htmx-request");
  #|  }
  #|}

///|
/// Show indicators - adds htmx-request class and tracks reference count
pub fn show_indicators(elements : Array[@dom.Element]) -> Unit {
  for el in elements {
    inc_indicator_count(el)
    add_request_class(el)
  }
}

///|
/// Hide indicators - decrements reference count and removes htmx-request class when count reaches 0
pub fn hide_indicators(elements : Array[@dom.Element]) -> Unit {
  for el in elements {
    dec_indicator_count(el)
    remove_request_class_if_zero(el)
  }
}
