///|
/// Debug log for processor
extern "js" fn log_debug(msg : String) -> Unit =
  #|(msg) => console.log("[htmx.mbt DEBUG] " + msg)

///|
/// Convert values array (Array[(String, String)]) to JavaScript object
extern "js" fn values_to_js_object(
  values : Array[(String, String)],
) -> @core.Any =
  #|(values) => {
  #|  const obj = {};
  #|  if (values && values.buf) {
  #|    for (let i = values.start || 0; i < (values.end || values.buf.length); i++) {
  #|      const entry = values.buf[i];
  #|      if (entry && entry._0 !== undefined) {
  #|        obj[entry._0] = entry._1;
  #|      }
  #|    }
  #|  }
  #|  return obj;
  #|}

///|
/// Merge source object into target object
extern "js" fn merge_objects(target : @core.Any, source : @core.Any) -> Unit =
  #|(target, source) => {
  #|  if (target && source) {
  #|    for (const key in source) {
  #|      if (source.hasOwnProperty(key)) {
  #|        target[key] = source[key];
  #|      }
  #|    }
  #|  }
  #|}

///|
/// Convert JavaScript object to Map
extern "js" fn js_object_to_map(obj : @core.Any) -> Map[String, String] =
  #|(obj) => {
  #|  const result = {};
  #|  if (obj) {
  #|    for (const key in obj) {
  #|      if (obj.hasOwnProperty(key)) {
  #|        const val = obj[key];
  #|        // Convert value to string
  #|        result[key] = (val === null || val === undefined) ? '' : String(val);
  #|      }
  #|    }
  #|  }
  #|  return result;
  #|}

///|
/// Process a single htmx element - perform request and swap (async for proper disabled-elt behavior)
fn process_element_with_trigger(
  element : @dom.Element,
  trigger_el : @dom.Element?,
) -> Unit {
  let trigger_tag = match trigger_el {
    Some(el) => el.tagName()
    None => "none"
  }
  log_debug(
    "process_element_with_trigger called: element=" +
    element.tagName() +
    " trigger_el=" +
    trigger_tag,
  )

  // Find method and URL
  let method_url = find_method_url(element)
  log_debug(
    "method_url found: " +
    (match method_url {
      Some(_) => "yes"
      None => "no"
    }),
  )
  guard method_url is Some((method_str, url)) else { return }

  // Convert method string to HttpMethod
  let http_method = match HttpMethod::from_string(method_str) {
    Some(m) => m
    None => {
      log_debug("Unknown method: " + method_str)
      return
    }
  }

  // Validate form before making request (pass trigger element for formnovalidate check)
  let validation_result = validate_element_with_trigger(element, trigger_el)
  log_debug(
    "validation_result: " +
    (match validation_result {
      true => "passed"
      false => "failed"
    }),
  )
  if not(validation_result) {
    return
  }

  // Get target and swap style (with inheritance support)
  log_debug(
    "About to call get_target_with_inherit on element: " + element.tagName(),
  )
  let target = get_target_with_inherit(element)
  log_debug("Target element: " + target.tagName())
  let swap_style = get_swap_style_with_inherit(element)
  let swap_style_str = swap_style.to_htmx_string()

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
    element, target, swap_style_str, url, disabled_elements, indicator_elements,
  )

  // Collect hx-vars/hx-vals from element and parents
  let expression_vars = get_expression_vars(Some(element), None)

  // Fire htmx:config-request event to allow modification of parameters
  // Collect input values for the event
  let input_values = collect_input_values(element)
  let parameters = values_to_js_object(input_values)
  // Add hx-vars to parameters
  let vars_any = map_to_any(expression_vars)
  merge_objects(parameters, vars_any)

  // Fire the config request event - this may modify parameters
  let headers : Map[String, String] = { "HX-Request": "true" }
  let headers_any = map_to_any(headers)
  let config_allowed = fire_config_request_event(
    element, parameters, headers_any,
  )

  // If event was prevented, don't send request
  if not(config_allowed) {
    log_debug("htmx:config-request was prevented, aborting request")
    // Hide indicators and re-enable elements before returning
    if indicator_elements.length() > 0 {
      hide_indicators(indicator_elements)
    }
    if disabled_elements.length() > 0 {
      enable_elements(disabled_elements)
    }
    return
  }

  // Handle form data for POST/PUT/PATCH vs GET/DELETE
  if http_method.has_body() {
    // Use modified parameters directly - convert JavaScript object to FormData
    let form_data_from_params = js_object_to_form_data(parameters)
    request_with_form_async(
      url,
      http_method,
      Some(form_data_from_params),
      Some(element),
      callback,
    )
  } else {
    // For GET/DELETE, append modified parameters as query params
    let actual_url = js_object_to_query_string(url, parameters)
    request_async(actual_url, http_method, Some(element), callback)
  }
}

