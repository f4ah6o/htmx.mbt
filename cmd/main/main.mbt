///|
// Check if we're in a browser environment (document exists)
// This prevents errors when running tests in Node.js
extern "js" fn is_browser() -> Bool =
  #|() => { return typeof document !== 'undefined'; }

///|
fn init {
  // Only initialize htmx if we're in a browser environment
  println("DEBUG: Main module loading...")
  if is_browser() {
    @htmx.htmx_init()
  }
}

///|
fn main {
  // Keep main for moon run compatibility
  println("DEBUG: Main function running")
}
