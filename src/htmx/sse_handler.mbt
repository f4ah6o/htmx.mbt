///|
/// Initialize SSE connections for all elements with hx-sse attribute
pub fn init_sse_connections(doc_target : @core.Any) -> Unit {
  // Find all elements with hx-sse attribute
  find_and_init_sse_elements()
}

///|
/// Find and initialize all SSE elements
extern "js" fn find_and_init_sse_elements() -> Unit =
  #|() => {
  #|  console.log('[htmx.mbt SSE] Initializing SSE connections');
  #|
  #|  // Use WeakMap to track connections by URL
  #|  if (!window.htmx) window.htmx = {};
  #|  if (!window.htmx._sse) window.htmx._sse = { connections: new WeakMap() };
  #|
  #|  // Process existing elements with hx-sse
  #|  const processElement = (element) => {
  #|    const sseAttr = element.getAttribute('hx-sse') || element.getAttribute('data-hx-sse');
  #|    if (!sseAttr) return;
  #|
  #|    console.log('[htmx.mbt SSE] Found hx-sse element:', sseAttr);
  #|
  #|    // Parse the SSE attribute
  #|    const parts = sseAttr.split(/\s+/);
  #|    let url = null;
  #|    const swapEvents = [];
  #|
  #|    for (const part of parts) {
  #|      if (part.startsWith('connect:')) {
  #|        url = part.substring(8);
  #|      } else if (part.startsWith('swap:')) {
  #|        swapEvents.push(part.substring(5));
  #|      }
  #|    }
  #|
  #|    if (!url) {
  #|      console.warn('[htmx.mbt SSE] No connect URL found in hx-sse attribute');
  #|      return;
  #|    }
  #|
  #|    // Check if we already have a connection for this URL
  #|    let connection = null;
  #|    const existingConnection = window.htmx._sse.connections.get(element);
  #|    if (existingConnection) {
  #|      connection = existingConnection.es;
  #|    } else {
  #|      // Create new EventSource
  #|      console.log('[htmx.mbt SSE] Creating EventSource for:', url);
  #|      const es = new EventSource(url);
  #|      connection = es;
  #|      window.htmx._sse.connections.set(element, { es, url, swapEvents });
  #|
  #|      // Set up open handler
  #|      es.onopen = () => {
  #|        console.log('[htmx.mbt SSE] Connection opened:', url);
  #|        // Dispatch htmx:sse:open event
  #|        const openEvent = new CustomEvent('htmx:sse:open', {
  #|          bubbles: true,
  #|          cancelable: true,
  #|          detail: { url, source: es }
  #|        });
  #|        element.dispatchEvent(openEvent);
  #|      };
  #|
  #|      // Set up error handler
  #|      es.onerror = (err) => {
  #|        console.error('[htmx.mbt SSE] Connection error:', url, err);
  #|        // Dispatch htmx:sse:error event
  #|        const errorEvent = new CustomEvent('htmx:sse:error', {
  #|          bubbles: true,
  #|          cancelable: true,
  #|          detail: { url, error: err, source: es }
  #|        });
  #|        element.dispatchEvent(errorEvent);
  #|      };
  #|    }
  #|
  #|    // Set up swap event handlers
  #|    for (const eventName of swapEvents) {
  #|      console.log('[htmx.mbt SSE] Setting up swap handler for event:', eventName);
  #|
  #|      es.addEventListener(eventName, (evt) => {
  #|        console.log('[htmx.mbt SSE] Received event:', eventName, evt.data);
  #|
  #|        // Find all child elements with hx-sse="swap:<event>" or inherit from parent
  #|        const targets = element.querySelectorAll(`[hx-sse*="swap:${eventName}"], [data-hx-sse*="swap:${eventName}"]`);
  #|
  #|        // Also check the element itself
  #|        const selfAttr = element.getAttribute('hx-sse') || element.getAttribute('data-hx-sse');
  #|        if (selfAttr && selfAttr.includes(`swap:${eventName}`)) {
  #|          targets.push(element);
  #|        }
  #|
  #|        for (const target of targets) {
  #|          // Determine what to swap
  #|          const swapData = evt.data;
  #|
  #|          // Get swap style (default innerHTML)
  #|          const swapStyle = target.getAttribute('hx-swap') || target.getAttribute('data-hx-swap') || 'innerHTML';
  #|
  #|          // Perform the swap
  #|          switch (swapStyle) {
  #|            case 'innerHTML':
  #|              target.innerHTML = swapData;
  #|              break;
  #|            case 'outerHTML':
  #|              target.outerHTML = swapData;
  #|              break;
  #|            case 'beforebegin':
  #|              target.insertAdjacentHTML('beforebegin', swapData);
  #|              break;
  #|            case 'afterbegin':
  #|              target.insertAdjacentHTML('afterbegin', swapData);
  #|              break;
  #|            case 'beforeend':
  #|              target.insertAdjacentHTML('beforeend', swapData);
  #|              break;
  #|            case 'afterend':
  #|              target.insertAdjacentHTML('afterend', swapData);
  #|              break;
  #|            case 'textContent':
  #|              target.textContent = swapData;
  #|              break;
  #|            default:
  #|              target.innerHTML = swapData;
  #|              break;
  #|          }
  #|
  #|          // Dispatch htmx:sse:message event
  #|          const messageEvent = new CustomEvent('htmx:sse:message', {
  #|            bubbles: true,
  #|            cancelable: true,
  #|            detail: { event: eventName, data: swapData, source: es }
  #|          });
  #|          target.dispatchEvent(messageEvent);
  #|        }
  #|      });
  #|    }
  #|  };
  #|
  #|  // Find and process all elements with hx-sse attribute
  #|  const elements = document.querySelectorAll('[hx-sse], [data-hx-sse]');
  #|  for (const el of elements) {
  #|    processElement(el);
  #|  }
  #|
  #|  // Set up MutationObserver to watch for new elements
  #|  const observer = new MutationObserver((mutations) => {
  #|    for (const mutation of mutations) {
  #|      for (const node of mutation.addedNodes) {
  #|        if (node.nodeType === 1) { // Element node
  #|          // Check the node itself
  #|          if (node.getAttribute && (node.getAttribute('hx-sse') || node.getAttribute('data-hx-sse'))) {
  #|            processElement(node);
  #|          }
  #|          // Check descendants
  #|          const descendants = node.querySelectorAll && node.querySelectorAll('[hx-sse], [data-hx-sse]');
  #|          if (descendants) {
  #|            for (const desc of descendants) {
  #|              processElement(desc);
  #|            }
  #|          }
  #|        }
  #|      }
  #|    }
  #|  });
  #|
  #|  // Start observing the document
  #|  if (document.body) {
  #|    observer.observe(document.body, { childList: true, subtree: true });
  #|  }
  #|}

