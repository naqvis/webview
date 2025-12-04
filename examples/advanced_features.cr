require "../src/webview"

# Example demonstrating advanced features:
# - Better error handling with context
# - Lifecycle hooks (on_load)
# - Async/fiber support
# - RAII-style resource management
# - Native handle access

puts "=" * 70
puts "Advanced Features Demo"
puts "=" * 70
puts ""

# Feature 1: RAII-style resource management with with_window
puts "1. RAII-Style Resource Management"
puts "   Using with_window for automatic cleanup..."
puts ""

html = <<-HTML
<!DOCTYPE html>
<html>
<head>
  <title>Advanced Features</title>
  <style>
    body {
      font-family: Arial, sans-serif;
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
    }
    button:hover { opacity: 0.9; }
    #log {
      background: rgba(0, 0, 0, 0.3);
      padding: 15px;
      border-radius: 8px;
      margin-top: 20px;
      font-family: monospace;
      min-height: 100px;
    }
    .log-entry {
      margin: 5px 0;
      padding: 5px;
      background: rgba(255, 255, 255, 0.1);
      border-radius: 4px;
    }
  </style>
</head>
<body>
  <div class="container">
    <h1>🚀 Advanced Features Demo</h1>
    <p>Testing lifecycle hooks, async operations, and error handling</p>
    
    <button onclick="testAsync()">Test Async Eval</button>
    <button onclick="testError()">Test Error Handling</button>
    <button onclick="clearLog()">Clear Log</button>
    
    <div id="log"></div>
  </div>
  
  <script>
    function log(msg) {
      const logDiv = document.getElementById('log');
      const entry = document.createElement('div');
      entry.className = 'log-entry';
      entry.textContent = `[${new Date().toLocaleTimeString()}] ${msg}`;
      logDiv.appendChild(entry);
      logDiv.scrollTop = logDiv.scrollHeight;
    }
    
    function clearLog() {
      document.getElementById('log').innerHTML = '';
    }
    
    async function testAsync() {
      log('Calling async operation...');
      const result = await asyncOperation('test message');
      log(`Async result: ${result}`);
    }
    
    async function testError() {
      log('Testing error handling...');
      try {
        await errorTest('test');
        log('Error test completed');
      } catch (e) {
        log(`Caught error: ${e.message}`);
      }
    }
    
    // This will be called by Crystal when page loads
    window.addEventListener('load', () => {
      log('✓ Page loaded - lifecycle hook triggered!');
    });
  </script>
</body>
</html>
HTML

# Use with_window for automatic resource management
Webview.with_window(900, 700, Webview::SizeHints::NONE, "Advanced Features", true) do |wv|
  puts "✓ Window created (will be auto-destroyed on exit)"
  puts ""

  # Feature 2: Lifecycle hooks
  puts "2. Lifecycle Hooks"
  wv.on_load = -> {
    puts "   ✓ Crystal: Page load event triggered!"
  }
  puts "   Registered on_load callback"
  puts ""

  # Feature 3: Better error handling with context
  puts "3. Better Error Handling"
  puts "   Errors now include context information"
  puts ""

  # Feature 4: Async operations
  puts "4. Async/Fiber Support"
  wv.bind_typed("asyncOperation", String) do |msg|
    puts "   Crystal: Async operation called"
    # Simulate some work
    sleep 0.1.seconds
    result = "Processed: #{msg}"
    puts "   Crystal: Returning result"
    result
  end
  puts "   Registered async operation binding"
  puts ""

  # Feature 5: Error test binding
  wv.bind_typed("errorTest", String) do |msg|
    puts "   Crystal: Error test called with: #{msg}"
    "Success"
  end

  # Feature 6: Native handle access
  puts "5. Native Handle Access"
  window_handle = wv.window
  puts "   Window handle: #{window_handle}"

  # Try to get native handles (may return null on some platforms)
  begin
    ui_window = wv.native_handle(Webview::NativeHandleKind::UI_WINDOW)
    puts "   UI Window handle: #{ui_window}"
  rescue ex
    puts "   UI Window handle: Not available"
  end
  puts ""

  # Feature 7: Async eval with callback
  puts "6. Async JavaScript Evaluation"
  wv.html = html

  # Wait a bit for page to load, then test async eval
  spawn do
    sleep 1.second
    puts "   Executing async JavaScript..."
    wv.eval_async("console.log('Async eval from Crystal!')") do
      puts "   ✓ Async eval completed"
    end
  end

  puts ""
  puts "=" * 70
  puts "Window is open. Close it to exit."
  puts "The window will be automatically destroyed on exit (RAII pattern)"
  puts "=" * 70
  puts ""

  wv.run
end

puts ""
puts "✓ Window automatically destroyed (RAII cleanup)"
puts "Demo completed!"
