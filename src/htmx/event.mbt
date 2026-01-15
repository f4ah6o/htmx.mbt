///|
/// Unified event dispatching for htmx.org compatibility
/// Dispatches both camelCase and kebab-case versions of events

///|
/// Convert kebab-case event name to camelCase
/// Examples: "htmx:config-request" -> "htmx:configRequest"
pub extern "js" fn kebab_to_camel(s : String) -> String =
  #|(s) => {
  #|  return s.replace(/-([a-z])/g, function(_, c) { return c.toUpperCase(); });
  #|}

///|
/// Dispatch both camelCase and kebab-case versions of an htmx event
/// Returns true if neither event was prevented (AND semantics)
pub extern "js" fn dispatch_htmx_event(
  target : @dom.Element,
  event_name : String,
  detail : @core.Any,
) -> Bool =
  #|(target, event_name, detail) => {
  #|  // First dispatch the original event name (usually kebab-case in htmx.mbt)
  #|  const evt1 = new CustomEvent(event_name, {
  #|    bubbles: true,
  #|    cancelable: true,
  #|    detail: detail
  #|  });
  #|  const result1 = target.dispatchEvent(evt1);
  #|
  #|  // Convert to camelCase and dispatch if different
  #|  const camelName = event_name.replace(/-([a-z])/g, function(_, c) { return c.toUpperCase(); });
  #|  if (camelName !== event_name) {
  #|    const evt2 = new CustomEvent(camelName, {
  #|      bubbles: true,
  #|      cancelable: true,
  #|      detail: detail
  #|    });
  #|    const result2 = target.dispatchEvent(evt2);
  #|    // Return false only if BOTH were prevented
  #|    return result1 && result2;
  #|  }
  #|  return result1;
  #|}

///|
/// Dispatch htmx event with default empty detail object
pub extern "js" fn dispatch_event(
  target : @dom.Element,
  event_name : String,
) -> Bool =
  #|(target, event_name) => {
  #|  return target.dispatchEvent(new CustomEvent(event_name, { bubbles: true, cancelable: true, detail: {} }));
  #|}