///|
/// Convert JavaScript object (potentially modified by event handlers) to FormData
extern "js" fn js_object_to_form_data(obj : @core.Any) -> @http.FormData =
  #|(obj) => {
  #|  const fd = new FormData();
  #|  if (obj && obj.buf && Array.isArray(obj.buf)) {
  #|    // Moonbit Map structure with array buffer
  #|    const buf = obj.buf;
  #|    for (let i = obj.start || 0; i < (obj.end || buf.length); i++) {
  #|      const entry = buf[i];
  #|      if (entry && entry._0 !== undefined) {
  #|        fd.append(entry._0, entry._1);
  #|      }
  #|    }
  #|  } else if (obj && typeof obj === 'object') {
  #|    // Plain object - iterate over keys
  #|    for (const key in obj) {
  #|      if (obj.hasOwnProperty(key) && key !== 'buf' && key !== 'start' && key !== 'end') {
  #|        const val = obj[key];
  #|        fd.append(key, val);
  #|      }
  #|    }
  #|  }
  #|  return fd;
  #|}

///|
/// Convert JavaScript object to query string and append to URL
extern "js" fn js_object_to_query_string(
  url : String,
  obj : @core.Any,
) -> String =
  #|(url, obj) => {
  #|  const queryParts = [];
  #|  if (obj && obj.buf && Array.isArray(obj.buf)) {
  #|    // Moonbit Map structure with array buffer
  #|    const buf = obj.buf;
  #|    for (let i = obj.start || 0; i < (obj.end || buf.length); i++) {
  #|      const entry = buf[i];
  #|      if (entry && entry._0 !== undefined) {
  #|        queryParts.push(encodeURIComponent(entry._0) + '=' + encodeURIComponent(entry._1));
  #|      }
  #|    }
  #|  } else if (obj && typeof obj === 'object') {
  #|    // Plain object - iterate over keys
  #|    for (const key in obj) {
  #|      if (obj.hasOwnProperty(key) && key !== 'buf' && key !== 'start' && key !== 'end') {
  #|        const val = obj[key];
  #|        queryParts.push(encodeURIComponent(key) + '=' + encodeURIComponent(val));
  #|      }
  #|    }
  #|  }
  #|  if (queryParts.length > 0) {
  #|    const separator = url.includes('?') ? '&' : '?';
  #|    return url + separator + queryParts.join('&');
  #|  }
  #|  return url;
  #|}

