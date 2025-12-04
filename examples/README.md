# Webview Examples

This directory contains examples demonstrating various features of the Crystal Webview library.

## 1. Type-Safe Bindings Example

**File:** `typed_bindings_example.cr`

Demonstrates the `bind_typed` feature which provides compile-time type safety and automatic JSON conversion for Crystal ↔ JavaScript bindings.

## 2. Advanced Features Example

**File:** `advanced_features.cr`

Demonstrates advanced features including:

- RAII-style resource management (`with_window`)
- Lifecycle hooks (`on_load`)
- Async/fiber support (`eval_async`, `eval_with_channel`)
- Better error handling with context
- Native handle access (`native_handle`)

### Running the Example

```bash
crystal run examples/typed_bindings_example.cr
```

Or compile and run:

```bash
crystal build examples/typed_bindings_example.cr -o examples/typed_bindings_example
./examples/typed_bindings_example
```

### What It Demonstrates

1. **Int32 Addition** - Basic integer arithmetic with type safety
2. **Int64 Multiplication** - Handling larger integer types
3. **Float64 Division** - Floating-point operations
4. **String Concatenation** - String manipulation
5. **Mixed Types** - Combining Int32, String, and Bool in one binding

### Key Benefits

- **Type Safety**: Compile-time type checking prevents runtime errors
- **Clean Code**: No manual JSON conversion boilerplate
- **Automatic Conversion**: Types are converted automatically between JSON and Crystal

### Code Comparison

**Traditional approach:**

```crystal
wv.bind("add", Webview::JSProc.new { |args|
  a = args[0].as_i.to_i32  # Manual conversion
  b = args[1].as_i.to_i32  # Manual conversion
  JSON::Any.new(a + b)     # Manual wrapping
})
```

**Type-safe approach:**

```crystal
wv.bind_typed("add", Int32, Int32) do |a, b|
  a + b  # Clean, automatic conversion!
end
```

## Supported Types

The `bind_typed` method currently supports:

- `Int32` - 32-bit integers
- `Int64` - 64-bit integers
- `Float64` - Double-precision floating-point
- `String` - Text strings
- `Bool` - Boolean values

## Adding More Examples

To add a new example:

1. Create a new `.cr` file in this directory
2. Add documentation here
3. Ensure it compiles and runs correctly

## New Features Summary

### A. Complete FFI Bindings

- ✅ Added `get_native_handle()` for accessing platform-specific handles
- ✅ Exposed `NativeHandleKind` enum (UI_WINDOW, UI_WIDGET, BROWSER_CONTROLLER)

### B. Type-Safe Bindings

- ✅ `bind_typed` with 1, 2, or 3 parameters
- ✅ Automatic JSON ↔ Crystal type conversion
- ✅ Support for Int32, Int64, Float64, String, Bool

### C. Async/Fiber Support

- ✅ `eval_async` - Execute JavaScript with callback
- ✅ `eval_with_channel` - Fiber-friendly async evaluation

### D. Better Error Handling

- ✅ Error context information
- ✅ Contextual error messages (e.g., "navigating to URL")

### E. Lifecycle Hooks

- ✅ `on_load` callback for page load events
- ✅ `on_navigate` property for navigation tracking

### F. Resource Management

- ✅ `with_window` - RAII-style automatic cleanup
- ✅ Ensures `destroy` is called even on exceptions
