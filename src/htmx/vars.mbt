///|
/// Variable processing for hx-vars and hx-vals attributes

///|
/// Get all expression vars (hx-vars + hx-vals combined) from an element
/// Returns a Map that can be converted to @core.Any for FFI
pub fn get_expression_vars(
  elt : @dom.Element?,
  event : @core.Any?,
) -> Map[String, String] {
  get_expression_vars_inner(elt, event)
}

///|
/// Convert Map[String, String] to @core.Any for FFI
extern "js" fn map_to_any(m : Map[String, String]) -> @core.Any =
  #|(m) => {
  #|  // MoonBit Map has { buf: [{_0: key, _1: value}, ...], start, end } structure
  #|  return m;  // Return the Map directly, it's already in JS format
  #|}

///|
/// Internal function to get expression vars via FFI
extern "js" fn get_expression_vars_inner(
  elt : @dom.Element?,
  event : @core.Any?,
) -> Map[String, String] =
  #|(elt, event) => {
  #|  // Unwrap MoonBit Option type for elt
  #|  const element = (elt && elt.$tag === 1) ? elt._0 : null;
  #|
  #|  // Check for delay-stored event (used when delay modifier is active)
  #|  let actualEvent = event;
  #|  if (element && element['htmx-internal-data']) {
  #|    const data = element['htmx-internal-data'];
  #|    // Prioritize currentEvent (set during delay callback) over delayEvent
  #|    if (data.currentEvent) {
  #|      actualEvent = data.currentEvent;
  #|    } else if (data.delayEvent) {
  #|      actualEvent = data.delayEvent;
  #|    }
  #|  }
  #|  // Helper to get attribute value (checks both hx-* and data-hx-*)
  #|  const getAttributeValue = (el, attr) => {
  #|    if (!el) return null;
  #|    return el.getAttribute(attr) || el.getAttribute('data-' + attr);
  #|  };
  #|
  #|  // Check if allowEval is enabled
  #|  const allowEval = window.htmx && window.htmx.config && window.htmx.config.allowEval !== false;
  #|
  #|  // Evaluate attribute value as JavaScript object literal
  #|  const evaluateAttribute = (elt, str, event) => {
  #|    // Wrap in braces if not already present
  #|    if (str.indexOf('{') !== 0) {
  #|      str = '{' + str + '}';
  #|    }
  #|
  #|    try {
  #|      let result;
  #|      if (event) {
  #|        const evt = (event && event.$tag === 1) ? event._0 : event;
  #|        result = new Function('event', 'return (' + str + ')').call(elt, evt);
  #|      } else {
  #|        result = new Function('return (' + str + ')').call(elt);
  #|      }
  #|      return result;
  #|    } catch (e) {
  #|      console.error('htmx.mbt: Error evaluating vars:', e, 'str:', str);
  #|      return {};
  #|    }
  #|  };
  #|
  #|  // Parse attribute value as JSON
  #|  const parseAttribute = (elt, str) => {
  #|    // Wrap in braces if not already present
  #|    if (str.indexOf('{') !== 0) {
  #|      str = '{' + str + '}';
  #|    }
  #|
  #|    try {
  #|      return JSON.parse(str);
  #|    } catch (e) {
  #|      console.error('htmx.mbt: Error parsing vars JSON:', e);
  #|      return {};
  #|    }
  #|  };
  #|
  #|  // Use actualEvent (which may be the stored delay event) for evaluation
  #|  const eventForEval = actualEvent;
  #|  // Collect values from hx-vars or hx-vals attribute on element and its parents
  #|  const getValuesForElement = (elt, attr, evalAsDefault, values) => {
  #|    if (values == null) {
  #|      values = {};
  #|    }
  #|    if (elt == null) {
  #|      return values;
  #|    }
  #|
  #|    // First, collect from parent (so parent values come first)
  #|    const parent = elt.parentElement;
  #|    if (parent) {
  #|      getValuesForElement(parent, attr, evalAsDefault, values);
  #|    }
  #|
  #|    // Then, process current element (child values override parent values)
  #|    const attributeValue = getAttributeValue(elt, attr);
  #|    if (attributeValue) {
  #|      let str = attributeValue.trim();
  #|      let evaluateValue = evalAsDefault;
  #|
  #|      // Check for 'unset' keyword
  #|      if (str === 'unset') {
  #|        // Clear all values - 'unset' removes all inherited vars
  #|        for (const key in values) {
  #|          if (values.hasOwnProperty(key)) {
  #|            delete values[key];
  #|          }
  #|        }
  #|        return values;
  #|      }
  #|
  #|      // Check for javascript: or js: prefix (forces evaluation)
  #|      if (str.indexOf('javascript:') === 0) {
  #|        str = str.slice(11);
  #|        evaluateValue = true;
  #|      } else if (str.indexOf('js:') === 0) {
  #|        str = str.slice(3);
  #|        evaluateValue = true;
  #|      }
  #|
  #|      // Check if evaluation is allowed
  #|      if (evaluateValue && !allowEval) {
  #|        // Trigger evalDisallowedError event (both camelCase and kebab-case)
  #|        const detail = { source: attr };
  #|        const evt1 = new CustomEvent('htmx:evalDisallowedError', {
  #|          bubbles: true,
  #|          cancelable: true,
  #|          detail: detail
  #|        });
  #|        elt.dispatchEvent(evt1);
  #|        const evt2 = new CustomEvent('htmx:evalDisallowedError', {
  #|          bubbles: true,
  #|          cancelable: true,
  #|          detail: detail
  #|        });
  #|        elt.dispatchEvent(evt2);
  #|        return values;
  #|      }
  #|
  #|      let varsValues;
  #|      if (evaluateValue) {
  #|        varsValues = evaluateAttribute(elt, str, eventForEval);
  #|      } else {
  #|        varsValues = parseAttribute(elt, str);
  #|      }
  #|
  #|      // Child values override parent values
  #|      if (varsValues) {
  #|        for (const key in varsValues) {
  #|          if (varsValues.hasOwnProperty(key)) {
  #|            values[key] = varsValues[key];
  #|          }
  #|        }
  #|      }
  #|    }
  #|    return values;
  #|  };
  #|
  #|  // Get both hx-vars and hx-vals
  #|  let vars = {};
  #|  let vals = {};
  #|
  #|  if (element) {
  #|    vars = getValuesForElement(element, 'hx-vars', true, {}) || {};
  #|    vals = getValuesForElement(element, 'hx-vals', false, {}) || {};
  #|  }
  #|
  #|  // Merge vars and vals, with vals taking precedence
  #|  const result = { ...vars, ...vals };
  #|
  #|  // Convert to MoonBit Map format
  #|  const entries = Object.entries(result);
  #|  const buf = [];
  #|  for (const [k, v] of entries) {
  #|    let strValue;
  #|    // Convert objects to JSON string, other values to string
  #|    // null becomes 'null' string for compatibility
  #|    if (v === null) {
  #|      strValue = 'null';
  #|    } else if (typeof v === 'object') {
  #|      strValue = JSON.stringify(v);
  #|    } else {
  #|      strValue = String(v);
  #|    }
  #|    buf.push({ _0: k, _1: strValue });
  #|  }
  #|  return { buf: buf, start: 0, end: buf.length };
  #|}

