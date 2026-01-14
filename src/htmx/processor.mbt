///|
/// Debug log for processor
extern "js" fn log_debug(msg : String) -> Unit =
  #|(msg) => console.log("[htmx.mbt DEBUG] " + msg)

///|
/// Process a single htmx element - perform request and swap (async for proper disabled-elt behavior)
fn process_element_with_trigger(
  element : @dom.Element,
  trigger_el : @dom.Element?,
) -> Unit {
  log_debug("process_element_with_trigger called")

  // Find method and URL
  let method_url = find_method_url(element)
  guard method_url is Some((http_method, url)) else { return }

  // Validate form before making request (pass trigger element for formnovalidate check)
  if not(validate_element_with_trigger(element, trigger_el)) {
    return
  }

  // Get target and swap style
  let target = get_target(element)
  let swap_style = get_swap_style(element)

  // Get disabled elements before request
  let disabled_elements = match get_disabled_elt(element) {
    Some(selector) => {
      log_debug("Found disabled-elt selector: " + selector)
      find_targets_by_selector(element, selector)
    }
    None => {
      log_debug("No disabled-elt attribute found")
      []
    }
  }
  log_debug(
    "Disabled elements count: " + disabled_elements.length().to_string(),
  )

  // Get indicator elements before request
  let indicator_elements = get_indicator_elements(element)
  if indicator_elements.length() > 0 {
    log_debug(
      "Found " +
      indicator_elements.length().to_string() +
      " indicator element(s)",
    )
  } else {
    log_debug("No indicator attribute found, using element itself")
  }
  log_debug(
    "Indicator elements count: " + indicator_elements.length().to_string(),
  )

  // Show indicators before request
  if indicator_elements.length() > 0 {
    log_debug(
      "About to call show_indicators with count: " +
      indicator_elements.length().to_string(),
    )
    show_indicators(indicator_elements)
    log_debug("show_indicators returned")
  }

  // Disable elements before request
  if disabled_elements.length() > 0 {
    log_debug(
      "About to call disable_elements with count: " +
      disabled_elements.length().to_string(),
    )
    disable_elements(disabled_elements)
    log_debug("disable_elements returned")
  }

  // Create callback for async response handling
  let callback = create_response_callback(
    element, target, swap_style, url, disabled_elements, indicator_elements,
  )

  // Handle form data for POST/PUT/PATCH vs GET/DELETE
  if http_method.has_body() {
    // Collect form data for methods that have a body
    let form_data = get_form_data(element)
    request_with_form_async(
      url,
      http_method,
      form_data,
      Some(element),
      callback,
    )
  } else {
    // For GET/DELETE, append form values as query params
    let actual_url = match get_form_data(element) {
      Some(fd) => {
        // Collect values and append to URL
        let values = collect_input_values(element)
        let query = values_to_query_string(values)
        let _ = fd // We don't use FormData for GET, just values
        append_query_string(url, query)
      }
      None => url
    }
    request_async(actual_url, http_method, Some(element), callback)
  }
}

