///|
/// MutationObserver integration for htmx
/// Watches DOM for newly added elements with hx-* attributes

///|
/// Process mutation records to find newly added htmx elements
fn process_mutations(
  records : @core.Any?,
  _observer : @observer.MutationObserver,
) -> Unit {
  guard records is Some(records_val) else { return }

  // Records is an array of MutationRecord
  let records_array = @core.array_from(records_val)
  for record_any in records_array {
    // Cast to MutationRecord to access addedNodes
    let record : @observer.MutationRecord = @core.identity(record_any)

    // Process each added node
    for node in record.addedNodes {
      // Check if node is an element (has tagName)
      process_new_node(node)
    }
  }
}

///|
/// Process a newly added node
fn process_new_node(node : @dom.Node) -> Unit {
  // Try to cast to element - only process elements
  let node_type = node.nodeType()
  if node_type != 1 {
    // Not an element node
    return
  }

  // Cast to element
  let element = @dom.Element::cast_from_node(node)

  // Check for htmx attributes
  let methods = get_hx_methods()
  for method_attr in methods {
    if element.hasAttribute(method_attr) {
      // Found htmx element - will be handled by event delegation
      return
    }
  }

  // Also check for htmx elements in children
  let htmx_children = element.querySelectorAll(
    "[hx-get], [hx-post], [hx-put], [hx-delete], [hx-patch]",
  )
  let _ = htmx_children
  // These will also be handled by event delegation
}

///|
/// Create MutationObserver options as @core.Any
fn create_observer_options() -> @core.Any {
  @core.from_entries([
    ("childList", @core.any(true)),
    ("subtree", @core.any(true)),
    ("attributes", @core.any(false)),
  ])
}

///|
/// Create and return a MutationObserver for htmx
pub fn create_htmx_observer() -> @observer.MutationObserver {
  @observer.MutationObserver::new(process_mutations)
}

///|
/// Start observing the document body for new htmx elements
pub fn start_htmx_observer(
  mutation_observer : @observer.MutationObserver,
) -> Unit {
  match @dom.document().body() {
    Some(body) => {
      let options = create_observer_options()
      mutation_observer.observe(body.as_element(), options)
    }
    None => @core.log(@core.any("Warning: document.body not available"))
  }
}

///|
/// Initialize htmx with MutationObserver support
pub fn init_with_observer() -> @observer.MutationObserver {
  let mutation_observer = create_htmx_observer()
  start_htmx_observer(mutation_observer)
  mutation_observer
}
