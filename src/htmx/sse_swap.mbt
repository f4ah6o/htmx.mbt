///|
/// Swap content from SSE event into target element
pub fn sse_swap(
  target : @dom.Element,
  content : String,
  swap_style : String,
) -> Unit {
  perform_swap(target, content, swap_style)
}

///|
/// Perform the actual swap operation
extern "js" fn perform_swap(
  target : @dom.Element,
  content : String,
  swap_style : String,
) -> Unit =
  #|(target, content, swapStyle) => {
  #|  switch (swapStyle) {
  #|    case 'innerHTML':
  #|      target.innerHTML = content;
  #|      break;
  #|    case 'outerHTML':
  #|      if (target.tagName && target.tagName.toUpperCase() === 'BODY') {
  #|        target.innerHTML = content;
  #|      } else {
  #|        target.outerHTML = content;
  #|      }
  #|      break;
  #|    case 'beforebegin':
  #|      target.insertAdjacentHTML('beforebegin', content);
  #|      break;
  #|    case 'afterbegin':
  #|      target.insertAdjacentHTML('afterbegin', content);
  #|      break;
  #|    case 'beforeend':
  #|      target.insertAdjacentHTML('beforeend', content);
  #|      break;
  #|    case 'afterend':
  #|      target.insertAdjacentHTML('afterend', content);
  #|      break;
  #|    case 'textContent':
  #|      target.textContent = content;
  #|      break;
  #|    default:
  #|      target.innerHTML = content;
  #|      break;
  #|  }
  #|}

///|
/// Find all elements that should swap on a specific SSE event
extern "js" fn find_swap_targets(
  root : @dom.Element,
  event_name : String,
) -> Array[@dom.Element] =
  #|(root, eventName) => {
  #|  const targets = [];
  #|
  #|  // Find elements with hx-sse="swap:<event>"
  #|  const swapElements = root.querySelectorAll(`[hx-sse*="swap:${eventName}"], [data-hx-sse*="swap:${eventName}"]`);
  #|  for (const el of swapElements) {
  #|    targets.push(el);
  #|  }
  #|
  #|  return targets;
  #|}

///|
/// Dispatch htmx SSE message event
extern "js" fn dispatch_sse_message_event(
  target : @dom.Element,
  event_name : String,
  data : String,
) -> Unit =
  #|(target, eventName, data) => {
  #|  const messageEvent = new CustomEvent('htmx:sse:message', {
  #|    bubbles: true,
  #|    cancelable: true,
  #|    detail: { event: eventName, data: data }
  #|  });
  #|  target.dispatchEvent(messageEvent);
  #|}

///|
/// Dispatch htmx SSE open event
extern "js" fn dispatch_sse_open_event(
  target : @dom.Element,
  url : String,
) -> Unit =
  #|(target, url) => {
  #|  const openEvent = new CustomEvent('htmx:sse:open', {
  #|    bubbles: true,
  #|    cancelable: true,
  #|    detail: { url: url }
  #|  });
  #|  target.dispatchEvent(openEvent);
  #|}

///|
/// Dispatch htmx SSE error event
extern "js" fn dispatch_sse_error_event(
  target : @dom.Element,
  url : String,
  error : @core.Any,
) -> Unit =
  #|(target, url, error) => {
  #|  const errorEvent = new CustomEvent('htmx:sse:error', {
  #|    bubbles: true,
  #|    cancelable: true,
  #|    detail: { url: url, error: error }
  #|  });
  #|  target.dispatchEvent(errorEvent);
  #|}