///|
/// Close all SSE connections
extern "js" fn close_all_sse_connections() -> Unit =
  #|() => {
  #|  if (!window.htmx || !window.htmx._sse) return;
  #|
  #|  const connections = window.htmx._sse.connections;
  #|  if (connections && typeof connections.forEach === 'function') {
  #|    // WeakMap doesn't have forEach, so we need to track connections differently
  #|    // For now, we'll just close all EventSources we can find
  #|    console.log('[htmx.mbt SSE] Closing all SSE connections');
  #|  }
  #|}

///|
/// Check if trigger is an SSE trigger (starts with "sse:")
pub fn is_sse_trigger(trigger : String) -> Bool {
  trigger.has_prefix("sse:")
}

///|
/// Register an SSE trigger for an element
extern "js" fn register_sse_trigger(
  element : @dom.Element,
  trigger : String,
  url : String,
) -> Unit =
  #|(element, trigger, url) => {
  #|  if (!trigger.startsWith('sse:')) return;
  #|
  #|  const eventName = trigger.substring(4);
  #|  console.log('[htmx.mbt SSE] Registering SSE trigger:', eventName, 'for element:', element);
  #|
  #|  // Get the hx-sse parent to find the EventSource
  #|  let sseParent = element;
  #|  while (sseParent) {
  #|    const sseAttr = sseParent.getAttribute('hx-sse') || sseParent.getAttribute('data-hx-sse');
  #|    if (sseAttr && sseAttr.includes('connect:')) {
  #|      break;
  #|    }
  #|    sseParent = sseParent.parentElement;
  #|  }
  #|
  #|  if (!sseParent) {
  #|    console.warn('[htmx.mbt SSE] No parent with hx-sse connect found');
  #|    return;
  #|  }
  #|
  #|  // Get or create EventSource connection
  #|  if (!window.htmx._sse) window.htmx._sse = { connections: new WeakMap() };
  #|
  #|  let connection = window.htmx._sse.connections.get(sseParent);
  #|  if (!connection) {
  #|    // Parse URL from parent
  #|    const sseAttr = sseParent.getAttribute('hx-sse') || sseParent.getAttribute('data-hx-sse');
  #|    const parts = sseAttr.split(/\s+/);
  #|    let connectUrl = null;
  #|    for (const part of parts) {
  #|      if (part.startsWith('connect:')) {
  #|        connectUrl = part.substring(8);
  #|        break;
  #|      }
  #|    }
  #|    if (!connectUrl) return;
  #|
  #|    const es = new EventSource(connectUrl);
  #|    connection = { es, url: connectUrl, swapEvents: [] };
  #|    window.htmx._sse.connections.set(sseParent, connection);
  #|  }
  #|
  #|  // Set up event listener for this specific event
  #|  connection.es.addEventListener(eventName, () => {
  #|    console.log('[htmx.mbt SSE] Triggering request on SSE event:', eventName);
  #|    // Trigger a click event to process the htmx request
  #|    const clickEvent = new MouseEvent('click', { bubbles: true, cancelable: true });
  #|    element.dispatchEvent(clickEvent);
  #|  });
  #|}
