///|
/// History cache implementation for htmx
/// Handles caching of page content in sessionStorage for history navigation

///|
/// Storage key for history cache in sessionStorage
const HISTORY_CACHE_KEY : String = "htmx-history-cache"

///|
/// Normalize a URL path for caching
/// Uses dummy base URL to handle path-only URLs
pub fn normalize_path(path : String) -> String {
  normalize_path_impl(path)
}

///|
extern "js" fn normalize_path_impl(path : String) -> String =
  #|(path) => {
  #|  let parsed = false;
  #|  try {
  #|    const url = new URL(path, 'http://x');
  #|    if (url) {
  #|      path = url.pathname + url.search;
  #|      parsed = true;
  #|    }
  #|  } catch (e) {
  #|    // If URL parsing fails, use path as-is (no trailing slash removal)
  #|  }
  #|  // Remove trailing slash unless it's the index
  #|  // Only apply this for valid URLs that were parsed successfully
  #|  if (parsed && path !== '/') {
  #|    path = path.replace(/\/+$/, '');
  #|  }
  #|  return path;
  #|}

///|
/// Get history cache size from htmx config
fn get_cache_size() -> Int {
  get_cache_size_js()
}

///|
extern "js" fn get_cache_size_js() -> Int =
  #|() => {
  #|  const size = window.htmx && window.htmx.config && window.htmx.config.historyCacheSize;
  #|  return (typeof size === 'number') ? size : 10;
  #|}

///|
/// Get refreshOnHistoryMiss config value
fn get_refresh_on_history_miss() -> Bool {
  get_refresh_on_history_miss_js()
}

///|
extern "js" fn get_refresh_on_history_miss_js() -> Bool =
  #|() => {
  #|  return !!(window.htmx && window.htmx.config && window.htmx.config.refreshOnHistoryMiss);
  #|}

///|
/// Check if sessionStorage is accessible
fn can_access_session_storage() -> Bool {
  can_access_session_storage_js()
}

///|
extern "js" fn can_access_session_storage_js() -> Bool =
  #|() => {
  #|  try {
  #|    const test = 'htmx:sessionStorageTest';
  #|    sessionStorage.setItem(test, test);
  #|    sessionStorage.removeItem(test);
  #|    return true;
  #|  } catch (e) {
  #|    return false;
  #|  }
  #|}

///|
/// Get item from sessionStorage (returns null on error)
fn session_storage_get(key : String) -> @core.Any {
  session_storage_get_js(key)
}

///|
extern "js" fn session_storage_get_js(key : String) -> @core.Any =
  #|(key) => {
  #|  try {
  #|    return sessionStorage.getItem(key);
  #|  } catch (e) {
  #|    return null;
  #|  }
  #|}

///|
/// Set item in sessionStorage (returns false on error)
fn session_storage_set(key : String, value : @core.Any) -> Bool {
  session_storage_set_js(key, value)
}

///|
extern "js" fn session_storage_set_js(key : String, value : @core.Any) -> Bool =
  #|(key, value) => {
  #|  try {
  #|    sessionStorage.setItem(key, value);
  #|    return true;
  #|  } catch (e) {
  #|    return false;
  #|  }
  #|}

///|
/// Remove item from sessionStorage
fn session_storage_remove(key : String) -> Unit {
  session_storage_remove_js(key)
}

///|
extern "js" fn session_storage_remove_js(key : String) -> Unit =
  #|(key) => {
  #|  try {
  #|    sessionStorage.removeItem(key);
  #|  } catch (e) {
  #|    // Ignore errors
  #|  }
  #|}

///|
/// Get the history element (body or element with hx-history-elt attribute)
fn get_history_element() -> @dom.Element {
  get_history_element_js()
}

///|
extern "js" fn get_history_element_js() -> @dom.Element =
  #|() => {
  #|  const historyElt = document.querySelector('[hx-history-elt],[data-hx-history-elt]');
  #|  return historyElt || document.body;
  #|}

///|
/// Get document title
fn get_document_title() -> String {
  get_document_title_js()
}

///|
extern "js" fn get_document_title_js() -> String =
  #|() => document.title

///|
/// Get current scroll Y position
fn get_scroll_y() -> Int {
  get_scroll_y_js()
}

///|
extern "js" fn get_scroll_y_js() -> Int =
  #|() => window.scrollY || 0

///|
/// Stringify JSON safely (returns null on error)
fn json_stringify_safe(obj : @core.Any) -> @core.Any? {
  let result = json_stringify_safe_js(obj)
  if @core.is_nullish(result) {
    Option::None
  } else {
    Some(result)
  }
}

///|
extern "js" fn json_stringify_safe_js(obj : @core.Any) -> @core.Any =
  #|(obj) => {
  #|  try {
  #|    return JSON.stringify(obj);
  #|  } catch (e) {
  #|    return null;
  #|  }
  #|}