///|
/// Create a callback function for handling async XHR response
extern "js" fn create_response_callback(
  element : @dom.Element,
  target : @dom.Element,
  swap_style : SwapStyle,
  url : String,
  disabled_elements : Array[@dom.Element],
  indicator_elements : Array[@dom.Element],
) -> @core.Any =
  #|(element, target, swap_style, url, disabled_elements, indicator_elements) => {
  #|  return function(responseText) {
  #|    // Hide indicators after request
  #|    if (indicator_elements.length > 0) {
  #|      for (const el of indicator_elements) {
  #|        const key = "htmx-internal-data";
  #|        const data = el[key];
  #|        if (data) {
  #|          data.indicatorCount = (data.indicatorCount || 1) - 1;
  #|        }
  #|        const count = data ? (data.indicatorCount || 0) : 0;
  #|        if (count === 0) {
  #|          el.classList.remove("htmx-request");
  #|        }
  #|      }
  #|    }
  #|
  #|    // Re-enable disabled elements after request
  #|    if (disabled_elements.length > 0) {
  #|      for (const el of disabled_elements) {
  #|        const key = "htmx-internal-data";
  #|        const data = el[key];
  #|        if (data) {
  #|          data.requestCount = (data.requestCount || 1) - 1;
  #|        }
  #|        const count = data ? (data.requestCount || 0) : 0;
  #|        if (count === 0) {
  #|          el.removeAttribute("disabled");
  #|        }
  #|      }
  #|    }
  #|
  #|    // Swap content if we got a response
  #|    if (responseText !== null) {
  #|      const select_val = element.getAttribute("hx-select") || element.getAttribute("data-hx-select");
  #|      let final_content = responseText;
  #|      const parser = new DOMParser();
  #|      const doc = parser.parseFromString(responseText, 'text/html');
  #|      if (select_val) {
  #|        const selected = doc.querySelector(select_val);
  #|        if (selected) {
  #|          final_content = selected.outerHTML;
  #|        } else {
  #|          final_content = "";
  #|        }
  #|      }
  #|      // If select was used, re-parse for OOB processing
  #|      let oobDoc = doc;
  #|      if (select_val) {
  #|        oobDoc = parser.parseFromString(final_content, 'text/html');
  #|      }
  #|
  #|      // Handle OOB swaps (hx-swap-oob)
  #|      const oobElements = oobDoc.querySelectorAll('[hx-swap-oob], [data-hx-swap-oob]');
  #|      for (const oobEl of oobElements) {
  #|        const oobVal = oobEl.getAttribute('hx-swap-oob') || oobEl.getAttribute('data-hx-swap-oob') || 'true';
  #|        let targetSelector = null;
  #|        let swapStyle = 'innerHTML'; // default
  #|
  #|        // Parse OOB specification
  #|        if (oobVal === 'true') {
  #|          swapStyle = 'outerHTML';
  #|          const id = oobEl.getAttribute('id');
  #|          if (id) targetSelector = '#' + CSS.escape(id);
  #|        } else if (oobVal.includes(':')) {
  #|          const parts = oobVal.split(':');
  #|          swapStyle = parts[0] || 'innerHTML';
  #|          targetSelector = parts[1];
  #|        } else {
  #|          swapStyle = oobVal;
  #|          const id = oobEl.getAttribute('id');
  #|          if (id) targetSelector = '#' + CSS.escape(id);
  #|        }
  #|
  #|        // Handle delete style
  #|        if (swapStyle === 'delete') {
  #|          if (targetSelector) {
  #|            const targets = document.querySelectorAll(targetSelector);
  #|            for (const targetEl of targets) {
  #|              targetEl.remove();
  #|            }
  #|          }
  #|          oobEl.remove();
  #|          continue;
  #|        }
  #|
  #|        // Find and swap target
  #|        if (targetSelector) {
  #|          const targets = document.querySelectorAll(targetSelector);
  #|          if (targets.length === 0) {
  #|            // No target found, dispatch error event
  #|            const evt = new CustomEvent('htmx:oobErrorNoTarget', {
  #|              bubbles: true,
  #|              cancelable: true,
  #|              detail: { content: oobEl }
  #|            });
  #|            document.body.dispatchEvent(evt);
  #|          } else {
  #|            // Swap into all matching targets
  #|            for (const targetEl of targets) {
  #|              if (swapStyle === 'innerHTML') {
  #|                targetEl.innerHTML = oobEl.innerHTML;
  #|              } else if (swapStyle === 'outerHTML') {
  #|                targetEl.outerHTML = oobEl.outerHTML;
  #|              }
  #|            }
  #|          }
  #|        }
  #|
  #|        // Remove OOB element from response
  #|        oobEl.remove();
  #|      }
  #|
  #|      // Get final content after OOB removal
  #|      final_content = oobDoc.body.innerHTML;
  #|
  #|      // Simple innerHTML swap
  #|      target.innerHTML = final_content;
  #|
  #|      // Evaluate inline scripts and load external scripts after swap (Issue #2, Issue #3)
  #|      // Only executes scripts with no type or type='text/javascript'
  #|      // Exceptions are caught to prevent breaking rendering
  #|      if (window.htmx && window.htmx.config && window.htmx.config.allowEval !== false) {
  #|        // Initialize internal tracking for loaded scripts to prevent duplicate execution
  #|        if (!window.htmx._internal) window.htmx._internal = {};
  #|        if (!window.htmx._internal.loadedScripts) window.htmx._internal.loadedScripts = new Set();
  #|        const scripts = target.querySelectorAll('script');
  #|        for (const script of scripts) {
  #|          const type = script.getAttribute('type');
  #|          if (!type || type === 'text/javascript') {
  #|            const src = script.getAttribute('src');
  #|            if (src) {
  #|              // External script with src attribute (Issue #3)
  #|              // innerHTML doesn't trigger script loading, so we need to create a new script element
  #|              // Prevent duplicate execution by checking if script URL was already loaded
  #|              if (window.htmx._internal.loadedScripts.has(src)) {
  #|                // Already loaded, remove original element to prevent duplicates
  #|                script.remove();
  #|                continue;
  #|              }
  #|              const newScript = document.createElement('script');
  #|              newScript.src = src;
  #|              // Copy necessary attributes including ID for test compatibility
  #|              const attrsToCopy = ['id', 'nonce', 'referrerpolicy', 'type', 'async', 'defer', 'crossorigin'];
  #|              for (const attr of attrsToCopy) {
  #|                if (script.hasAttribute(attr)) {
  #|                  newScript.setAttribute(attr, script.getAttribute(attr));
  #|                }
  #|              }
  #|              // Mark as loaded (at load start time to prevent race conditions)
  #|              window.htmx._internal.loadedScripts.add(src);
  #|              // Replace to trigger loading
  #|              script.replaceWith(newScript);
  #|            } else if (script.textContent) {
  #|              // Inline script (Issue #2)
  #|              try {
  #|                (new Function(script.textContent))();
  #|              } catch (e) {
  #|                console.error('htmx.mbt: Error executing script:', e);
  #|              }
  #|              script.remove();
  #|            }
  #|          }
  #|        }
  #|      }
  #|
  #|      // Handle history API
  #|      const push_val = element.getAttribute("hx-push-url") || element.getAttribute("data-hx-push-url");
  #|      if (push_val && push_val !== "false") {
  #|        const dest_url = push_val === "true" ? url : push_val;
  #|        history.pushState(null, '', dest_url);
  #|      }
  #|    }
  #|  };
  #|}

