require "json"

# Crystal bindings for [zserge's Webview](https://github.com/zserge/webview) which is an excellent cross-platform single header webview library for C/C++ using Gtk, Cocoa or MSHTML repectively.
module Webview
  VERSION = {{ `shards version "#{__DIR__}"`.chomp.stringify }}

  # Window size hints
  enum SizeHints
    NONE  = 0 # Width and height are default size
    MIN   = 1 # Width and height are minimum bounds
    MAX   = 2 # Width and height are maximum bounds
    FIXED = 3 # Window size can not be changed by user
  end

  record VersionInfo, major : UInt32, minor : UInt32, patch : UInt32, version_number : String,
    pre_release : String, build_metadata : String do
    def self.new(ptr : Pointer(LibWebView::WebviewVersionInfo))
      rec = ptr.value
      new(rec.version.major, rec.version.minor, rec.version.patch,
        String.new(rec.version_number.to_unsafe),
        String.new(rec.pre_release.to_unsafe), String.new(rec.build_metadata.to_unsafe))
    end
  end

  alias JSProc = Array(JSON::Any) -> JSON::Any

  class Webview
    private record BindContext, w : LibWebView::T, cb : JSProc

    @@dispatchs = Hash(Proc(Nil), Pointer(Void)?).new
    @@bindings = Hash(JSProc, Pointer(Void)?).new

    def initialize(debug, title)
      @w = LibWebView.create(debug ? 1 : 0, nil)
      LibWebView.set_title(@w, title)
    end

    # destroys a WebView and closes the native window.
    def destroy
      LibWebView.destroy(@w)
    end

    # Terminate stops the main loop. It is safe to call this function from
    # a background thread.
    def terminate
      LibWebView.terminate(@w)
    end

    # runs the main loop until it's terminated. After this function exists
    # you must destroy the WebView
    def run
      LibWebView.run(@w)
    end

    # returns a native window handle pointer. When using GTK backend the
    # pointer is GtkWindow pointer, when using Cocoa backend the pointer is
    # NSWindow pointer, when using Win32 backend the pointer is HWND pointer.
    def window
      LibWebView.get_window(@w)
    end

    def title=(val)
      LibWebView.set_title(@w, val)
    end

    def size(width, height, hint : SizeHints)
      LibWebView.set_size(@w, width, height, hint.value)
    end

    # navigates WebView to the given URL. URL may be a data URI, i.e.
    # "data:text/text,<html>..</html>". It is often ok not to url-encode it
    # properlty, WebView will re-encode it for you.
    def navigate(url)
      LibWebView.navigate(@w, url)
    end

    # Set WebView HTML directly
    def html=(html : String)
      LibWebView.set_html(@w, html)
    end

    # posts a function to be executed on the main thread. You normally do no need
    # to call this function, unless you want to tweak the native window.
    def dispatch(&f : ->)
      boxed = Box.box(f)
      @@dispatchs[f] = boxed

      LibWebView.dispatch(@w, ->(_w, data) {
        cb = Box(typeof(f)).unbox(data)
        cb.call
        @@dispatchs.delete(cb)
      }, boxed)
    end

    # injects Javascript code at the initialization of the new page. Every
    # time the WebView will open the new page - this initialization code will
    # be executed. It is guaranteed that code is executed before window.onload.
    def init(js : String)
      LibWebView.init(@w, js)
    end

    # evaluates arbitrary Javascript code. Evaluation happens asynchronously,
    # also the result of the expression is ignored. Use RPC bindings if you want
    # to receive notifications about the result of the evaluation.
    def eval(js : String)
      LibWebView.eval(@w, js)
    end

    # binds a callback function so that it will appear under the given name
    # as a global Javascript function.
    def bind(name : String, fn : JSProc)
      ctx = BindContext.new(@w, fn)
      boxed = Box.box(ctx)
      @@bindings[fn] = boxed

      LibWebView.bind(@w, name, ->(id, req, data) {
        raw = JSON.parse(String.new(req))
        cb_ctx = Box(BindContext).unbox(data)
        res = cb_ctx.cb.call(raw.as_a)
        @@bindings.delete(cb_ctx.cb)
        LibWebView.webview_return(cb_ctx.w, id, 0, res.to_json)
      }, boxed)
    end

    # Removes a native Crystal callback that was previously set by `bind`.
    def unbind(name : String)
      LibWebView.unbind(@w, name)
    end
  end

  def self.window(width : Int32, height : Int32, hint : SizeHints, title : String, debug = false)
    wv = Webview.new(debug, title)
    wv.size(width, height, hint)
    wv.title = title
    wv
  end

  def self.window(width : Int32, height : Int32, hint : SizeHints, title : String, url : String, debug = false)
    wv = Webview.new(debug, title)
    wv.size(width, height, hint)
    wv.title = title
    wv.navigate(url)
    wv
  end

  # Get the library's version information.
  def self.version
    VersionInfo.new(LibWebView.version)
  end
end

require "./*"