///|
/// Remove URL from cache array
fn remove_url_from_cache(cache : @core.Any, url : String) -> @core.Any {
  remove_url_from_cache_js(cache, url)
}

///|
extern "js" fn remove_url_from_cache_js(
  cache : @core.Any,
  url : String,
) -> @core.Any =
  #|(cache, url) => {
  #|  const arr = Array.isArray(cache) ? cache : [];
  #|  for (let i = 0; i < arr.length; i++) {
  #|    if (arr[i] && arr[i].url === url) {
  #|      arr.splice(i, 1);
  #|      break;
  #|    }
  #|  }
  #|  return arr;
  #|}

///|
/// Add new entry to cache (LRU - adds to end)
fn add_to_cache(
  cache : @core.Any,
  url : String,
  content : String,
  title : String,
  scroll : Int,
) -> @core.Any {
  add_to_cache_js(cache, url, content, title, scroll)
}

///|
extern "js" fn add_to_cache_js(
  cache : @core.Any,
  url : String,
  content : String,
  title : String,
  scroll : Int,
) -> @core.Any =
  #|(cache, url, content, title, scroll) => {
  #|  const arr = Array.isArray(cache) ? cache : [];
  #|  arr.push({ url, content, title, scroll });
  #|  return arr;
  #|}

///|
/// Limit cache to specified size (removes from beginning - oldest entries)
fn limit_cache_size(cache : @core.Any, max_size : Int) -> @core.Any {
  limit_cache_size_js(cache, max_size)
}

///|
extern "js" fn limit_cache_size_js(
  cache : @core.Any,
  max_size : Int,
) -> @core.Any =
  #|(cache, max_size) => {
  #|  const arr = Array.isArray(cache) ? cache : [];
  #|  while (arr.length > max_size) {
  #|    arr.shift();
  #|  }
  #|  return arr;
  #|}

///|
/// Get array length
fn array_length(arr : @core.Any) -> Int {
  array_length_js(arr)
}

///|
extern "js" fn array_length_js(arr : @core.Any) -> Int =
  #|(arr) => (Array.isArray(arr) ? arr.length : 0)

///|
/// Find content in cache by URL
fn find_in_cache(cache : @core.Any, url : String) -> @core.Any? {
  let result = find_in_cache_js(cache, url)
  if @core.is_nullish(result) {
    Option::None
  } else {
    Some(result)
  }
}

///|
extern "js" fn find_in_cache_js(cache : @core.Any, url : String) -> @core.Any =
  #|(cache, url) => {
  #|  const arr = Array.isArray(cache) ? cache : [];
  #|  for (let i = 0; i < arr.length; i++) {
  #|    if (arr[i] && arr[i].url === url) {
  #|      return arr[i].content || null;
  #|    }
  #|  }
  #|  return null;
  #|}

///|
/// Save cache with retry (shrinks if quota exceeded)
fn save_cache_with_retry(cache : @core.Any) -> Unit {
  let cache_len = array_length(cache)
  if cache_len == 0 {
    // Empty cache, remove it
    session_storage_remove(HISTORY_CACHE_KEY)
    return
  }
  match json_stringify_safe(cache) {
    Some(json_str) =>
      if not(session_storage_set(HISTORY_CACHE_KEY, json_str)) {
        // Storage failed, try shrinking cache
        if cache_len > 1 {
          let shrunk = limit_cache_size(cache, cache_len - 1)
          save_cache_with_retry(shrunk)
        } else {
          // Single item failed to save, remove cache entirely
          session_storage_remove(HISTORY_CACHE_KEY)
        }
      }
    None =>
      // JSON stringify failed, remove cache entirely
      session_storage_remove(HISTORY_CACHE_KEY)
  }
}

///|
/// Get cache array from sessionStorage
fn get_cache_array() -> @core.Any {
  let json = session_storage_get(HISTORY_CACHE_KEY)
  if @core.is_nullish(json) {
    @core.new_array()
  } else {
    let parsed = json_parse_safe_any(json)
    if @core.is_nullish(parsed) {
      @core.new_array()
    } else {
      parsed
    }
  }
}

///|
extern "js" fn json_parse_safe_any(json_any : @core.Any) -> @core.Any =
  #|(json_any) => {
  #|  try {
  #|    return JSON.parse(json_any);
  #|  } catch (e) {
  #|    return null;
  #|  }
  #|}

///|
/// Clean element innerHTML for history cache
/// Cleans the content of the given element
fn clean_element_for_history(element_any : @core.Any) -> String {
  clean_element_for_history_js(element_any)
}