///|
/// Get all custom headers from hx-headers attribute
/// Returns a Map that can be converted to @core.Any for FFI
pub fn get_headers_from_element(elt : @dom.Element?) -> Map[String, String] {
  get_headers_from_element_inner(elt)
}

///|
/// Internal function to get headers via FFI
extern "js" fn get_headers_from_element_inner(
  elt : @dom.Element?,
) -> Map[String, String] =
  #|(elt) => {
  #|  // Unwrap MoonBit Option type for elt
  #|  const element = (elt && elt.$tag === 1) ? elt._0 : null;
  #|  // Helper to get attribute value (checks both hx-* and data-hx-*)
  #|  const getAttributeValue = (el, attr) => {
  #|    if (!el) return null;
  #|    return el.getAttribute(attr) || el.getAttribute('data-' + attr);
  #|  };
  #|  // Check if allowEval is enabled
  #|  const allowEval = window.htmx && window.htmx.config && window.htmx.config.allowEval !== false;
  #|  // Evaluate attribute value as JavaScript object literal
  #|  const evaluateAttribute = (elt, str) => {
  #|    // Wrap in braces if not already present
  #|    if (str.indexOf('{') !== 0) {
  #|      str = '{' + str + '}';
  #|    }
  #|    try {
  #|      return new Function('return (' + str + ')').call(elt);
  #|    } catch (e) {
  #|      console.error('htmx.mbt: Error evaluating headers:', e, 'str:', str);
  #|      return {};
  #|    }
  #|  };
  #|  // Parse attribute value as JSON
  #|  const parseAttribute = (elt, str) => {
  #|    // Wrap in braces if not already present
  #|    if (str.indexOf('{') !== 0) {
  #|      str = '{' + str + '}';
  #|    }
  #|    try {
  #|      return JSON.parse(str);
  #|    } catch (e) {
  #|      console.error('htmx.mbt: Error parsing headers JSON:', e);
  #|      return {};
  #|    }
  #|  };
  #|  // Collect headers from hx-headers attribute on element and its parents
  #|  const getHeadersForElement = (elt, headers) => {
  #|    if (headers == null) {
  #|      headers = {};
  #|    }
  #|    if (elt == null) {
  #|      return headers;
  #|    }
  #|    // First, collect from parent (so parent values come first)
  #|    const parent = elt.parentElement;
  #|    if (parent) {
  #|      getHeadersForElement(parent, headers);
  #|    }
  #|    // Then, process current element (child values override parent values)
  #|    const attributeValue = getAttributeValue(elt, 'hx-headers');
  #|    if (attributeValue) {
  #|      let str = attributeValue.trim();
  #|      let evaluateValue = false;
  #|      // Check for 'unset' keyword
  #|      if (str === 'unset') {
  #|        // Clear all headers - 'unset' removes all inherited headers
  #|        for (const key in headers) {
  #|          if (headers.hasOwnProperty(key)) {
  #|            delete headers[key];
  #|          }
  #|        }
  #|        return headers;
  #|      }
  #|      // Check for javascript: or js: prefix (forces evaluation)
  #|      if (str.indexOf('javascript:') === 0) {
  #|        str = str.slice(11);
  #|        evaluateValue = true;
  #|      } else if (str.indexOf('js:') === 0) {
  #|        str = str.slice(3);
  #|        evaluateValue = true;
  #|      }
  #|      // Check if evaluation is allowed
  #|      if (evaluateValue && !allowEval) {
  #|        // Trigger evalDisallowedError event (both camelCase and kebab-case)
  #|        const detail = { source: 'hx-headers' };
  #|        const evt1 = new CustomEvent('htmx:evalDisallowedError', {
  #|          bubbles: true,
  #|          cancelable: true,
  #|          detail: detail
  #|        });
  #|        elt.dispatchEvent(evt1);
  #|        const evt2 = new CustomEvent('htmx:evalDisallowedError', {
  #|          bubbles: true,
  #|          cancelable: true,
  #|          detail: detail
  #|        });
  #|        elt.dispatchEvent(evt2);
  #|        return headers;
  #|      }
  #|      let headersValues;
  #|      if (evaluateValue) {
  #|        headersValues = evaluateAttribute(elt, str);
  #|      } else {
  #|        headersValues = parseAttribute(elt, str);
  #|      }
  #|      // Child values override parent values
  #|      if (headersValues) {
  #|        for (const key in headersValues) {
  #|          if (headersValues.hasOwnProperty(key)) {
  #|            headers[key] = headersValues[key];
  #|          }
  #|        }
  #|      }
  #|    }
  #|    return headers;
  #|  };
  #|  let headers = {};
  #|  if (element) {
  #|    headers = getHeadersForElement(element, {}) || {};
  #|  }
  #|  // Convert to MoonBit Map format
  #|  const entries = Object.entries(headers);
  #|  const buf = [];
  #|  for (const [k, v] of entries) {
  #|    let strValue;
  #|    // Convert values to string
  #|    if (v === null) {
  #|      strValue = 'null';
  #|    } else if (typeof v === 'object') {
  #|      strValue = JSON.stringify(v);
  #|    } else {
  #|      strValue = String(v);
  #|    }
  #|    buf.push({ _0: k, _1: strValue });
  #|  }
  #|  return { buf: buf, start: 0, end: buf.length };
  #|}

