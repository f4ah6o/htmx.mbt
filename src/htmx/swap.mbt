///|
/// Swap styles for DOM updates
pub enum SwapStyle {
  InnerHTML
  OuterHTML
  BeforeBegin
  AfterBegin
  BeforeEnd
  AfterEnd
  Delete
  None
}

///|
/// Parse swap style from string
pub fn SwapStyle::parse(value : String) -> SwapStyle {
  match value {
    "innerHTML" => InnerHTML
    "outerHTML" => OuterHTML
    "beforebegin" => BeforeBegin
    "afterbegin" => AfterBegin
    "beforeend" => BeforeEnd
    "afterend" => AfterEnd
    "delete" => Delete
    "none" => None
    _ => InnerHTML // default
  }
}

///|
/// Get position string for insertAdjacentHTML
fn SwapStyle::to_position(self : SwapStyle) -> String? {
  match self {
    BeforeBegin => Some("beforebegin")
    AfterBegin => Some("afterbegin")
    BeforeEnd => Some("beforeend")
    AfterEnd => Some("afterend")
    _ => Option::None
  }
}

///|
/// Perform DOM swap operation
pub fn swap(target : @dom.Element, content : String, style : SwapStyle) -> Unit {
  match style {
    InnerHTML => target.setInnerHTML(content)
    OuterHTML => target.setOuterHTML(content)
    BeforeBegin => target.insertAdjacentHTML("beforebegin", content)
    AfterBegin => target.insertAdjacentHTML("afterbegin", content)
    BeforeEnd => target.insertAdjacentHTML("beforeend", content)
    AfterEnd => target.insertAdjacentHTML("afterend", content)
    Delete => target.remove()
    None => () // do nothing
  }
}
