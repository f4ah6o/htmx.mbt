///|
/// Minimal JS harness for upstream htmx tests.
extern "js" fn is_browser() -> Bool =
  #|() => typeof document !== 'undefined'

///|
extern "js" fn document_object() -> @core.Any =
  #|() => document

///|
extern "js" fn window_location() -> @core.Any =
  #|() => window.location

///|
extern "js" fn document_query_selector(selector : String) -> @core.Any =
  #|(selector) => document.querySelector(selector)

///|
extern "js" fn document_query_selector_all(selector : String) -> @core.Any =
  #|(selector) => document.querySelectorAll(selector)

///|
extern "js" fn element_query_selector(
  target : @core.Any,
  selector : String,
) -> @core.Any =
  #|(target, selector) => target?.querySelector(selector) ?? null

///|
extern "js" fn element_query_selector_all(
  target : @core.Any,
  selector : String,
) -> @core.Any =
  #|(target, selector) => target?.querySelectorAll(selector) ?? []

///|
extern "js" fn element_closest(
  target : @core.Any,
  selector : String,
) -> @core.Any =
  #|(target, selector) => target?.closest(selector) ?? null

///|
extern "js" fn add_event_listener(
  target : @core.Any,
  event_name : String,
  handler : @core.Any,
) -> Unit =
  #|(target, event_name, handler) => target?.addEventListener(event_name, handler)

///|
extern "js" fn remove_event_listener(
  target : @core.Any,
  event_name : String,
  handler : @core.Any,
) -> Unit =
  #|(target, event_name, handler) => target?.removeEventListener(event_name, handler)

///|
extern "js" fn dispatch_event(
  target : @core.Any,
  event_name : String,
  detail : @core.Any,
) -> Unit =
  #|(target, event_name, detail) => {
  #|  if (!target) return;
  #|  const opts = { bubbles: true, cancelable: true };
  #|  if (detail != null) opts.detail = detail;
  #|  const evt = detail != null ? new CustomEvent(event_name, opts) : new Event(event_name, opts);
  #|  target.dispatchEvent(evt);
  #|}

///|
extern "js" fn class_list_add(
  target : @core.Any,
  class_name : String,
  delay : @core.Any,
) -> Unit =
  #|(target, class_name, delay) => {
  #|  if (!target || !target.classList) return;
  #|  if (delay == null) {
  #|    target.classList.add(class_name);
  #|  } else {
  #|    setTimeout(() => target.classList.add(class_name), delay);
  #|  }
  #|}

///|
extern "js" fn class_list_remove(
  target : @core.Any,
  class_name : String,
  delay : @core.Any,
) -> Unit =
  #|(target, class_name, delay) => {
  #|  if (!target || !target.classList) return;
  #|  if (delay == null) {
  #|    target.classList.remove(class_name);
  #|  } else {
  #|    setTimeout(() => target.classList.remove(class_name), delay);
  #|  }
  #|}

///|
extern "js" fn class_list_toggle(
  target : @core.Any,
  class_name : String,
  delay : @core.Any,
) -> Unit =
  #|(target, class_name, delay) => {
  #|  if (!target || !target.classList) return;
  #|  if (delay == null) {
  #|    target.classList.toggle(class_name);
  #|  } else {
  #|    setTimeout(() => target.classList.toggle(class_name), delay);
  #|  }
  #|}

///|
extern "js" fn remove_element(target : @core.Any, delay : @core.Any) -> Unit =
  #|(target, delay) => {
  #|  if (!target) return;
  #|  if (delay == null) {
  #|    target.remove();
  #|  } else {
  #|    setTimeout(() => target.remove(), delay);
  #|  }
  #|}

///|
extern "js" fn form_data_from_element(target : @core.Any) -> @core.Any =
  #|(target) => {
  #|  if (!target) return new FormData();
  #|  try {
  #|    return new FormData(target);
  #|  } catch {
  #|    return new FormData();
  #|  }
  #|}

///|
extern "js" fn take_class_js(target : @core.Any, class_name : String) -> Unit =
  #|(target, class_name) => {
  #|  if (!target || !target.classList) return;
  #|  document.querySelectorAll('.' + class_name).forEach((el) => {
  #|    if (el?.classList) {
  #|      el.classList.remove(class_name);
  #|    }
  #|  });
  #|  target.classList.add(class_name);
  #|}

