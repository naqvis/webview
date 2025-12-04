require "../src/webview"

# Example demonstrating multi-window management
# Shows how to create and manage multiple webview windows

puts "=" * 70
puts "Multi-Window Management Demo"
puts "=" * 70
puts ""

# Create HTML for different windows
window1_html = <<-HTML
<!DOCTYPE html>
<html>
<head>
  <title>Window 1</title>
  <style>
    body {
      font-family: Arial, sans-serif;
      padding: 40px;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      color: white;
      text-align: center;
    }
    h1 { font-size: 48px; }
    button {
      background: white;
      color: #667eea;
      border: none;
      padding: 15px 30px;
      margin: 10px;
      border-radius: 8px;
      cursor: pointer;
      font-size: 18px;
      font-weight: bold;
    }
    button:hover { opacity: 0.9; }
    #counter { font-size: 36px; margin: 20px; }
  </style>
</head>
<body>
  <h1>🔵 Window 1</h1>
  <p>This is the first window</p>
  <div id="counter">Count: 0</div>
  <button onclick="increment()">Increment</button>
  <button onclick="sendToWindow2()">Send to Window 2</button>
  
  <script>
    let count = 0;
    function increment() {
      count++;
      document.getElementById('counter').textContent = 'Count: ' + count;
      updateCount(count);
    }
    
    async function sendToWindow2() {
      await sendMessage('Hello from Window 1!');
    }
  </script>
</body>
</html>
HTML

window2_html = <<-HTML
<!DOCTYPE html>
<html>
<head>
  <title>Window 2</title>
  <style>
    body {
      font-family: Arial, sans-serif;
      padding: 40px;
      background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
      color: white;
      text-align: center;
    }
    h1 { font-size: 48px; }
    button {
      background: white;
      color: #f5576c;
      border: none;
      padding: 15px 30px;
      margin: 10px;
      border-radius: 8px;
      cursor: pointer;
      font-size: 18px;
      font-weight: bold;
    }
    button:hover { opacity: 0.9; }
    #messages {
      background: rgba(0, 0, 0, 0.3);
      padding: 20px;
      border-radius: 8px;
      margin-top: 20px;
      min-height: 100px;
    }
    .message {
      margin: 10px 0;
      padding: 10px;
      background: rgba(255, 255, 255, 0.2);
      border-radius: 4px;
    }
  </style>
</head>
<body>
  <h1>🔴 Window 2</h1>
  <p>This is the second window</p>
  <button onclick="testCrystal()">Call Crystal</button>
  <div id="messages"></div>
  
  <script>
    function addMessage(msg) {
      const div = document.createElement('div');
      div.className = 'message';
      div.textContent = msg;
      document.getElementById('messages').appendChild(div);
    }
    
    async function testCrystal() {
      const result = await greet('Window 2');
      addMessage('Crystal says: ' + result);
    }
    
    window.addEventListener('load', () => {
      addMessage('Window 2 ready!');
    });
  </script>
</body>
</html>
HTML

window3_html = <<-HTML
<!DOCTYPE html>
<html>
<head>
  <title>Window 3</title>
  <style>
    body {
      font-family: Arial, sans-serif;
      padding: 40px;
      background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%);
      color: white;
      text-align: center;
    }
    h1 { font-size: 48px; }
    #status { font-size: 24px; margin: 20px; }
  </style>
</head>
<body>
  <h1>🟢 Window 3</h1>
  <p>This is the third window</p>
  <div id="status">Status: Active</div>
</body>
</html>
HTML

# Use WindowManager for RAII-style management
Webview::WindowManager.with_manager do |manager|
  puts "Creating multiple windows..."
  puts ""

  # Create all windows first with different sizes so they're easier to distinguish
  window1 = manager.create_window(600, 500, Webview::SizeHints::NONE, "🔵 Window 1", true)
  window2 = manager.create_window(650, 550, Webview::SizeHints::NONE, "🔴 Window 2", true)
  window3 = manager.create_window(700, 600, Webview::SizeHints::NONE, "🟢 Window 3", true)

  # Set HTML content
  window1.html = window1_html
  window2.html = window2_html
  window3.html = window3_html

  # Bind functions for window 1
  window1.bind_typed("updateCount", Int32) do |count|
    puts "  Window 1: Count updated to #{count}"
    "OK"
  end

  window1.bind_typed("sendMessage", String) do |msg|
    puts "  Window 1: Sending message: #{msg}"
    # Send message to Window 2 via JavaScript (escape quotes)
    escaped_msg = msg.gsub("'", "\\\\'")
    window2.eval("addMessage('From Window 1: #{escaped_msg}')")
    "Message sent"
  end

  puts "✓ Window 1 created (600x500)"

  # Bind functions for window 2
  window2.bind_typed("greet", String) do |name|
    greeting = "Hello #{name} from Crystal!"
    puts "  Window 2: Greeting #{name}"
    greeting
  end

  puts "✓ Window 2 created (650x550)"
  puts "✓ Window 3 created (700x600)"
  puts ""
  puts "Manager stats:"
  puts "  Total windows: #{manager.count}"
  puts ""
  puts "=" * 70
  puts "All 3 windows are open!"
  puts "NOTE: Windows may stack on top of each other - drag them apart"
  puts "      to see all three windows (different sizes & emojis in titles)"
  puts ""
  puts "Try clicking 'Send to Window 2' in Window 1 to see inter-window"
  puts "communication in action!"
  puts ""
  puts "Close any window to exit (they'll all be cleaned up automatically)"
  puts "=" * 70
  puts ""

  # Run the first window (blocking)
  # In a real app, you might use run_all with fibers for concurrent windows
  window1.run

  puts ""
  puts "Window closed, cleaning up..."
end

puts ""
puts "✓ All windows automatically destroyed (RAII cleanup)"
puts "Demo completed!"
