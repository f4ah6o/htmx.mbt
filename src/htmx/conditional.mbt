///|
/// Conditional expression generator for htmx filter expressions

///|
/// Generate a conditional function from tokens
/// This function takes an array of tokens and generates a JavaScript
/// conditional expression function. Used for parsing filter expressions
/// like [code==4||(code==5&&foo==true)] in htmx attributes.
///
/// Parameters:
/// - elt: The element (can be null, not used in current implementation)
/// - tokens: Array of tokens from tokenize_string
/// - param_name: Parameter name for the generated function (default "event")
///
/// Returns:
/// - A function that evaluates the conditional expression, or null if parsing fails
pub fn maybe_generate_conditional(
  elt : @core.Any,
  tokens : @core.Any,
  param_name : String,
) -> @core.Any {
  maybe_generate_conditional_js(elt, tokens, param_name)
}

///|
/// JavaScript implementation of maybe_generate_conditional
/// Ported from htmx.org to maintain compatibility
extern "js" fn maybe_generate_conditional_js(
  elt : @core.Any,
  tokens : @core.Any,
  param_name : String,
) -> @core.Any =
  #|(elt, tokens, paramName) => {
  #|  if (!tokens || tokens.length === 0) {
  #|    return null;
  #|  }
  #|
  #|  if (tokens[0] !== '[') {
  #|    return null;
  #|  }
  #|
  #|  tokens.shift(); // Remove opening '['
  #|  let bracketCount = 1;
  #|  let conditionalSource = ' return (function(' + paramName + '){ return (';
  #|  let last = null;
  #|  const SYMBOL_START = /[_$a-zA-Z]/;
  #|
  #|  const isPossibleRelativeReference = (token, last, paramName) => {
  #|    return SYMBOL_START.test(token.charAt(0)) &&
  #|      token !== 'true' &&
  #|      token !== 'false' &&
  #|      token !== 'this' &&
  #|      token !== paramName &&
  #|      last !== '.';
  #|  };
  #|
  #|  while (tokens.length > 0) {
  #|    const token = tokens[0];
  #|
  #|    if (token === ']') {
  #|      bracketCount--;
  #|      if (bracketCount === 0) {
  #|        if (last === null) {
  #|          conditionalSource = conditionalSource + 'true';
  #|        }
  #|        tokens.shift();
  #|        conditionalSource += ')})';
  #|        try {
  #|          const conditionFunction = new Function(conditionalSource)();
  #|          conditionFunction.source = conditionalSource;
  #|          return conditionFunction;
  #|        } catch (e) {
  #|          console.error('htmx: syntax error in conditional:', e, conditionalSource);
  #|          return null;
  #|        }
  #|      }
  #|    } else if (token === '[') {
  #|      bracketCount++;
  #|    }
  #|
  #|    if (isPossibleRelativeReference(token, last, paramName)) {
  #|      conditionalSource += '((' + paramName + '.' + token + ') ? (' + paramName + '.' + token + ') : (window.' + token + '))';
  #|    } else {
  #|      conditionalSource = conditionalSource + token;
  #|    }
  #|    last = tokens.shift();
  #|  }
  #|
  #|  return null;
  #|}
