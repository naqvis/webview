# Crystal Webview

Crystal language bindings for [zserge's Webview](https://github.com/zserge/webview) which is an excellent cross-platform single-header webview library for C/C++ using Gtk, Cocoa, or MSHTML/Edge, depending on the host OS.

**Webview** relys on default rendering engine of host Operating System, thus binaries generated with this Shard will be much more leaner as compared to [Electron](https://github.com/electron/electron) which bundles Chromium with each distribution.

This shard supports **two-way bindings** between Crystal and JavaScript. You can invoke JS code via `Webview::Webview#eval` and calling Crystal code from JS is done via `WebView::Webview#bind` (refer to Examples 3 & 4 for samples on how to invoke Crystal functions from JS).

Webview-supported platforms and the engines you can expect to render your application content are as follows:

| Operating System | Browser Engine Used |
| ---------------- | ------------------- |
| macOS            | Cocoa, [WebKit][webkit] |
| Linux            | [GTK 3][gtk], [WebKitGTK][webkitgtk]|
| Windows          | [Windows API][win32-api], [WebView2][ms-webview2]  |

## Pre-requisite
If you're planning on targeting Linux or BSD you must ensure that [WebKit2GTK][webkitgtk] is already installed and available for discovery via the pkg-config command.

Debian-based systems:

* Packages:
  * Development: `apt install libgtk-3-dev libwebkit2gtk-4.0-dev`
  * Production: `apt install libgtk-3-0 libwebkit2gtk-4.0-37`

BSD-based systems:

* FreeBSD packages: `pkg install webkit2-gtk3`
* Execution on BSD-based systems may require adding the `wxallowed` option (see [mount(8)](https://man.openbsd.org/mount.8))  to your fstab to bypass [W^X](https://en.wikipedia.org/wiki/W%5EX "write xor execute") memory protection for your executable. Please see if it works without disabling this security feature first.

Microsoft Windows:

* You should have Visual C++ Build tools already as it's a pre-requisite for crystal compiler
* `git clone https://github.com/webview/webview` to get WebView sources
* `webview\script\build.bat` to compile them (it will download required nuget package)
* copy `webview\dll\x64\webview.lib` to `<your crystal installation>\lib`
* copy `webview\dll\x64\webview.dll` to directory with your program
  
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
<!DOCTYPE html><html lang="en-US">
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

wv = Webview.window(640, 480, Webview::SizeHints::NONE, "Hello WebView")
wv.html = html
wv.run
wv.destroy
```

### Example 3: Calling Crystal code from JavaScript
```crystal
require "webview"

html = <<-HTML
<!doctype html>
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

wv = Webview.window(640, 480, Webview::SizeHints::NONE, "Hello WebView", true)
wv.html = html
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

wv = Webview.window(640, 480, Webview::SizeHints::NONE, "Hello WebView", true)
wv.html = html

wv.bind("add", Webview::JSProc.new { |n|
  wv.eval(sprintf(inject, n))
  JSON::Any.new(nil)
})

wv.run
wv.destroy
```

### Example 5: Running your web app in another thread

```crystal
Thread.new do
  get "/" do
    "hello from kemal"
  end
  Kemal.run
end

wv = Webview.window(640, 480, Webview::SizeHints::NONE, "WebView with local webapp!", "http://localhost:3000")
wv.run
wv.destroy
```

## App Distribution

Distribution of your app is outside the scope of this library but we can give some pointers for you to explore.

### macOS Application Bundle

On macOS you would typically create a bundle for your app with an icon and proper metadata.

A minimalistic bundle typically has the following directory structure:

```
example.app                 bundle
└── Contents
    ├── Info.plist          information property list
    ├── MacOS
    |   └── example         executable
    └── Resources
        └── example.icns    icon
```

Read more about the [structure of bundles][macos-app-bundle] at the Apple Developer site.

> Tip: The `png2icns` tool can create icns files from PNG files. See the `icnsutils` package for Debian-based systems.

### Windows Apps

You would typically create a resource script file (`*.rc`) with information about the app as well as an icon. Since you should have MinGW-w64 readily available then you can compile the file using `windres` and link it into your program. If you instead use Visual C++ then look into the [Windows Resource Compiler][win32-rc].

The directory structure could look like this:

```
my-project/
├── icons/
|   ├── application.ico
|   └── window.ico
├── basic.cc
└── resources.rc
```

`resources.rc`:
```
100 ICON "icons\\application.ico"
32512 ICON "icons\\window.ico"
```

> **Note:** The ID of the icon resource to be used for the window must be `32512` (`IDI_APPLICATION`).

## Limitations

### Browser Features

Since a browser engine is not a full web browser it may not support every feature you may expect from a browser. If you find that a feature does not work as expected then please consult with the browser engine's documentation and [open an issue on webview library][issues-new] if you think that the library should support it.

For example, the `webview` library does not attempt to support user interaction features like `alert()`, `confirm()` and `prompt()` and other non-essential features like `console.log()`.
## Contributing

1. Fork it (<https://github.com/naqvis/webview/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Ali Naqvi](https://github.com/naqvis) - creator and maintainer


[macos-app-bundle]:  https://developer.apple.com/library/archive/documentation/CoreFoundation/Conceptual/CFBundles/BundleTypes/BundleTypes.html
[gtk]:               https://docs.gtk.org/gtk3/
[issues-new]:        https://github.com/webview/webview/issues/new
[webkit]:            https://webkit.org/
[webkitgtk]:         https://webkitgtk.org/
[ms-webview2]:       https://developer.microsoft.com/en-us/microsoft-edge/webview2/
[ms-webview2-sdk]:   https://www.nuget.org/packages/Microsoft.Web.WebView2
[ms-webview2-rt]:    https://developer.microsoft.com/en-us/microsoft-edge/webview2/
[win32-api]:         https://docs.microsoft.com/en-us/windows/win32/apiindex/windows-api-list
[win32-rc]:          https://docs.microsoft.com/en-us/windows/win32/menurc/resource-compiler