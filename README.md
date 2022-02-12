# Crystal Webview

Crystal language bindings for [zserge's Webview](https://github.com/zserge/webview) which is an excellent cross-platform single header webview library for C/C++ using Gtk, Cocoa or MSHTML/Edge repectively.

**Webview** relys on default rendering engine of host Operating System, thus binaries generated with this Shard will be much more leaner as compared to [Electron](https://github.com/electron/electron) which bundles Chromium with each distribution.

Shard Supports **Two-way bindings** between Crystal and JavaScript. You can invoke JS code via `Webview::Webview#eval` and calling Crystal code from JS is done via `WebView::Webview#bind` (refer to Example 3 for sample on how to invoke Crystal functions from JS)

Webview supported platforms and the engines you can expect to render your application content are as follows:

| Operating System | Browser Engine Used |
| ---------------- | ------------------- |
| OSX              | Cocoa/WebKit        |
| Linux            | Gtk-webkit2         |
| Windows          | MSHTML or EdgeHTML  |

## Pre-requisite
If you're planning on targeting Linux you must ensure that Webkit2gtk is already installed and available for discovery via the pkg-config command.

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     webview:
       github: naqvis/webview
   ```

2. Run `shards install`

## Usage

### Example 1: Loading URL

```crystal
require "webview"

wv = Webview.window(640, 480, Webview::SizeHints::NONE, "Hello WebView", "http://crystal-lang.org")
wv.run
wv.destroy
```

### Example 2: Loading HTML

```crystal
require "webview"

html = <<-HTML
data:text/html,<!DOCTYPE html><html lang="en-US">
<head>
<title>Hello,World!</title>
</head>
<body>
<div class="container">
<header>
	<!-- Logo -->
   <h1>City Gallery</h1>
</header>
<nav>
  <ul>
    <li><a href="/London">London</a></li>
    <li><a href="/Paris">Paris</a></li>
    <li><a href="/Tokyo">Tokyo</a></li>
  </ul>
</nav>
<article>
  <h1>London</h1>
  <img src="pic_mountain.jpg" alt="Mountain View" style="width:304px;height:228px;">
  <p>London is the capital city of England. It is the most populous city in the  United Kingdom, with a metropolitan area of over 13 million inhabitants.</p>
  <p>Standing on the River Thames, London has been a major settlement for two millennia, its history going back to its founding by the Romans, who named it Londinium.</p>
</article>
<footer>Copyright &copy; W3Schools.com</footer>
</div>
</body>
</html>
HTML

wv = Webview.window(640, 480, Webview::SizeHints::NONE, "Hello WebView", html)
wv.run
wv.destroy
```

### Example 3: Calling Crystal code from JavaScript
```crystal
require "webview"

html = <<-HTML
data:text/html,<!doctype html>
<html>
  <body>hello</body>
  <script>
    window.onload = function() {
      document.body.innerText = "Javascript calling Crystal code";
      noop().then(function(res) {
        console.log('noop res', res);
        add(1, 2).then(function(res) {
          console.log('add res', res);
        });
      });
    };
  </script>
</html>
HTML

wv = Webview.window(640, 480, Webview::SizeHints::NONE, "Hello WebView", html, true)

wv.bind("noop", Webview::JSProc.new { |a|
  pp "Noop called with arguments: #{a}"
  JSON::Any.new("noop")
})

wv.bind("add", Webview::JSProc.new { |a|
  pp "add called with arguments: #{a}"
  ret = 0_i64
  a.each do |v|
    ret += v.as_i64
  end
  JSON::Any.new(ret)
})


wv.run
wv.destroy
```

### Example 4: Calling Crystal code from JavaScript and executing JavaScript from Crystal

```crystal
require "webview"

html = <<-HTML
<!DOCTYPE html><html lang="en-US">
<head>
<title>Hello,World!</title>
</head>
<body>
  <button onClick="add(document.body.children.length)">Add</button>
</body>
</html>
HTML


inject = <<-JS
  elem = document.createElement('div');  
  elem.innerHTML = "hello webview %s";
  document.body.appendChild(elem);
JS

wv = Webview.window(640, 480, Webview::SizeHints::NONE, "Hello WebView", "data:text/html,#{html}" , true)

wv.bind("add", Webview::JSProc.new { |n|
  wv.eval(sprintf(inject, n))
  JSON::Any.new(nil)
})

wv.run
wv.destroy
```

## Contributing

1. Fork it (<https://github.com/naqvis/webview/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Ali Naqvi](https://github.com/naqvis) - creator and maintainer
