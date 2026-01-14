///|
/// DOM Morphing implementation (Basic explicit diffing)

///|
/// Morph the target element to match the content string
/// Preserves element identity and state where possible
pub fn morph(target : @dom.Element, content : String) -> Unit {
  let doc = @dom.document()
  let temp = doc.createElement("div")
  temp.setInnerHTML(content)

  // If content is single element, try to morph
  let children = temp.children()
  if children.length() == 1 {
    let new_el = children[0]
    morph_element(target, new_el)
  } else {
    // If multiple elements or text, just replace innerHTML
    // For a robust implementation, we'd need to handle multiple root nodes
    target.setInnerHTML(content)
  }
}

///|
/// Recursively morph old element to match new element
pub fn morph_element(old_el : @dom.Element, new_el : @dom.Element) -> Unit {
  // If tags are different, strict replacement
  if old_el.tagName() != new_el.tagName() {
    let new_node = new_el.as_node()
    old_el.replaceWith([new_node])
    return
  }

  // 1. Sync attributes
  let new_attrs = new_el.getAttributeNames()
  for name in new_attrs {
    match new_el.getAttribute(name) {
      Some(val) => old_el.setAttribute(name, val)
      None => ()
    }
  }
  let old_attrs = old_el.getAttributeNames()
  for name in old_attrs {
    if not(new_el.hasAttribute(name)) {
      old_el.removeAttribute(name)
    }
  }

  // 2. Sync children
  let old_children = old_el.children()
  let new_children = new_el.children()

  // Simple heuristic: if child count matches, recurse. Otherwise, replace content.
  // Proper keyed diffing is complex; this covers simple updates well.
  if old_children.length() != new_children.length() {
    let new_html = get_innerHTML(new_el)
    old_el.setInnerHTML(new_html)
    return
  }

  // Recurse for each child
  for i = 0; i < old_children.length(); i = i + 1 {
    morph_element(old_children[i], new_children[i])
  }

  // 3. Sync text content if leaf node
  if old_children.length() == 0 {
    let old_html = get_innerHTML(old_el)
    let new_html = get_innerHTML(new_el)
    if old_html != new_html {
      old_el.setInnerHTML(new_html)
    }
  }
}

///|
/// Helper to get innerHTML
extern "js" fn get_innerHTML(element : @dom.Element) -> String =
  #|(el) => el.innerHTML
