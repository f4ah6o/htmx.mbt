///|
/// Trigger modifier types for hx-trigger parsing
pub enum TriggerModifier {
  Once // trigger:once
  Changed // trigger:changed  
  Delay(Int) // delay:500ms
  Throttle(Int) // throttle:500ms
  From(String) // from:selector
  Target(String) // target:selector
  Consume // consume
  Queue(String) // queue:first/last/all/none
  Filter(String) // [ctrlKey] or [target.value != '']
}

///|
/// Parsed trigger definition
pub struct TriggerDef {
  event_name : String
  modifiers : Array[TriggerModifier]
}

///|
/// Create a new TriggerDef with default event
pub fn TriggerDef::new(event_name : String) -> TriggerDef {
  { event_name, modifiers: [] }
}

///|
/// Add a modifier to the trigger definition
pub fn TriggerDef::add_modifier(
  self : TriggerDef,
  modifier : TriggerModifier,
) -> TriggerDef {
  self.modifiers.push(modifier)
  self
}

///|
/// Check if trigger has "once" modifier
pub fn TriggerDef::has_once(self : TriggerDef) -> Bool {
  for m in self.modifiers {
    if m is Once {
      return true
    }
  }
  false
}

///|
/// Get delay in milliseconds (0 if no delay)
pub fn TriggerDef::get_delay_ms(self : TriggerDef) -> Int {
  for m in self.modifiers {
    if m is Delay(ms) {
      return ms
    }
  }
  0
}

///|
/// Get throttle in milliseconds (0 if no throttle)
pub fn TriggerDef::get_throttle_ms(self : TriggerDef) -> Int {
  for m in self.modifiers {
    if m is Throttle(ms) {
      return ms
    }
  }
  0
}

///|
/// Get "from" selector (None if not specified)
pub fn TriggerDef::get_from_selector(self : TriggerDef) -> String? {
  for m in self.modifiers {
    if m is From(selector) {
      return Some(selector)
    }
  }
  None
}

///|
/// Extract substring from string using indices (safe version)
fn substr(s : String, start : Int, end : Int) -> String {
  let chars = s.to_array()
  let len = chars.length()
  let real_start = if start < 0 { 0 } else { start }
  let real_end = if end > len { len } else { end }
  if real_start >= real_end {
    return ""
  }
  String::from_array(chars[real_start:real_end])
}

///|
/// Extract substring from start to end of string
fn substr_from(s : String, start : Int) -> String {
  let chars = s.to_array()
  let len = chars.length()
  if start >= len {
    return ""
  }
  String::from_array(chars[start:])
}

///|
/// Extract substring from beginning to index
fn substr_to(s : String, end : Int) -> String {
  let chars = s.to_array()
  if end <= 0 {
    return ""
  }
  let real_end = if end > chars.length() { chars.length() } else { end }
  String::from_array(chars[:real_end])
}

///|
/// Parse milliseconds from strings like "500ms" or "1s"
fn parse_duration_ms(value : String) -> Int {
  let len = value.length()
  if len == 0 {
    return 0
  }

  // Check for "ms" suffix
  if len > 2 && substr_from(value, len - 2) == "ms" {
    let num_str = substr_to(value, len - 2)
    return parse_int(num_str)
  }

  // Check for "s" suffix
  if len > 1 && substr_from(value, len - 1) == "s" {
    let num_str = substr_to(value, len - 1)
    return parse_int(num_str) * 1000
  }

  // Try parsing as raw number (assume ms)
  parse_int(value)
}

///|
/// Simple integer parser
fn parse_int(s : String) -> Int {
  let mut result = 0
  for c in s {
    if c >= '0' && c <= '9' {
      result = result * 10 + (c.to_int() - '0'.to_int())
    }
  }
  result
}

///|
/// Parse a single trigger specification
/// Examples: "click", "click delay:500ms", "click[ctrlKey] delay:500ms from:body"
pub fn parse_trigger(value : String) -> TriggerDef {
  let value = value.trim().to_string()
  if value.length() == 0 {
    return TriggerDef::new("click")
  }
  let mut event_name = ""
  let modifiers : Array[TriggerModifier] = []

  // Split by space for main tokenization
  let tokens = split_by_space(value)
  if tokens.length() == 0 {
    return TriggerDef::new("click")
  }

  // First token is the event name (possibly with filter)
  let first_token = tokens[0]

  // Check for filter in event name: "click[ctrlKey]"
  let bracket_idx = find_char(first_token, '[')
  if bracket_idx >= 0 {
    event_name = substr_to(first_token, bracket_idx)
    let end_bracket = find_char(first_token, ']')
    if end_bracket > bracket_idx {
      let filter_expr = substr(first_token, bracket_idx + 1, end_bracket)
      modifiers.push(Filter(filter_expr))
    }
  } else {
    event_name = first_token
  }

  // Process remaining tokens as modifiers
  for i = 1; i < tokens.length(); i = i + 1 {
    let token = tokens[i]

    // Check for colon-separated modifiers
    let colon_idx = find_char(token, ':')
    if colon_idx > 0 {
      let key = substr_to(token, colon_idx).to_lower()
      let val = substr_from(token, colon_idx + 1)
      match key {
        "delay" => modifiers.push(Delay(parse_duration_ms(val)))
        "throttle" => modifiers.push(Throttle(parse_duration_ms(val)))
        "from" => modifiers.push(From(val))
        "target" => modifiers.push(Target(val))
        "queue" => modifiers.push(Queue(val))
        _ => () // Unknown modifier, ignore
      }
    } else {
      // Simple modifiers without values
      match token.to_lower() {
        "once" => modifiers.push(Once)
        "changed" => modifiers.push(Changed)
        "consume" => modifiers.push(Consume)
        _ => () // Unknown modifier, ignore
      }
    }
  }
  { event_name, modifiers }
}

///|
/// Split string by spaces (simple tokenizer)
fn split_by_space(s : String) -> Array[String] {
  let result : Array[String] = []
  let current : Array[Char] = []
  for c in s {
    if c == ' ' || c == '\t' {
      if current.length() > 0 {
        result.push(String::from_array(current))
        current.clear()
      }
    } else {
      current.push(c)
    }
  }
  if current.length() > 0 {
    result.push(String::from_array(current))
  }
  result
}

///|
/// Find first occurrence of character in string, return -1 if not found
fn find_char(s : String, target : Char) -> Int {
  for i, c in s {
    if c == target {
      return i
    }
  }
  -1
}

///|
/// Parse multiple trigger specifications separated by commas
/// Example: "click, keyup[key=='Enter']"
pub fn parse_triggers(value : String) -> Array[TriggerDef] {
  let result : Array[TriggerDef] = []
  let current : Array[Char] = []
  let mut in_brackets = false
  for c in value {
    if c == '[' {
      in_brackets = true
      current.push(c)
    } else if c == ']' {
      in_brackets = false
      current.push(c)
    } else if c == ',' && not(in_brackets) {
      if current.length() > 0 {
        result.push(parse_trigger(String::from_array(current)))
        current.clear()
      }
    } else {
      current.push(c)
    }
  }
  if current.length() > 0 {
    result.push(parse_trigger(String::from_array(current)))
  }
  result
}
