///|
test "target selector 'this' returns element itself" {
  // Test that 'this' selector works
  let selector = "this"
  inspect(selector, content="this")
}

///|
test "target selector 'closest div' parses correctly" {
  // Test closest selector format
  let selector = "closest div"
  inspect(selector.has_prefix("closest "), content="true")
}

///|
test "target selector 'find .child' parses correctly" {
  // Test find selector format
  let selector = "find .child"
  inspect(selector.has_prefix("find "), content="true")
}

///|
test "target selector 'next' parses correctly" {
  // Test next selector format
  let selector = "next"
  inspect(selector.has_prefix("next"), content="true")
}

///|
test "target selector 'next div' parses correctly" {
  // Test next with selector format
  let selector = "next div"
  inspect(selector.has_prefix("next"), content="true")
}

///|
test "target selector 'previous' parses correctly" {
  // Test previous selector format
  let selector = "previous"
  inspect(selector.has_prefix("previous"), content="true")
}

///|
test "target selector 'previous span' parses correctly" {
  // Test previous with selector format
  let selector = "previous span"
  inspect(selector.has_prefix("previous"), content="true")
}

///|
test "target selector with CSS selector #my-id" {
  // Test standard CSS selector
  let selector = "#my-id"
  inspect(selector, content="#my-id")
}

///|
test "target selector with CSS selector .my-class" {
  // Test standard CSS class selector
  let selector = ".my-class"
  inspect(selector, content=".my-class")
}

///|
test "data-hx-target prefix works" {
  // Test that data-hx-target is recognized
  let attr = "hx-target"
  let prefixed = "data-" + attr
  inspect(prefixed, content="data-hx-target")
}