///|
/// Create a callback function for handling async XHR response
extern "js" fn create_response_callback(
  element : @dom.Element,
  target : @dom.Element,
  swap_style_str : String,
  url : String,
  disabled_elements : Array[@dom.Element],
  indicator_elements : Array[@dom.Element],
) -> @core.Any =
  #|(element, target, swap_style_str, url, disabled_elements, indicator_elements) => {
  #|  return function(responseText) {
  #|    console.log('[htmx.mbt CALLBACK] responseText:', responseText, 'target:', target.tagName, 'target.innerHTML:', target.innerHTML);
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
  #|      const htmx = window.htmx || {};
  #|      const config = htmx.config || {};
  #|      const selectVal = element.getAttribute("hx-select") || element.getAttribute("data-hx-select");
  #|      const swapSpecFn = htmx._ ? htmx._('getSwapSpecification') : null;
  #|      const swapSpec = swapSpecFn ? swapSpecFn(element) : null;
  #|      const defaultSwapStyle = typeof config.defaultSwapStyle === 'string'
  #|        ? config.defaultSwapStyle
  #|        : 'innerHTML';
  #|      // Use the passed swap_style_str (with inheritance support) as priority
  #|      const swapStyle = swap_style_str && typeof swap_style_str === 'string'
  #|        ? swap_style_str
  #|        : (swapSpec && typeof swapSpec.swapStyle === 'string'
  #|          ? swapSpec.swapStyle
  #|          : defaultSwapStyle);
  #|      const swapDelay = swapSpec && typeof swapSpec.swapDelay === 'number' ? swapSpec.swapDelay : 0;
  #|      const settleDelay = swapSpec && typeof swapSpec.settleDelay === 'number'
  #|        ? swapSpec.settleDelay
  #|        : (typeof config.defaultSettleDelay === 'number' ? config.defaultSettleDelay : 0);
  #|      const transition = swapSpec && swapSpec.transition === true;
  #|      const scrollSpec = swapSpec ? swapSpec.scroll : null;
  #|      const showSpec = swapSpec ? swapSpec.show : null;
  #|      const allowNestedOobSwaps = config.allowNestedOobSwaps !== false;
  #|      const knownSwapStyles = new Set([
  #|        'innerHTML',
  #|        'outerHTML',
  #|        'beforebegin',
  #|        'afterbegin',
  #|        'beforeend',
  #|        'afterend',
  #|        'delete',
  #|        'none',
  #|        'morph',
  #|        'textContent'
  #|      ]);
  #|      const resolvedStyle = knownSwapStyles.has(swapStyle) ? swapStyle : defaultSwapStyle;
  #|      const parser = new DOMParser();
  #|      let finalContent = responseText;
  #|      let oobDoc = null;
  #|      if (resolvedStyle !== 'textContent') {
  #|        let doc = parser.parseFromString(responseText, 'text/html');
  #|        if (selectVal) {
  #|          const selected = doc.querySelector(selectVal);
  #|          finalContent = selected ? selected.outerHTML : '';
  #|          doc = parser.parseFromString(finalContent, 'text/html');
  #|        } else {
  #|          finalContent = doc.body.innerHTML;
  #|        }
  #|        oobDoc = doc;
  #|        const rootNode = element && element.getRootNode ? element.getRootNode() : document;
  #|        const localRoot = rootNode && rootNode.querySelectorAll ? rootNode : document;
  #|        const stripOobAttrs = (oobEl) => {
  #|          oobEl.removeAttribute('hx-swap-oob');
  #|          oobEl.removeAttribute('data-hx-swap-oob');
  #|        };
  #|        const escapeId = (id) => {
  #|          if (!id) return null;
  #|          if (window.CSS && CSS.escape) return '#' + CSS.escape(id);
  #|          return '[id="' + String(id).replace(/"/g, '\\"') + '"]';
  #|        };
  #|        const normalizeOobStyle = (style) => {
  #|          const allowed = [
  #|            'innerHTML',
  #|            'outerHTML',
  #|            'beforebegin',
  #|            'afterbegin',
  #|            'beforeend',
  #|            'afterend',
  #|            'delete',
  #|            'none',
  #|            'morph'
  #|          ];
  #|          return allowed.includes(style) ? style : 'innerHTML';
  #|        };
  #|        const parseOobSpec = (oobEl) => {
  #|          const rawVal = oobEl.getAttribute('hx-swap-oob') || oobEl.getAttribute('data-hx-swap-oob') || 'true';
  #|          let swap = 'innerHTML';
  #|          let targetSelector = null;
  #|          if (rawVal === 'true') {
  #|            swap = 'outerHTML';
  #|            targetSelector = escapeId(oobEl.getAttribute('id'));
  #|          } else if (rawVal.includes(':')) {
  #|            const parts = rawVal.split(':');
  #|            swap = parts[0] || 'innerHTML';
  #|            targetSelector = parts.slice(1).join(':');
  #|          } else {
  #|            swap = rawVal;
  #|            targetSelector = escapeId(oobEl.getAttribute('id'));
  #|          }
  #|          let isGlobal = false;
  #|          if (targetSelector) {
  #|            const trimmed = targetSelector.trim();
  #|            if (trimmed.startsWith('global ')) {
  #|              isGlobal = true;
  #|              targetSelector = trimmed.slice(7).trim();
  #|            } else if (trimmed === 'global') {
  #|              isGlobal = true;
  #|              targetSelector = null;
  #|            } else {
  #|              targetSelector = trimmed;
  #|            }
  #|          }
  #|          return { swapStyle: normalizeOobStyle(swap), targetSelector, isGlobal };
  #|        };
  #|        const selectTargets = (spec) => {
  #|          if (!spec.targetSelector) return [];
  #|          const root = spec.isGlobal ? document : localRoot;
  #|          if (!root || !root.querySelectorAll) return [];
  #|          try {
  #|            return Array.from(root.querySelectorAll(spec.targetSelector));
  #|          } catch (e) {
  #|            return [];
  #|          }
  #|        };
  #|        const applyOobSwap = (targetEl, spec, innerHtml, outerHtml) => {
  #|          switch (spec.swapStyle) {
  #|            case 'innerHTML':
  #|              targetEl.innerHTML = innerHtml;
  #|              break;
  #|            case 'outerHTML':
  #|              targetEl.outerHTML = outerHtml;
  #|              break;
  #|            case 'beforebegin':
  #|              targetEl.insertAdjacentHTML('beforebegin', outerHtml);
  #|              break;
  #|            case 'afterbegin':
  #|              targetEl.insertAdjacentHTML('afterbegin', innerHtml);
  #|              break;
  #|            case 'beforeend':
  #|              targetEl.insertAdjacentHTML('beforeend', innerHtml);
  #|              break;
  #|            case 'afterend':
  #|              targetEl.insertAdjacentHTML('afterend', outerHtml);
  #|              break;
  #|            case 'delete':
  #|              targetEl.remove();
  #|              break;
  #|            case 'none':
  #|              break;
  #|            default:
  #|              targetEl.innerHTML = innerHtml;
  #|              break;
  #|          }
  #|        };
  #|        const handleOobElement = (oobEl, fromTemplate) => {
  #|          const parent = oobEl.parentElement;
  #|          const isNested = !fromTemplate && !allowNestedOobSwaps &&
  #|            parent && parent !== oobDoc.body && parent.tagName !== 'BODY';
  #|          if (isNested) {
  #|            stripOobAttrs(oobEl);
  #|            return;
  #|          }
  #|          const spec = parseOobSpec(oobEl);
  #|          const targets = selectTargets(spec);
  #|          if (spec.swapStyle === 'delete') {
  #|            for (const targetEl of targets) {
  #|              targetEl.remove();
  #|            }
  #|            oobEl.remove();
  #|            return;
  #|          }
  #|          stripOobAttrs(oobEl);
  #|          if (targets.length === 0) {
  #|            if (spec.targetSelector) {
  #|              const evt = new CustomEvent('htmx:oobErrorNoTarget', {
  #|                bubbles: true,
  #|                cancelable: true,
  #|                detail: { content: oobEl }
  #|              });
  #|              document.body.dispatchEvent(evt);
  #|            }
  #|            oobEl.remove();
  #|            return;
  #|          }
  #|          const innerHtml = oobEl.innerHTML;
  #|          const outerHtml = oobEl.outerHTML;
  #|          for (const targetEl of targets) {
  #|            applyOobSwap(targetEl, spec, innerHtml, outerHtml);
  #|          }
  #|          oobEl.remove();
  #|        };
  #|        const templates = oobDoc.querySelectorAll('template');
  #|        for (const template of templates) {
  #|          const content = template.content;
  #|          if (!content) {
  #|            continue;
  #|          }
  #|          const nestedOobs = content.querySelectorAll('[hx-swap-oob], [data-hx-swap-oob]');
  #|          if (nestedOobs.length === 0) {
  #|            continue;
  #|          }
  #|          for (const oobEl of nestedOobs) {
  #|            handleOobElement(oobEl, true);
  #|          }
  #|          template.remove();
  #|        }
  #|        const oobElements = oobDoc.querySelectorAll('[hx-swap-oob], [data-hx-swap-oob]');
  #|        for (const oobEl of oobElements) {
  #|          handleOobElement(oobEl, false);
  #|        }
  #|        finalContent = oobDoc.body.innerHTML;
  #|      }
  #|      const dispatchSwapError = (err) => {
  #|        const evt = new CustomEvent('htmx:swapError', {
  #|          bubbles: true,
  #|          cancelable: true,
  #|          detail: { error: err }
  #|        });
  #|        document.body.dispatchEvent(evt);
  #|      };
  #|      const applySwap = (content) => {
  #|        switch (resolvedStyle) {
  #|          case 'innerHTML':
  #|            target.innerHTML = content;
  #|            break;
  #|          case 'outerHTML':
  #|            if (target.tagName && target.tagName.toUpperCase() === 'BODY') {
  #|              target.innerHTML = content;
  #|            } else {
  #|              target.outerHTML = content;
  #|            }
  #|            break;
  #|          case 'beforebegin':
  #|            target.insertAdjacentHTML('beforebegin', content);
  #|            break;
  #|          case 'afterbegin':
  #|            target.insertAdjacentHTML('afterbegin', content);
  #|            break;
  #|          case 'beforeend':
  #|            target.insertAdjacentHTML('beforeend', content);
  #|            break;
  #|          case 'afterend':
  #|            target.insertAdjacentHTML('afterend', content);
  #|            break;
  #|          case 'delete':
  #|            target.remove();
  #|            break;
  #|          case 'none':
  #|            break;
  #|          case 'textContent':
  #|            target.textContent = content;
  #|            break;
  #|          case 'morph':
  #|            target.innerHTML = content;
  #|            break;
  #|          default:
  #|            target.innerHTML = content;
  #|            break;
  #|        }
  #|      };
  #|      const resolveScrollTarget = (spec) => {
  #|        if (!spec) return null;
  #|        if (!spec.target || spec.target === 'window') {
  #|          return document.body;
  #|        }
  #|        return document.querySelector(spec.target);
  #|      };
  #|      const settleActions = () => {
  #|        if (scrollSpec && scrollSpec.direction) {
  #|          const scrollTarget = resolveScrollTarget(scrollSpec);
  #|          if (scrollTarget) {
  #|            if (scrollSpec.direction === 'top') {
  #|              if (scrollTarget === document.body) {
  #|                window.scrollTo(0, 0);
  #|              } else {
  #|                scrollTarget.scrollTop = 0;
  #|              }
  #|            } else if (scrollSpec.direction === 'bottom') {
  #|              if (scrollTarget === document.body) {
  #|                window.scrollTo(0, document.body.scrollHeight);
  #|              } else {
  #|                scrollTarget.scrollTop = scrollTarget.scrollHeight;
  #|              }
  #|            }
  #|          }
  #|        }
  #|        if (showSpec && showSpec.direction) {
  #|          const showTarget = resolveScrollTarget(showSpec);
  #|          if (showTarget && typeof showTarget.scrollIntoView === 'function') {
  #|            const block = showSpec.direction === 'bottom' ? 'end' : 'start';
  #|            showTarget.scrollIntoView({ block: block });
  #|          }
  #|        }
  #|      };
  #|      const doSwap = () => {
  #|        try {
  #|          console.log('[htmx.mbt SWAP] doSwap called: target.tagName=', target.tagName, 'finalContent=', finalContent, 'swapStyle=', resolvedStyle);
  #|          if (typeof window.makeSettleInfo === 'function') {
  #|            window.makeSettleInfo(target);
  #|          }
  #|          applySwap(finalContent);
  #|        } catch (e) {
  #|          dispatchSwapError(e);
  #|          return;
  #|        }
  #|        // Evaluate inline scripts and load external scripts after swap (Issue #2, Issue #3)
  #|        // Only executes scripts with no type or type='text/javascript'
  #|        // Exceptions are caught to prevent breaking rendering
  #|        if (window.htmx && window.htmx.config && window.htmx.config.allowEval !== false) {
  #|          // Initialize internal tracking for loaded scripts to prevent duplicate execution
  #|          if (!window.htmx._internal) window.htmx._internal = {};
  #|          if (!window.htmx._internal.loadedScripts) window.htmx._internal.loadedScripts = new Set();
  #|          const scripts = target.querySelectorAll('script');
  #|          for (const script of scripts) {
  #|            const type = script.getAttribute('type');
  #|            if (!type || type === 'text/javascript') {
  #|              const src = script.getAttribute('src');
  #|              if (src) {
  #|                // External script with src attribute (Issue #3)
  #|                // innerHTML doesn't trigger script loading, so we need to create a new script element
  #|                // Prevent duplicate execution by checking if script URL was already loaded
  #|                if (window.htmx._internal.loadedScripts.has(src)) {
  #|                  // Already loaded, remove original element to prevent duplicates
  #|                  script.remove();
  #|                  continue;
  #|                }
  #|                const newScript = document.createElement('script');
  #|                newScript.src = src;
  #|                // Copy necessary attributes including ID for test compatibility
  #|                const attrsToCopy = ['id', 'nonce', 'referrerpolicy', 'type', 'async', 'defer', 'crossorigin'];
  #|                for (const attr of attrsToCopy) {
  #|                  if (script.hasAttribute(attr)) {
  #|                    newScript.setAttribute(attr, script.getAttribute(attr));
  #|                  }
  #|                }
  #|                // Mark as loaded (at load start time to prevent race conditions)
  #|                window.htmx._internal.loadedScripts.add(src);
  #|                // Replace to trigger loading
  #|                script.replaceWith(newScript);
  #|              } else if (script.textContent) {
  #|                // Inline script (Issue #2)
  #|                try {
  #|                  (new Function(script.textContent))();
  #|                } catch (e) {
  #|                  console.error('htmx.mbt: Error executing script:', e);
  #|                }
  #|                script.remove();
  #|              }
  #|            }
  #|          }
  #|        }
  #|        // Handle history API
  #|        const push_val = element.getAttribute("hx-push-url") || element.getAttribute("data-hx-push-url");
  #|        if (push_val && push_val !== "false") {
  #|          const dest_url = push_val === "true" ? url : push_val;
  #|          history.pushState(null, '', dest_url);
  #|          // Save to history cache
  #|          if (window.htmx && window.htmx._ && typeof window.htmx._ === 'function') {
  #|            try {
  #|              window.htmx._('saveToHistoryCache')(dest_url, target);
  #|            } catch (e) {
  #|              // Ignore errors
  #|            }
  #|          }
  #|        }
  #|        if (settleDelay > 0) {
  #|          setTimeout(settleActions, settleDelay);
  #|        } else {
  #|          settleActions();
  #|        }
  #|      };
  #|      if (swapDelay > 0 || transition) {
  #|        setTimeout(doSwap, swapDelay);
  #|      } else {
  #|        doSwap();
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
  #|(evt) => {
  #|  if (evt && typeof evt.composedPath === 'function') {
  #|    const path = evt.composedPath();
  #|    if (path && path.length > 0 && path[0] && path[0].nodeType === 1) {
  #|      return path[0];
  #|    }
  #|  }
  #|  return evt.target;
  #|}

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
  log_debug("handle_click: target_el=" + target_el.tagName())

  // Check if clicking a submit button inside an htmx form
  if is_submit_button(target_el) {
    if has_containing_form(target_el) {
      let form = find_closest_form(target_el)
      // Check if the button itself has an htmx method attribute
      // If so, it should handle the click, not the form (indirect form submission)
      match find_method_url(target_el) {
        Some(_) => {
          // Button has its own htmx request, skip form submit handling
          // It will be processed by find_htmx_element below
          ()
        }
        None => {
          // Button doesn't have htmx, check if form does
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
    }
  }

  // Find htmx element and handle click trigger
  match find_htmx_element(target_el) {
    Some(htmx_el) => {
      log_debug(
        "handle_click: found htmx_el=" +
        htmx_el.tagName() +
        " trigger=" +
        get_trigger_event(htmx_el),
      )
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
  #|        // Check if this is an hx-on attribute (check :: and -- before : and -)
  #|        let eventSpec = null;
  #|        if (attrName.startsWith('hx-on::')) {
  #|          // :: shorthand for htmx: namespace
  #|          eventSpec = 'htmx:' + attrName.slice(8); // after 'hx-on::'
  #|        } else if (attrName.startsWith('hx-on:')) {
  #|          eventSpec = attrName.slice(6); // after 'hx-on:'
  #|        } else if (attrName.startsWith('hx-on--')) {
  #|          // -- shorthand for htmx: namespace
  #|          eventSpec = 'htmx:' + attrName.slice(8); // after 'hx-on--'
  #|        } else if (attrName.startsWith('hx-on-')) {
  #|          eventSpec = attrName.slice(6); // after 'hx-on-'
  #|        } else if (attrName.startsWith('data-hx-on::')) {
  #|          eventSpec = 'htmx:' + attrName.slice(13); // after 'data-hx-on::'
  #|        } else if (attrName.startsWith('data-hx-on:')) {
  #|          eventSpec = attrName.slice(11); // after 'data-hx-on:'
  #|        } else if (attrName.startsWith('data-hx-on--')) {
  #|          eventSpec = 'htmx:' + attrName.slice(13); // after 'data-hx-on--'
  #|        } else if (attrName.startsWith('data-hx-on-')) {
  #|          eventSpec = attrName.slice(11); // after 'data-hx-on-'
  #|        }
  #|
  #|        if (eventSpec !== null) {
  #|          // Convert htmx-* to htmx:* (for hx-on-htmx-* style)
  #|          if (eventSpec.startsWith('htmx-')) {
  #|            eventSpec = 'htmx:' + eventSpec.slice(5);
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

  // Process revealed triggers
  process_revealed_triggers()

  // Expose htmx.process API for test compatibility
  init_htmx_process_api()
}

///|
/// Initialize htmx.process API for processing dynamically added elements
extern "js" fn init_htmx_process_api() -> Unit =
  #|() => {
  #|  // Initialize window.htmx if it doesn't exist
  #|  if (!window.htmx) {
  #|    window.htmx = {};
  #|  }
  #|  // htmx.process() - Process an element and its children for htmx attributes
  #|  window.htmx.process = function(element) {
  #|    if (!element) return;
  #|    // Process the element itself for load triggers
  #|    const trigger = element.getAttribute('hx-trigger') || element.getAttribute('data-hx-trigger');
  #|    if (trigger) {
  #|      const parts = trigger.split(',').map(s => s.trim());
  #|      for (const part of parts) {
  #|        if (part === 'load' || part.startsWith('load ')) {
  #|          // Trigger load event
  #|          const event = new MouseEvent('click', { bubbles: true, cancelable: true });
  #|          element.dispatchEvent(event);
  #|          break;
  #|        } else if (part === 'revealed' || part.startsWith('revealed ')) {
  #|          // Check if element is in viewport and trigger revealed
  #|          const rect = element.getBoundingClientRect();
  #|          const isInViewport = (
  #|            rect.top >= 0 &&
  #|            rect.left >= 0 &&
  #|            rect.bottom <= (window.innerHeight || document.documentElement.clientHeight) &&
  #|            rect.right <= (window.innerWidth || document.documentElement.clientWidth)
  #|          );
  #|          if (isInViewport) {
  #|            const event = new MouseEvent('click', { bubbles: true, cancelable: true });
  #|            element.dispatchEvent(event);
  #|          }
  #|          break;
  #|        }
  #|      }
  #|    }
  #|    // Process all descendants with hx-trigger
  #|    const elements = element.querySelectorAll('[hx-trigger], [data-hx-trigger]');
  #|    for (const el of elements) {
  #|      const elTrigger = el.getAttribute('hx-trigger') || el.getAttribute('data-hx-trigger');
  #|      if (elTrigger) {
  #|        const elParts = elTrigger.split(',').map(s => s.trim());
  #|        for (const part of elParts) {
  #|          if (part === 'load' || part.startsWith('load ')) {
  #|            const event = new MouseEvent('click', { bubbles: true, cancelable: true });
  #|            el.dispatchEvent(event);
  #|            break;
  #|          } else if (part === 'revealed' || part.startsWith('revealed ')) {
  #|            // Check if element is in viewport and trigger revealed
  #|            const rect = el.getBoundingClientRect();
  #|            const isInViewport = (
  #|              rect.top >= 0 &&
  #|              rect.left >= 0 &&
  #|              rect.bottom <= (window.innerHeight || document.documentElement.clientHeight) &&
  #|              rect.right <= (window.innerWidth || document.documentElement.clientWidth)
  #|            );
  #|            if (isInViewport) {
  #|              const event = new MouseEvent('click', { bubbles: true, cancelable: true });
  #|              el.dispatchEvent(event);
  #|            }
  #|            break;
  #|          }
  #|        }
  #|      }
  #|    }
  #|  };
  #|}

///|
/// Process elements with hx-trigger='revealed'
extern "js" fn process_revealed_triggers() -> Unit =
  #|() => {
  #|  // Find all elements with revealed trigger
  #|  const revealedElements = document.querySelectorAll('[hx-trigger*="revealed"], [data-hx-trigger*="revealed"]');
  #|
  #|  // Function to check if element is in viewport
  #|  const isInViewport = function(el) {
  #|    const rect = el.getBoundingClientRect();
  #|    return (
  #|      rect.top >= 0 &&
  #|      rect.left >= 0 &&
  #|      rect.bottom <= (window.innerHeight || document.documentElement.clientHeight) &&
  #|      rect.right <= (window.innerWidth || document.documentElement.clientWidth)
  #|    );
  #|  };
  #|
  #|  // Function to trigger a revealed element
  #|  const triggerRevealed = function(el) {
  #|    // Mark as processed to avoid duplicate triggers
  #|    if (el.hasAttribute('data-revealed-triggered')) return;
  #|    el.setAttribute('data-revealed-triggered', 'true');
  #|
  #|    // Trigger click event which will process the htmx request
  #|    const event = new MouseEvent('click', { bubbles: true, cancelable: true });
  #|    el.dispatchEvent(event);
  #|  };
  #|
  #|  // Process elements that are already visible
  #|  for (const el of revealedElements) {
  #|    const trigger = el.getAttribute('hx-trigger') || el.getAttribute('data-hx-trigger');
  #|    if (trigger && trigger.includes('revealed')) {
  #|      // Check if element is currently in viewport
  #|      if (isInViewport(el)) {
  #|        triggerRevealed(el);
  #|      }
  #|    }
  #|  }
  #|
  #|  // Set up IntersectionObserver for elements not yet in viewport
  #|  const observer = new IntersectionObserver(function(entries) {
  #|    for (const entry of entries) {
  #|      if (entry.isIntersecting) {
  #|        const el = entry.target;
  #|        triggerRevealed(el);
  #|        observer.unobserve(el);
  #|      }
  #|    }
  #|  }, { threshold: 0 });
  #|
  #|  // Observe elements that aren't already triggered
  #|  for (const el of revealedElements) {
  #|    if (!el.hasAttribute('data-revealed-triggered')) {
  #|      observer.observe(el);
  #|    }
  #|  }
  #|}
