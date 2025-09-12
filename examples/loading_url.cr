require "../src/webview"

wv = Webview.window(640, 480, Webview::SizeHints::NONE, "Hello WebView", "http://crystal-lang.org")
wv.run
wv.destroy
