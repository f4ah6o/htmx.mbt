///|
test "parse_trigger basic" {
  let t = parse_trigger("click")
  inspect(t.event_name, content="click")
  inspect(t.modifiers.length(), content="0")
}

///|
test "parse_trigger with delay" {
  let t = parse_trigger("click delay:500ms")
  inspect(t.event_name, content="click")
  inspect(t.get_delay_ms(), content="500")
}

///|
test "parse_trigger with delay seconds" {
  let t = parse_trigger("click delay:2s")
  inspect(t.get_delay_ms(), content="2000")
}

///|
test "parse_trigger with from" {
  let t = parse_trigger("click from:body")
  inspect(t.event_name, content="click")
  inspect(t.get_from_selector(), content="Some(\"body\")")
}

///|
test "parse_trigger with filter" {
  let t = parse_trigger("click[ctrlKey]")
  inspect(t.event_name, content="click")
  inspect(t.modifiers.length(), content="1")
}

///|
test "parse_trigger complex" {
  let t = parse_trigger("keyup[key=='Enter'] delay:100ms from:body once")
  inspect(t.event_name, content="keyup")
  inspect(t.get_delay_ms(), content="100")
  inspect(t.get_from_selector(), content="Some(\"body\")")
  inspect(t.has_once(), content="true")
}

///|
test "parse_triggers multiple" {
  let triggers = parse_triggers("click, mouseover delay:500ms")
  inspect(triggers.length(), content="2")
  inspect(triggers[0].event_name, content="click")
  inspect(triggers[1].event_name, content="mouseover")
}
