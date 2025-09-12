require "json"

# Crystal bindings for [zserge's Webview](https://github.com/zserge/webview) which is an excellent cross-platform single header webview library for C/C++ using Gtk, Cocoa or MSHTML respectively.
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

  # Exception class for webview errors
  class Error < Exception
    getter error_code : LibWebView::Error

    def initialize(@error_code : LibWebView::Error, message : String? = nil)
      super(message || error_code.to_s)
    end
  end

  alias JSProc = Array(JSON::Any) -> JSON::Any

  class Webview
    private record BindContext, w : LibWebView::T, cb : JSProc

    @@dispatchs = Hash(Proc(Nil), Pointer(Void)?).new
    @@bindings = Hash(JSProc, Pointer(Void)?).new

    def initialize(debug, title)
      @w = LibWebView.create(debug ? 1 : 0, nil)
      check_error(LibWebView.set_title(@w, title))
    end

    # Helper method to check error codes and raise exceptions if needed
    private def check_error(result : LibWebView::Error)
      raise Error.new(result) unless result.ok?
    end

    # destroys a WebView and closes the native window.
    def destroy
      check_error(LibWebView.destroy(@w))
    end

    # Terminate stops the main loop. It is safe to call this function from
    # a background thread.
    def terminate
      check_error(LibWebView.terminate(@w))
    end

    # runs the main loop until it's terminated. After this function exists
    # you must destroy the WebView
    def run
      check_error(LibWebView.run(@w))
    end

    # returns a native window handle pointer. When using GTK backend the
    # pointer is GtkWindow pointer, when using Cocoa backend the pointer is
    # NSWindow pointer, when using Win32 backend the pointer is HWND pointer.
    def window
      LibWebView.get_window(@w)
    end

    def title=(val)
      check_error(LibWebView.set_title(@w, val))
    end

    def size(width, height, hint : SizeHints)
      check_error(LibWebView.set_size(@w, width, height, hint))
    end

    # navigates WebView to the given URL. URL may be a data URI, i.e.
    # "data:text/text,<html>..</html>". It is often ok not to url-encode it
    # properlty, WebView will re-encode it for you.
    def navigate(url)
      check_error(LibWebView.navigate(@w, url))
    end

    # Set WebView HTML directly
    def html=(html : String)
      check_error(LibWebView.set_html(@w, html))
    end

    # posts a function to be executed on the main thread. You normally do no need
    # to call this function, unless you want to tweak the native window.
    def dispatch(&f : ->)
      boxed = Box.box(f)
      @@dispatchs[f] = boxed

      check_error(LibWebView.dispatch(@w, ->(_w, data) {
        cb = Box(typeof(f)).unbox(data)
        cb.call
        @@dispatchs.delete(cb)
      }, boxed))
    end

    # injects Javascript code at the initialization of the new page. Every
    # time the WebView will open the new page - this initialization code will
    # be executed. It is guaranteed that code is executed before window.onload.
    def init(js : String)
      check_error(LibWebView.init(@w, js))
    end

    # evaluates arbitrary Javascript code. Evaluation happens asynchronously,
    # also the result of the expression is ignored. Use RPC bindings if you want
    # to receive notifications about the result of the evaluation.
    def eval(js : String)
      check_error(LibWebView.eval(@w, js))
    end

    # binds a callback function so that it will appear under the given name
    # as a global Javascript function.
    def bind(name : String, fn : JSProc)
      ctx = BindContext.new(@w, fn)
      boxed = Box.box(ctx)
      @@bindings[fn] = boxed

      check_error(LibWebView.bind(@w, name, ->(id, req, data) {
        raw = JSON.parse(String.new(req))
        cb_ctx = Box(BindContext).unbox(data)
        res = cb_ctx.cb.call(raw.as_a)
        LibWebView.webview_return(cb_ctx.w, id, 0, res.to_json)
      }, boxed))
    end

    # Removes a native Crystal callback that was previously set by `bind`.
    def unbind(name : String)
      check_error(LibWebView.unbind(@w, name))
      @@bindings.delete(name)
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
