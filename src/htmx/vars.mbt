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
  #|    console.log('[htmx.mbt VARS] evaluateAttribute: str=', str, 'event=', event);
  #|    try {
  #|      let result;
  #|      if (event) {
  #|        const evt = (event && event.$tag === 1) ? event._0 : event;
  #|        result = new Function('event', 'return (' + str + ')').call(elt, evt);
  #|      } else {
  #|        result = new Function('return (' + str + ')').call(elt);
  #|      }
  #|      console.log('[htmx.mbt VARS] evaluateAttribute result:', result);
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
  #|    console.log('[htmx.mbt VARS] process element:', elt, 'attr:', attr, 'attributeValue:', attributeValue);
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
  #|      console.log('[htmx.mbt VARS] element:', elt, 'attr:', attr, 'str:', str, 'evaluateValue:', evaluateValue);
  #|      if (evaluateValue && !allowEval) {
  #|        // Trigger evalDisallowedError event
  #|        const errorEvt = new CustomEvent('htmx:evalDisallowedError', {
  #|          bubbles: true,
  #|          cancelable: true,
  #|          detail: { source: attr }
  #|        });
  #|        elt.dispatchEvent(errorEvt);
  #|        return values;
  #|      }
  #|
  #|      let varsValues;
  #|      if (evaluateValue) {
  #|        varsValues = evaluateAttribute(elt, str, event);
  #|      } else {
  #|        varsValues = parseAttribute(elt, str);
  #|      }
  #|      console.log('[htmx.mbt VARS] varsValues:', varsValues);
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
  #|  console.log('[htmx.mbt VARS] result:', JSON.stringify(result));
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