///|
extern "js" fn clean_element_for_history_js(element_any : @core.Any) -> String =
  #|(element) => {
  #|  if (!element) return '';
  #|  // Clone the element
  #|  const clone = element.cloneNode(true);
  #|  // Remove htmx-request class from all elements
  #|  const requestElements = clone.querySelectorAll('.htmx-request');
  #|  for (let i = 0; i < requestElements.length; i++) {
  #|    requestElements[i].classList.remove('htmx-request');
  #|  }
  #|  // Remove disabled attribute from elements with data-disabled-by-htmx
  #|  const disabledElements = clone.querySelectorAll('[data-disabled-by-htmx]');
  #|  for (let i = 0; i < disabledElements.length; i++) {
  #|    disabledElements[i].removeAttribute('disabled');
  #|  }
  #|  return clone.innerHTML;
  #|}

///|
/// Save current page content to history cache
pub fn save_to_history_cache(
  url : String,
  element_any : @core.Any,
  title : String,
) -> Unit {
  if not(can_access_session_storage()) {
    return
  }
  let cache_size = get_cache_size()
  if cache_size <= 0 {
    session_storage_remove(HISTORY_CACHE_KEY)
    return
  }
  let normalized_url = normalize_path(url)

  // Clean the HTML content from the given element
  let content = clean_element_for_history(element_any)
  let doc_title = if title == "" { get_document_title() } else { title }
  let scroll = get_scroll_y()

  // Get existing cache or initialize
  let mut cache = get_cache_array()

  // Remove existing entry for this URL (if any) - same URL overwrites
  cache = remove_url_from_cache(cache, normalized_url)

  // Add new entry
  cache = add_to_cache(cache, normalized_url, content, doc_title, scroll)

  // Limit to cache size
  cache = limit_cache_size(cache, cache_size)

  // Try to save, shrinking cache if needed
  save_cache_with_retry(cache)
}

///|
/// Get cached history content for a URL
pub fn get_cached_history(url : String) -> String? {
  if not(can_access_session_storage()) {
    Option::None
  } else {
    let normalized_url = normalize_path(url)
    let cache = get_cache_array()
    match find_in_cache(cache, normalized_url) {
      Some(result) =>
        if @core.is_nullish(result) {
          Option::None
        } else {
          Some(any_to_string(result))
        }
      None => Option::None
    }
  }
}

///|
extern "js" fn any_to_string(any : @core.Any) -> String =
  #|(any) => {
  #|  if (typeof any === 'string') return any;
  #|  return String(any);
  #|}

///|
/// Get current location pathname + search
fn location_pathname() -> String {
  location_pathname_js()
}

///|
extern "js" fn location_pathname_js() -> String =
  #|() => location.pathname + location.search

///|
/// Reload the page
fn location_reload(forced : Bool) -> Unit {
  location_reload_js(forced)
}

///|
extern "js" fn location_reload_js(forced : Bool) -> Unit =
  #|(forced) => { window.location.reload(forced); }

///|
/// Set inner HTML of element (for history cache)
fn set_inner_html_for_cache(element : @dom.Element, html : String) -> Unit {
  set_inner_html_for_cache_js(element, html)
}

///|
extern "js" fn set_inner_html_for_cache_js(
  element : @dom.Element,
  html : String,
) -> Unit =
  #|(element, html) => { element.innerHTML = html; }

///|
/// Process htmx content on element
fn process_htmx_content(element_any : @core.Any) -> Unit {
  process_htmx_content_js(element_any)
}

///|
extern "js" fn process_htmx_content_js(element_any : @core.Any) -> Unit =
  #|(element_any) => {
  #|  if (window.htmx && window.htmx.process) {
  #|    window.htmx.process(element_any);
  #|  }
  #|}

///|
/// Load history from server on cache miss
fn load_from_server(path : String) -> Unit {
  load_from_server_js(path)
}

///|
extern "js" fn load_from_server_js(path : String) -> Unit =
  #|(path) => {
  #|  const xhr = new XMLHttpRequest();
  #|  xhr.open('GET', path, true);
  #|  xhr.setRequestHeader('HX-Request', 'true');
  #|  xhr.setRequestHeader('HX-History-Restore-Request', 'true');
  #|  xhr.setRequestHeader('HX-Current-URL', location.href);
  #|  xhr.onload = function() {
  #|    if (this.status >= 200 && this.status < 400) {
  #|      const historyElt = document.querySelector('[hx-history-elt],[data-hx-history-elt]') || document.body;
  #|      historyElt.innerHTML = this.response;
  #|      if (window.htmx && window.htmx.process) {
  #|        window.htmx.process(historyElt);
  #|      }
  #|    }
  #|  };
  #|  xhr.send();
  #|}

///|
/// Restore history from cache or server
pub fn restore_history(path : String) -> Unit {
  let cache_path = if path == "" { location_pathname() } else { path }
  match get_cached_history(cache_path) {
    Some(content) => {
      // Cache hit - restore from cache
      let history_elt = get_history_element()
      set_inner_html_for_cache(history_elt, content)

      // Process new content
      process_htmx_content(history_elt.as_any())
    }
    None =>
      // Cache miss
      if get_refresh_on_history_miss() {
        location_reload(true)
      } else {
        load_from_server(cache_path)
      }
  }
}
