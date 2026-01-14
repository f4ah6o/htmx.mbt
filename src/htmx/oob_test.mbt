///|
/// Tests for Out-Of-Band swap support

///|
test "parse_oob_spec 'true' defaults to outerHTML" {
  let spec = parse_oob_spec("true")
  match spec.style {
    OuterHTML => inspect("ok", content="ok")
    _ => inspect("error", content="Expected OuterHTML")
  }
  inspect(spec.target, content="None")
}

///|
test "parse_oob_spec 'innerHTML'" {
  let spec = parse_oob_spec("innerHTML")
  match spec.style {
    InnerHTML => inspect("ok", content="ok")
    _ => inspect("error", content="Expected InnerHTML")
  }
  inspect(spec.target, content="None")
}

///|
test "parse_oob_spec 'outerHTML'" {
  let spec = parse_oob_spec("outerHTML")
  match spec.style {
    OuterHTML => inspect("ok", content="ok")
    _ => inspect("error", content="Expected OuterHTML")
  }
  inspect(spec.target, content="None")
}

///|
test "parse_oob_spec 'beforebegin'" {
  let spec = parse_oob_spec("beforebegin")
  match spec.style {
    BeforeBegin => inspect("ok", content="ok")
    _ => inspect("error", content="Expected BeforeBegin")
  }
  inspect(spec.target, content="None")
}

///|
test "parse_oob_spec 'afterbegin'" {
  let spec = parse_oob_spec("afterbegin")
  match spec.style {
    AfterBegin => inspect("ok", content="ok")
    _ => inspect("error", content="Expected AfterBegin")
  }
  inspect(spec.target, content="None")
}

///|
test "parse_oob_spec 'beforeend'" {
  let spec = parse_oob_spec("beforeend")
  match spec.style {
    BeforeEnd => inspect("ok", content="ok")
    _ => inspect("error", content="Expected BeforeEnd")
  }
  inspect(spec.target, content="None")
}

///|
test "parse_oob_spec 'afterend'" {
  let spec = parse_oob_spec("afterend")
  match spec.style {
    AfterEnd => inspect("ok", content="ok")
    _ => inspect("error", content="Expected AfterEnd")
  }
  inspect(spec.target, content="None")
}

///|
test "parse_oob_spec 'delete'" {
  let spec = parse_oob_spec("delete")
  match spec.style {
    Delete => inspect("ok", content="ok")
    _ => inspect("error", content="Expected Delete")
  }
  inspect(spec.target, content="None")
}

///|
test "parse_oob_spec 'none'" {
  let spec = parse_oob_spec("none")
  match spec.style {
    None => inspect("ok", content="ok")
    _ => inspect("error", content="Expected None")
  }
  inspect(spec.target, content="None")
}

///|
test "parse_oob_spec 'morph'" {
  let spec = parse_oob_spec("morph")
  match spec.style {
    Morph => inspect("ok", content="ok")
    _ => inspect("error", content="Expected Morph")
  }
  inspect(spec.target, content="None")
}

///|
test "parse_oob_spec 'innerHTML:#target'" {
  let spec = parse_oob_spec("innerHTML:#target")
  match spec.style {
    InnerHTML => inspect("ok", content="ok")
    _ => inspect("error", content="Expected InnerHTML")
  }
  inspect(spec.target, content="Some(\"#target\")")
}

///|
test "parse_oob_spec 'beforeend:.class-selector'" {
  let spec = parse_oob_spec("beforeend:.class-selector")
  match spec.style {
    BeforeEnd => inspect("ok", content="ok")
    _ => inspect("error", content="Expected BeforeEnd")
  }
  inspect(spec.target, content="Some(\".class-selector\")")
}

///|
test "parse_oob_spec 'outerHTML:#my-id'" {
  let spec = parse_oob_spec("outerHTML:#my-id")
  match spec.style {
    OuterHTML => inspect("ok", content="ok")
    _ => inspect("error", content="Expected OuterHTML")
  }
  inspect(spec.target, content="Some(\"#my-id\")")
}

///|
test "parse_oob_spec 'delete:[data-temp]'" {
  let spec = parse_oob_spec("delete:[data-temp]")
  match spec.style {
    Delete => inspect("ok", content="ok")
    _ => inspect("error", content="Expected Delete")
  }
  inspect(spec.target, content="Some(\"[data-temp]\")")
}

///|
test "parse_oob_spec unknown defaults to innerHTML" {
  let spec = parse_oob_spec("unknown-style")
  // SwapStyle::parse defaults to InnerHTML for unknown values
  match spec.style {
    InnerHTML => inspect("ok", content="ok")
    _ => inspect("error", content="Expected InnerHTML as default")
  }
  inspect(spec.target, content="None")
}

///|
test "parse_oob_spec with whitespace" {
  let spec = parse_oob_spec("  innerHTML  ")
  match spec.style {
    InnerHTML => inspect("ok", content="ok")
    _ => inspect("error", content="Expected InnerHTML")
  }
  inspect(spec.target, content="None")
}

///|
test "parse_oob_spec 'afterend:div.container'" {
  let spec = parse_oob_spec("afterend:div.container")
  match spec.style {
    AfterEnd => inspect("ok", content="ok")
    _ => inspect("error", content="Expected AfterEnd")
  }
  inspect(spec.target, content="Some(\"div.container\")")
}

///|
test "parse_oob_spec complex selector" {
  let spec = parse_oob_spec("innerHTML:[data-role='content']")
  match spec.style {
    InnerHTML => inspect("ok", content="ok")
    _ => inspect("error", content="Expected InnerHTML")
  }
  inspect(spec.target, content="Some(\"[data-role='content']\")")
}

///|
test "parse_oob_spec morph with target" {
  let spec = parse_oob_spec("morph:#target")
  match spec.style {
    Morph => inspect("ok", content="ok")
    _ => inspect("error", content="Expected Morph")
  }
  inspect(spec.target, content="Some(\"#target\")")
}