///|
extern "js" fn parse_interval_js(value : @core.Any) -> @core.Any =
  #|(value) => {
  #|  if (value == null || typeof value !== 'string') return undefined;
  #|  const trimmed = value.trim();
  #|  if (trimmed === '') return undefined;
  #|  const toNumber = (input) => {
  #|    const num = parseFloat(input);
  #|    return Number.isNaN(num) ? undefined : num;
  #|  };
  #|  if (trimmed.endsWith('ms')) {
  #|    const num = toNumber(trimmed.slice(0, -2));
  #|    return num == null ? undefined : Math.floor(num);
  #|  }
  #|  if (trimmed.endsWith('s')) {
  #|    const num = toNumber(trimmed.slice(0, -1));
  #|    return num == null ? undefined : Math.floor(num * 1000);
  #|  }
  #|  if (trimmed.endsWith('m')) {
  #|    const num = toNumber(trimmed.slice(0, -1));
  #|    return num == null ? undefined : Math.floor(num * 60000);
  #|  }
  #|  const num = toNumber(trimmed);
  #|  return num == null ? undefined : Math.floor(num);
  #|}

///|
extern "js" fn resolved_promise() -> @core.Any =
  #|() => Promise.resolve()

///|
fn is_string(value : @core.Any) -> Bool {
  @core.typeof_(value) == "string"
}

///|
fn as_string(value : @core.Any) -> String {
  @core.identity(value)
}

///|
fn resolve_target(target_or_selector : @core.Any) -> @core.Any? {
  if @core.is_nullish(target_or_selector) {
    Option::None
  } else if is_string(target_or_selector) {
    let selector = as_string(target_or_selector)
    let target = document_query_selector(selector)
    if @core.is_nullish(target) {
      Option::None
    } else {
      Some(target)
    }
  } else {
    Some(target_or_selector)
  }
}

///|
fn parse_event_args(
  target_or_event : @core.Any,
  event_or_handler : @core.Any,
  handler_maybe : @core.Any,
) -> (@core.Any, String, @core.Any)? {
  if @core.is_nullish(target_or_event) {
    Option::None
  } else if is_string(target_or_event) && @core.is_nullish(handler_maybe) {
    let event_name = as_string(target_or_event)
    let handler = event_or_handler
    Some((document_object(), event_name, handler))
  } else if is_string(target_or_event) && !@core.is_nullish(handler_maybe) {
    match resolve_target(target_or_event) {
      Some(target) => Some((target, as_string(event_or_handler), handler_maybe))
      Option::None => Option::None
    }
  } else if @core.is_nullish(handler_maybe) {
    Option::None
  } else {
    Some((target_or_event, as_string(event_or_handler), handler_maybe))
  }
}

///|
/// Process an element for htmx - handles load triggers
extern "js" fn process_any(target : @core.Any) -> Unit =
  #|(target) => {
  #|  if (!target) return;
  #|
  #|  // Function to process a single element for load trigger
  #|  const processElement = (el) => {
  #|    // Ensure el is a valid DOM element with getAttribute method
  #|    if (!el || typeof el.getAttribute !== 'function') return;
  #|
  #|    const trigger = el.getAttribute('hx-trigger') || el.getAttribute('data-hx-trigger');
  #|    if (trigger) {
  #|      const parts = trigger.split(',').map(s => s.trim());
  #|      for (const part of parts) {
  #|        if (part === 'load' || part.startsWith('load ')) {
  #|          // Find the method attribute (hx-get, hx-post, etc.)
  #|          const methodAttrs = ['hx-get', 'hx-post', 'hx-put', 'hx-delete', 'hx-patch',
  #|                              'data-hx-get', 'data-hx-post', 'data-hx-put', 'data-hx-delete', 'data-hx-patch'];
  #|          for (const attr of methodAttrs) {
  #|            if (el.hasAttribute(attr)) {
  #|              const url = el.getAttribute(attr);
  #|              const method = attr.replace('data-', '').replace('hx-', '').toUpperCase();
  #|              // Trigger click event which will be handled by htmx
  #|              const event = new MouseEvent('click', { bubbles: true, cancelable: true });
  #|              el.dispatchEvent(event);
  #|              break;
  #|            }
  #|          }
  #|          break;
  #|        }
  #|      }
  #|    }
  #|  };
  #|
  #|  // Check if target is an array (NodeList)
  #|  if (Array.isArray(target) || target instanceof NodeList) {
  #|    for (const el of target) {
  #|      processElement(el);
  #|    }
  #|  } else {
  #|    // Single element
  #|    processElement(target);
  #|  }
  #|}

