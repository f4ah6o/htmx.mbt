///|
test "SwapStyle parse innerHTML" {
  match SwapStyle::parse("innerHTML") {
    InnerHTML => inspect("ok", content="ok")
    _ => inspect("error", content="Expected InnerHTML")
  }
}

///|
test "SwapStyle parse outerHTML" {
  match SwapStyle::parse("outerHTML") {
    OuterHTML => inspect("ok", content="ok")
    _ => inspect("error", content="Expected OuterHTML")
  }
}

///|
test "SwapStyle parse beforebegin" {
  match SwapStyle::parse("beforebegin") {
    BeforeBegin => inspect("ok", content="ok")
    _ => inspect("error", content="Expected BeforeBegin")
  }
}

///|
test "SwapStyle parse afterbegin" {
  match SwapStyle::parse("afterbegin") {
    AfterBegin => inspect("ok", content="ok")
    _ => inspect("error", content="Expected AfterBegin")
  }
}

///|
test "SwapStyle parse beforeend" {
  match SwapStyle::parse("beforeend") {
    BeforeEnd => inspect("ok", content="ok")
    _ => inspect("error", content="Expected BeforeEnd")
  }
}

///|
test "SwapStyle parse afterend" {
  match SwapStyle::parse("afterend") {
    AfterEnd => inspect("ok", content="ok")
    _ => inspect("error", content="Expected AfterEnd")
  }
}

///|
test "SwapStyle parse delete" {
  match SwapStyle::parse("delete") {
    Delete => inspect("ok", content="ok")
    _ => inspect("error", content="Expected Delete")
  }
}

///|
test "SwapStyle parse none" {
  match SwapStyle::parse("none") {
    None => inspect("ok", content="ok")
    _ => inspect("error", content="Expected None")
  }
}

///|
test "SwapStyle parse morph" {
  match SwapStyle::parse("morph") {
    Morph => inspect("ok", content="ok")
    _ => inspect("error", content="Expected Morph")
  }
}

///|
test "SwapStyle parse invalid defaults to innerHTML" {
  match SwapStyle::parse("invalid") {
    InnerHTML => inspect("ok", content="ok")
    _ => inspect("error", content="Expected InnerHTML as default")
  }
}

///|
test "SwapSpec default has correct values" {
  let spec = SwapSpec::parse("")
  match spec.style {
    InnerHTML => inspect("ok", content="ok")
    _ => inspect("error", content="Expected InnerHTML as default")
  }
}

///|
test "SwapSpec parse with style" {
  let spec = SwapSpec::parse("outerHTML")
  match spec.style {
    OuterHTML => inspect("ok", content="ok")
    _ => inspect("error", content="Expected OuterHTML")
  }
}

///|
test "SwapSpec parse with swap delay" {
  let spec = SwapSpec::parse("innerHTML swap:100ms")
  inspect(spec.swap_delay_ms, content="100")
}

///|
test "SwapSpec parse with settle delay" {
  let spec = SwapSpec::parse("innerHTML settle:200ms")
  inspect(spec.settle_delay_ms, content="200")
}

///|
test "ScrollSpec creates correctly" {
  let spec = SwapSpec::parse("innerHTML scroll:top")
  match spec.scroll {
    Some(scroll) =>
      match scroll.direction {
        Top => inspect("ok", content="ok")
        Bottom => inspect("error", content="Expected Top")
      }
    Option::None => inspect("error", content="Expected Some scroll")
  }
}

///|
test "ShowSpec creates correctly" {
  let spec = SwapSpec::parse("innerHTML show:bottom")
  match spec.show {
    Some(show) =>
      match show.direction {
        Bottom => inspect("ok", content="ok")
        Top => inspect("error", content="Expected Bottom")
      }
    Option::None => inspect("error", content="Expected Some show")
  }
}

///|
test "data-hx-swap prefix is recognized" {
  let attr = "hx-swap"
  let prefixed = "data-" + attr
  inspect(prefixed, content="data-hx-swap")
}
