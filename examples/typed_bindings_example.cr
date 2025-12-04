require "../src/webview"

# Example demonstrating type-safe bindings between Crystal and JavaScript
# This shows how bind_typed provides compile-time type safety and automatic
# JSON conversion, eliminating boilerplate code.

html = <<-HTML
<!DOCTYPE html>
<html>
<head>
  <title>Type-Safe Bindings Example</title>
  <style>
    body { 
      font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
      max-width: 800px;
      margin: 50px auto;
      padding: 20px;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      color: white;
    }
    .container {
      background: rgba(255, 255, 255, 0.1);
      backdrop-filter: blur(10px);
      border-radius: 15px;
      padding: 30px;
      box-shadow: 0 8px 32px 0 rgba(31, 38, 135, 0.37);
    }
    h1 { margin-top: 0; }
    button {
      background: white;
      color: #667eea;
      border: none;
      padding: 12px 24px;
      margin: 10px 5px;
      border-radius: 8px;
      cursor: pointer;
      font-size: 16px;
      font-weight: bold;
      transition: transform 0.2s;
    }
    button:hover { transform: scale(1.05); }
    button:active { transform: scale(0.95); }
    #output {
      background: rgba(0, 0, 0, 0.3);
      padding: 20px;
      border-radius: 8px;
      margin-top: 20px;
      min-height: 100px;
      font-family: 'Courier New', monospace;
    }
    .result { 
      margin: 5px 0;
      padding: 8px;
      background: rgba(255, 255, 255, 0.1);
      border-radius: 4px;
    }
  </style>
</head>
<body>
  <div class="container">
    <h1>🔷 Type-Safe Crystal ↔ JavaScript Bindings</h1>
    <p>Click buttons to call Crystal functions with type-safe parameters:</p>
    
    <button onclick="testAdd()">Int32 Addition</button>
    <button onclick="testMultiply()">Int64 Multiply</button>
    <button onclick="testDivide()">Float64 Division</button>
    <button onclick="testConcat()">String Concat</button>
    <button onclick="testMixed()">Mixed Types</button>
    <button onclick="clearOutput()">Clear</button>
    
    <div id="output"></div>
  </div>
  
  <script>
    const output = document.getElementById('output');
    
    function log(msg) {
      const div = document.createElement('div');
      div.className = 'result';
      div.textContent = msg;
      output.appendChild(div);
      output.scrollTop = output.scrollHeight;
    }
    
    function clearOutput() {
      output.innerHTML = '';
    }
    
    async function testAdd() {
      log('JS: Calling add(42, 58)');
      const result = await add(42, 58);
      log(`JS: Result = ${result} (type: ${typeof result})`);
    }
    
    async function testMultiply() {
      log('JS: Calling multiply(123456, 789)');
      const result = await multiply(123456, 789);
      log(`JS: Result = ${result} (type: ${typeof result})`);
    }
    
    async function testDivide() {
      log('JS: Calling divide(22.0, 7.0)');
      const result = await divide(22.0, 7.0);
      log(`JS: Result = ${result.toFixed(6)} (type: ${typeof result})`);
    }
    
    async function testConcat() {
      log('JS: Calling concat("Crystal", "Rocks!")');
      const result = await concat("Crystal", "Rocks!");
      log(`JS: Result = "${result}" (type: ${typeof result})`);
    }
    
    async function testMixed() {
      log('JS: Calling format(99, "bottles", true)');
      const result = await format(99, "bottles", true);
      log(`JS: Result = "${result}"`);
    }
    
    window.addEventListener('load', () => {
      log('✓ Ready! Click buttons to test type-safe bindings.');
    });
  </script>
</body>
</html>
HTML

puts "=" * 70
puts "Type-Safe Bindings Example"
puts "=" * 70
puts ""
puts "This example demonstrates the bind_typed feature which provides:"
puts "  • Compile-time type safety"
puts "  • Automatic JSON ↔ Crystal type conversion"
puts "  • Clean, readable code without boilerplate"
puts ""

# Create webview
wv = Webview.window(900, 700, Webview::SizeHints::NONE, "Type-Safe Bindings Example", true)

puts "Registering type-safe bindings..."
puts ""

# Example 1: Int32 + Int32 -> Int32
# JavaScript will call: add(42, 58)
# Crystal receives typed Int32 parameters automatically
wv.bind_typed("add", Int32, Int32) do |a, b|
  result = a + b
  puts "  Crystal: add(#{a}, #{b}) = #{result}"
  result
end

# Example 2: Int64 * Int64 -> Int64
# Demonstrates handling of larger integer types
wv.bind_typed("multiply", Int64, Int64) do |a, b|
  result = a * b
  puts "  Crystal: multiply(#{a}, #{b}) = #{result}"
  result
end

# Example 3: Float64 / Float64 -> Float64
# Shows floating-point arithmetic with automatic conversion
wv.bind_typed("divide", Float64, Float64) do |a, b|
  result = a / b
  puts "  Crystal: divide(#{a}, #{b}) = #{result}"
  result
end

# Example 4: String + String -> String
# String concatenation with automatic type conversion
wv.bind_typed("concat", String, String) do |a, b|
  result = "#{a} #{b}"
  puts "  Crystal: concat(\"#{a}\", \"#{b}\") = \"#{result}\""
  result
end

# Example 5: Mixed types - Int32, String, Bool -> String
# Demonstrates handling multiple different types in one binding
wv.bind_typed("format", Int32, String, Bool) do |num, text, flag|
  result = if flag
             "#{num} #{text} on the wall!"
           else
             "No #{text}"
           end
  puts "  Crystal: format(#{num}, \"#{text}\", #{flag}) = \"#{result}\""
  result
end

puts "✓ All bindings registered successfully"
puts ""
puts "Compare with traditional bind() approach:"
puts ""
puts "  Traditional:"
puts "    wv.bind(\"add\", Webview::JSProc.new { |args|"
puts "      a = args[0].as_i.to_i32  # Manual conversion"
puts "      b = args[1].as_i.to_i32  # Manual conversion"
puts "      JSON::Any.new(a + b)     # Manual wrapping"
puts "    })"
puts ""
puts "  Type-safe:"
puts "    wv.bind_typed(\"add\", Int32, Int32) do |a, b|"
puts "      a + b  # Clean, automatic conversion!"
puts "    end"
puts ""
puts "=" * 70
puts "Opening window... Close it to exit."
puts "=" * 70
puts ""

wv.html = html
wv.run
wv.destroy

puts ""
puts "Example completed!"