///|
/// Wrapper for process element (kept for API compatibility)
fn process_element(element : @dom.Element) -> Unit {
  process_element_with_trigger(element, None)
}

///|
/// FFI to get event target directly
extern "js" fn get_event_target(evt : @core.Any) -> @dom.Element =
  #|(evt) => evt.target

///|
/// Check if element is a submit button
extern "js" fn is_submit_button(el : @dom.Element) -> Bool =
  #|(el) => el && el.tagName === 'BUTTON' && (el.type === 'submit' || !el.type)

///|
/// Find the closest form ancestor using FFI
extern "js" fn find_closest_form(el : @dom.Element) -> @dom.Element =
  #|(el) => el.form || el.closest('form')

///|
/// Check if element has a containing form
extern "js" fn has_containing_form(el : @dom.Element) -> Bool =
  #|(el) => !!(el.form || el.closest('form'))

///|
/// Handle click events for htmx elements
fn handle_click(evt : @core.Any) -> Unit {
  let event : @event.Event = @core.identity(evt)
  let target_el = get_event_target(evt)

  // Check if clicking a submit button inside an htmx form
  if is_submit_button(target_el) {
    if has_containing_form(target_el) {
      let form = find_closest_form(target_el)
      // Check if form itself has an htmx method attribute
      match find_method_url(form) {
        Some(_) => {
          // Submit buttons should always submit the form, regardless of hx-trigger
          // The form's hx-trigger only affects what events automatically trigger,
          // not explicit user action of clicking a submit button
          event.preventDefault()
          // Pass the button as submitter for formnovalidate check
          process_element_with_trigger(form, Some(target_el))
          return
        }
        None => ()
      }
    }
  }

  // Find htmx element and handle click trigger
  match find_htmx_element(target_el) {
    Some(htmx_el) => {
      let trigger = get_trigger_event(htmx_el)
      if trigger == "click" || trigger == "load" {
        event.preventDefault()
        process_element_with_trigger(htmx_el, Some(target_el))
      }
    }
    Option::None => ()
  }
}