///|
/// Get params filter from hx-params attribute
/// Returns a filter specification: { mode: "none" | "all" | "include" | "exclude", names: string[] }
pub fn get_params_filter(elt : @dom.Element?) -> @core.Any {
  get_params_filter_inner(elt)
}

///|
/// Internal function to get params filter via FFI
extern "js" fn get_params_filter_inner(elt : @dom.Element?) -> @core.Any =
  #|(elt) => {
  #|  // Unwrap MoonBit Option type for elt
  #|  const element = (elt && elt.$tag === 1) ? elt._0 : null;
  #|
  #|  // Helper to get attribute value (checks both hx-* and data-hx-*)
  #|  const getAttributeValue = (el, attr) => {
  #|    if (!el) return null;
  #|    return el.getAttribute(attr) || el.getAttribute('data-' + attr);
  #| };
  #|
  #|  // Get params filter from element (does not inherit like hx-headers)
  #|  if (!element) {
  #|    return { mode: 'all', names: [] };
  #|  }
  #|
  #|  const paramsValue = getAttributeValue(element, 'hx-params');
  #|  if (!paramsValue) {
  #|    return { mode: 'all', names: [] };
  #|  }
  #|
  #|  const trimmed = paramsValue.trim();
  #|
  #|  // Handle 'none' - exclude all parameters
  #|  if (trimmed === 'none') {
  #|    return { mode: 'none', names: [] };
  #|  }
  #|
  #|  // Handle '*' - include all parameters (default)
  #|  if (trimmed === '*') {
  #|    return { mode: 'all', names: [] };
  #|  }
  #|
  #|  // Handle 'not' prefix for exclude mode
  #|  if (trimmed.startsWith('not ')) {
  #|    const namesStr = trimmed.slice(4).trim();
  #|    const names = namesStr ? namesStr.split(',').map(s => s.trim()).filter(s => s.length > 0) : [];
  #|    return { mode: 'exclude', names: names };
  #|  }
  #|
  #|  // Handle comma-separated list for include mode
  #|  const names = trimmed ? trimmed.split(',').map(s => s.trim()).filter(s => s.length > 0) : [];
  #|  return { mode: 'include', names: names };
  #|}