///|
fn on_any(
  target_or_event : @core.Any,
  event_or_handler : @core.Any,
  handler_maybe : @core.Any,
) -> @core.Any {
  match parse_event_args(target_or_event, event_or_handler, handler_maybe) {
    Some((target, event_name, handler)) => {
      add_event_listener(target, event_name, handler)
      handler
    }
    Option::None => @core.undefined()
  }
}

///|
fn off_any(
  target_or_event : @core.Any,
  event_or_handler : @core.Any,
  handler_maybe : @core.Any,
) -> Unit {
  match parse_event_args(target_or_event, event_or_handler, handler_maybe) {
    Some((target, event_name, handler)) =>
      remove_event_listener(target, event_name, handler)
    Option::None => ()
  }
}

///|
fn trigger_any(
  target_or_selector : @core.Any,
  event_any : @core.Any,
  detail_any : @core.Any,
) -> Unit {
  let event_name = as_string(event_any)
  match resolve_target(target_or_selector) {
    Some(target) => dispatch_event(target, event_name, detail_any)
    Option::None => ()
  }
}

///|
fn find_any(
  root_or_selector : @core.Any,
  selector_any : @core.Any,
) -> @core.Any {
  if @core.is_nullish(selector_any) {
    document_query_selector(as_string(root_or_selector))
  } else {
    match resolve_target(root_or_selector) {
      Some(target) => element_query_selector(target, as_string(selector_any))
      Option::None => @core.null()
    }
  }
}

///|
fn find_all_any(
  root_or_selector : @core.Any,
  selector_any : @core.Any,
) -> @core.Any {
  if @core.is_nullish(selector_any) {
    document_query_selector_all(as_string(root_or_selector))
  } else {
    match resolve_target(root_or_selector) {
      Some(target) =>
        element_query_selector_all(target, as_string(selector_any))
      Option::None => @core.new_array()
    }
  }
}

///|
fn closest_any(target_any : @core.Any, selector_any : @core.Any) -> @core.Any {
  match resolve_target(target_any) {
    Some(target) => element_closest(target, as_string(selector_any))
    Option::None => @core.null()
  }
}

///|
fn add_class_any(
  target_or_selector : @core.Any,
  class_any : @core.Any,
  delay_any : @core.Any,
) -> Unit {
  match resolve_target(target_or_selector) {
    Some(target) => class_list_add(target, as_string(class_any), delay_any)
    Option::None => ()
  }
}

///|
fn remove_class_any(
  target_or_selector : @core.Any,
  class_any : @core.Any,
  delay_any : @core.Any,
) -> Unit {
  match resolve_target(target_or_selector) {
    Some(target) => class_list_remove(target, as_string(class_any), delay_any)
    Option::None => ()
  }
}

///|
fn toggle_class_any(
  target_or_selector : @core.Any,
  class_any : @core.Any,
  delay_any : @core.Any,
) -> Unit {
  match resolve_target(target_or_selector) {
    Some(target) => class_list_toggle(target, as_string(class_any), delay_any)
    Option::None => ()
  }
}

///|
fn take_class_any(
  target_or_selector : @core.Any,
  class_any : @core.Any,
) -> Unit {
  match resolve_target(target_or_selector) {
    Some(target) => take_class_js(target, as_string(class_any))
    Option::None => ()
  }
}

///|
fn remove_any(target_or_selector : @core.Any, delay_any : @core.Any) -> Unit {
  match resolve_target(target_or_selector) {
    Some(target) => remove_element(target, delay_any)
    Option::None => ()
  }
}

///|
fn values_any(
  target_or_selector : @core.Any,
  _method_any : @core.Any,
) -> @core.Any {
  match resolve_target(target_or_selector) {
    Some(target) => form_data_from_element(target)
    Option::None => form_data_from_element(@core.null())
  }
}

///|
fn on_load_any(handler_any : @core.Any) -> @core.Any {
  add_event_listener(document_object(), "htmx:load", handler_any)
  handler_any
}

///|
fn log_all() -> Unit {

}

///|
fn log_none() -> Unit {

}

///|
fn ajax_any(
  _method_any : @core.Any,
  _url_any : @core.Any,
  _context_any : @core.Any,
) -> @core.Any {
  resolved_promise()
}

///|
fn swap_any(
  _target_any : @core.Any,
  _content_any : @core.Any,
  _swap_any : @core.Any,
) -> Unit {

}