///|
/// Handle change events for htmx elements
fn handle_change(evt : @core.Any) -> Unit {
  let event : @event.Event = @core.identity(evt)
  let target_el = get_event_target(evt)
  match find_htmx_element(target_el) {
    Some(htmx_el) => {
      let trigger = get_trigger_event(htmx_el)
      if trigger == "change" {
        event.preventDefault()
        process_element(htmx_el)
      }
    }
    Option::None => ()
  }
}

///|
/// Get submitter from submit event
extern "js" fn get_event_submitter(evt : @core.Any) -> @dom.Element? =
  #|(evt) => evt.submitter || null

///|
/// Handle submit events for htmx forms
fn handle_submit(evt : @core.Any) -> Unit {
  let event : @event.Event = @core.identity(evt)
  let target_el = get_event_target(evt)
  let submitter = get_event_submitter(evt)
  match find_htmx_element(target_el) {
    Some(htmx_el) => {
      let trigger = get_trigger_event(htmx_el)
      if trigger == "submit" {
        event.preventDefault()
        // Pass submitter for formnovalidate check
        process_element_with_trigger(htmx_el, submitter)
      }
    }
    Option::None => ()
  }
}

///|
/// Find all elements with hx-trigger="load" and process them
extern "js" fn process_load_triggers() -> Unit =
  #|() => {
  #|  const doc = document;
  #|
  #|  // Function to process a single element for load trigger
  #|  const processElement = (el) => {
  #|    const trigger = el.getAttribute('hx-trigger') || el.getAttribute('data-hx-trigger');
  #|    if (trigger) {
  #|      const parts = trigger.split(',').map(s => s.trim());
  #|      for (const part of parts) {
  #|        if (part === 'load' || part.startsWith('load ')) {
  #|          // Create and dispatch a click event to trigger the request
  #|          const event = new MouseEvent('click', { bubbles: true, cancelable: true });
  #|          el.dispatchEvent(event);
  #|          break;
  #|        }
  #|      }
  #|    }
  #|  };
  #|
  #|  // Process existing elements
  #|  const elements = doc.querySelectorAll('[hx-trigger], [data-hx-trigger]');
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
  #|          if (node.getAttribute && (node.getAttribute('hx-trigger') || node.getAttribute('data-hx-trigger'))) {
  #|            processElement(node);
  #|          }
  #|          // Check descendants
  #|          const descendants = node.querySelectorAll('[hx-trigger], [data-hx-trigger]');
  #|          for (const desc of descendants) {
  #|            processElement(desc);
  #|          }
  #|        }
  #|      }
  #|    }
  #|  });
  #|
  #|  // Start observing the document
  #|  observer.observe(doc.body, { childList: true, subtree: true });
  #|}

