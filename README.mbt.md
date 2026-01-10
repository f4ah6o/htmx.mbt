# htmx.mbt

A pure MoonBit implementation of the [htmx](https://htmx.org) client library.
This library allows you to access AJAX, CSS Transitions, WebSockets and Server Sent Events directly in HTML, using attributes, so you can build modern user interfaces with the simplicity and power of hypertext.

## Features

This implementation strives for feature parity with htmx 1.9.x, strictly typed and compiled to optimized JavaScript.

### Core Attributes
- `hx-get`, `hx-post`, `hx-put`, `hx-delete`, `hx-patch`: AJAX requests
- `hx-trigger`: Granular event triggering (delay, throttle, once, changed, filters)
- `hx-target`: Swap target specification
- `hx-swap`: Swap strategies (`innerHTML`, `outerHTML`, etc.)
- `hx-select`: Content filtering from response
- `hx-push-url`: Browser history integration
- `hx-swap-oob`: Out-of-Band swaps

### Advanced Capabilities
- **DOM Morphing**: `hx-swap="morph"` preserves element state (focus, cursor position) using a recursive DOM diffing algorithm.
- **Form Data**: Automatic collection and submission of form values.
- **Mutation Observer**: Automatically processes content injected into the DOM.
- **No Dependencies**: Built on top of `mizchi/js` bindings.

## Installation

```bash
moon add horideicom/htmx
```

## Usage

Initialize the library in your main entry point:

```moonbit
import horideicom/htmx/htmx

fn main {
  htmx.htmx_init()
}
```

Then use `hx-` attributes in your HTML:

```html
<!-- Basic Request -->
<button hx-get="/api/clicked" hx-swap="outerHTML">
    Click Me
</button>

<!-- Form Submission -->
<form hx-post="/api/user">
    <input name="username">
    <button type="submit">Save</button>
</form>

<!-- Morphing Swap (Preserves Input State) -->
<div hx-target="this" hx-swap="morph">
    <input type="text" name="q" placeholder="Search...">
</div>
```

## Supported Swap Styles

- `innerHTML` - Replace the inner HTML of the target element
- `outerHTML` - Replace the entire target element with the response
- `beforebegin` - Insert the response before the target element
- `afterbegin` - Insert the response before the first child of the target element
- `beforeend` - Insert the response after the last child of the target element
- `afterend` - Insert the response after the target element
- `delete` - Deletes the target element regardless of the response
- `none` - Does not append content from response (out of band items will still be processed)
- `morph` - Morphs the target element to match the response, preserving focus and state

## Building & Testing

```bash
# Build for JavaScript target
moon build --target js

# Run tests
moon test --target js
```

## License

[Apache-2.0](./LICENSE)