///|
fn define_extension_any(_name_any : @core.Any, _ext_any : @core.Any) -> Unit {

}

///|
fn remove_extension_any(_name_any : @core.Any) -> Unit {

}

///|

///|
/// Wrapper for saveToHistoryCache - (url, element, title) -> Unit
fn save_to_history_cache_any(
  url_any : @core.Any,
  element_any : @core.Any,
  title_any : @core.Any,
) -> @core.Any {
  let url = as_string(url_any)
  let title = as_string(title_any)
  @htmx.save_to_history_cache(url, element_any, title)
  @core.undefined()
}

///|
/// Wrapper for getCachedHistory - (url) -> content or null
fn get_cached_history_any(url_any : @core.Any) -> @core.Any {
  let url = as_string(url_any)
  match @htmx.get_cached_history(url) {
    Some(content) => @core.any(content)
    None => @core.null()
  }
}

///|
/// Wrapper for restoreHistory - (path) -> Unit
fn restore_history_any(path_any : @core.Any) -> @core.Any {
  let path = as_string(path_any)
  @htmx.restore_history(path)
  @core.undefined()
}

///|
/// Wrapper for normalizePath - (path) -> normalized string
fn normalize_path_any(path_any : @core.Any) -> @core.Any {
  let path = as_string(path_any)
  let normalized = @htmx.normalize_path(path)
  @core.any(normalized)
}

///|
fn internal_any(name_any : @core.Any) -> @core.Any {
  if @core.is_nullish(name_any) {
    @core.undefined()
  } else {
    let name = as_string(name_any)
    match name {
      "saveToHistoryCache" => @core.from_fn3(save_to_history_cache_any)
      "getCachedHistory" => @core.from_fn1(get_cached_history_any)
      "restoreHistory" => @core.from_fn1(restore_history_any)
      "normalizePath" => @core.from_fn1(normalize_path_any)
      _ => @core.undefined()
    }
  }
}

///|
fn make_htmx_object() -> @core.Any {
  let htmx_obj = @core.new_object()
  let config_obj = @core.new_object()
  let cache_obj = @core.new_object()
  htmx_obj._set("version", @core.any("0.1.0-mbt"))
  // Set allowEval to true by default for hx-on functionality
  config_obj._set("allowEval", @core.any(true))
  config_obj._set("historyCacheSize", @core.any(10))
  config_obj._set("refreshOnHistoryMiss", @core.any(false))
  htmx_obj._set("config", config_obj)
  htmx_obj._set("cache", cache_obj)
  htmx_obj._set("location", window_location())
  htmx_obj._set("process", @core.from_fn1(process_any))
  htmx_obj._set("on", @core.from_fn3(on_any))
  htmx_obj._set("off", @core.from_fn3(off_any))
  htmx_obj._set("trigger", @core.from_fn3(trigger_any))
  htmx_obj._set("find", @core.from_fn2(find_any))
  htmx_obj._set("findAll", @core.from_fn2(find_all_any))
  htmx_obj._set("closest", @core.from_fn2(closest_any))
  htmx_obj._set("addClass", @core.from_fn3(add_class_any))
  htmx_obj._set("removeClass", @core.from_fn3(remove_class_any))
  htmx_obj._set("toggleClass", @core.from_fn3(toggle_class_any))
  htmx_obj._set("takeClass", @core.from_fn2(take_class_any))
  htmx_obj._set("remove", @core.from_fn2(remove_any))
  htmx_obj._set("values", @core.from_fn2(values_any))
  htmx_obj._set("onLoad", @core.from_fn1(on_load_any))
  htmx_obj._set("logAll", @core.from_fn0(log_all))
  htmx_obj._set("logNone", @core.from_fn0(log_none))
  htmx_obj._set("ajax", @core.from_fn3(ajax_any))
  htmx_obj._set("swap", @core.from_fn3(swap_any))
  htmx_obj._set("defineExtension", @core.from_fn2(define_extension_any))
  htmx_obj._set("removeExtension", @core.from_fn1(remove_extension_any))
  htmx_obj._set("parseInterval", @core.from_fn1(parse_interval_js))
  htmx_obj._set("_", @core.from_fn1(internal_any))
  htmx_obj
}

///|
fn export_htmx(htmx_obj : @core.Any) -> Unit {
  @core.global_this()._set("htmx", htmx_obj)
}

///|
fn init {
  if is_browser() {
    export_htmx(make_htmx_object())
    @htmx.htmx_init()
  }
}

///|
fn main {

}