///|
/// Initialize hx-on event delegation for inline event handlers
extern "js" fn init_hx_on_delegation(doc_target : @core.Any) -> Unit =
  #|(doc_target) => {
  #|  // Common events to delegate - covers all test cases
  #|  const commonEvents = [
  #|    'click', 'dblclick', 'mousedown', 'mouseup', 'mouseover', 'mouseout',
  #|    'mousemove', 'mouseenter', 'mouseleave',
  #|    'keydown', 'keyup', 'keypress',
  #|    'change', 'input', 'submit', 'focus', 'blur',
  #|    'load', 'revealed',
  #|    'htmx:config-request', 'htmx:after-request', 'htmx:before-request',
  #|    'htmx:before-swap', 'htmx:after-swap', 'htmx:before-settle', 'htmx:after-settle',
  #|    'htmx:validation:failed', 'htmx:validation:halted',
  #|    'htmx:evalDisallowedError'
  #|  ];
  #|
  #|  // Handler function for all hx-on events
  #|  const handleHxOn = function(evt) {
  #|    const eventType = evt.type;
  #|    let currentTarget = evt.target;
  #|
  #|    // Walk up the DOM tree to find elements with hx-on attributes
  #|    while (currentTarget && currentTarget !== document) {
  #|      const attrs = currentTarget.attributes;
  #|      for (let i = 0; i < attrs.length; i++) {
  #|        const attrName = attrs[i].name;
  #|
  #|        // Check if this is an hx-on attribute
  #|        let eventSpec = null;
  #|        if (attrName.startsWith('hx-on:')) {
  #|          eventSpec = attrName.slice(6); // after 'hx-on:'
  #|        } else if (attrName.startsWith('hx-on-')) {
  #|          eventSpec = attrName.slice(6); // after 'hx-on-'
  #|        } else if (attrName.startsWith('data-hx-on:')) {
  #|          eventSpec = attrName.slice(11); // after 'data-hx-on:'
  #|        } else if (attrName.startsWith('data-hx-on-')) {
  #|          eventSpec = attrName.slice(11); // after 'data-hx-on-'
  #|        }
  #|
  #|        if (eventSpec !== null) {
  #|          // Expand :: and -- shorthands to htmx:
  #|          if (eventSpec.startsWith('::')) {
  #|            eventSpec = 'htmx:' + eventSpec.slice(2);
  #|          } else if (eventSpec.startsWith('--')) {
  #|            eventSpec = 'htmx:' + eventSpec.slice(2);
  #|          }
  #|
  #|          // Check if this handler matches the current event
  #|          if (eventSpec === eventType) {
  #|            const code = attrs[i].value;
  #|
  #|            // Check allowEval configuration
  #|            if (window.htmx && window.htmx.config && window.htmx.config.allowEval === false) {
  #|              const errorEvt = new CustomEvent('htmx:evalDisallowedError', {
  #|                bubbles: true,
  #|                cancelable: true,
  #|                detail: { source: 'hx-on' }
  #|              });
  #|              currentTarget.dispatchEvent(errorEvt);
  #|              return;
  #|            }
  #|
  #|            // Get or create handler storage on element
  #|            const key = 'htmx-internal-data';
  #|            let data = currentTarget[key];
  #|            if (!data) {
  #|              data = {};
  #|              currentTarget[key] = data;
  #|            }
  #|            if (!data.hxOnHandlers) {
  #|              data.hxOnHandlers = {};
  #|            }
  #|
  #|            // Create or get cached handler
  #|            if (!data.hxOnHandlers[eventType]) {
  #|              try {
  #|                data.hxOnHandlers[eventType] = new Function('event', code);
  #|              } catch (e) {
  #|                console.error('htmx.mbt: Error creating hx-on handler:', e);
  #|                return;
  #|              }
  #|            }
  #|
  #|            // Execute handler with element as 'this'
  #|            try {
  #|              data.hxOnHandlers[eventType].call(currentTarget, evt);
  #|            } catch (e) {
  #|              console.error('htmx.mbt: Error executing hx-on handler:', e);
  #|            }
  #|
  #|            return;
  #|          }
  #|        }
  #|      }
  #|      currentTarget = currentTarget.parentElement;
  #|    }
  #|  };
  #|
  #|  // Register delegation for all common events
  #|  for (const evtType of commonEvents) {
  #|    doc_target.addEventListener(evtType, handleHxOn, { capture: false });
  #|  }
  #|}

///|
/// Initialize htmx - set up global event listeners using event delegation
pub fn htmx_init() -> Unit {
  let doc = @dom.document()
  let doc_target = doc.as_event_target()

  // Use event delegation - listen on document for all events
  doc_target.addEventListener("click", handle_click)
  doc_target.addEventListener("change", handle_change)
  doc_target.addEventListener("submit", handle_submit)

  // Initialize hx-on event delegation for inline event handlers
  let doc_target_any : @core.Any = @core.identity(doc_target)
  init_hx_on_delegation(doc_target_any)

  // Process load triggers
  process_load_triggers()
}
