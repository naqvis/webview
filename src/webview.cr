require "json"
require "./lib"

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

  # Native handle kinds
  enum NativeHandleKind
    UI_WINDOW          = 0 # Top-level window
    UI_WIDGET          = 1 # Browser widget
    BROWSER_CONTROLLER = 2 # Browser controller
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
    getter context : String?

    def initialize(@error_code : LibWebView::Error, message : String? = nil, @context : String? = nil)
      super(build_message(message))
    end

    private def build_message(custom_message)
      msg = custom_message || error_code.to_s
      context ? "#{msg} (context: #{context})" : msg
    end
  end

  alias JSProc = Array(JSON::Any) -> JSON::Any

  class Webview
    private record BindContext, w : LibWebView::T, cb : JSProc

    @@dispatchs = Hash(Proc(Nil), Pointer(Void)?).new
    @@bindings = Hash(JSProc, Pointer(Void)?).new

    # Lifecycle event callbacks
    property on_load : Proc(Nil)?
    property on_navigate : Proc(String, Nil)?

    def initialize(debug, title)
      @w = LibWebView.create(debug ? 1 : 0, nil)
      check_error(LibWebView.set_title(@w, title))
      setup_lifecycle_hooks
    end

    # Setup internal lifecycle hooks for page events
    private def setup_lifecycle_hooks
      # Inject JS to notify Crystal of page events
      init(<<-JS)
        if (typeof window.__crystal_lifecycle_setup === 'undefined') {
          window.__crystal_lifecycle_setup = true;
          window.addEventListener('load', () => {
            if (typeof window.__crystal_page_loaded !== 'undefined') {
              window.__crystal_page_loaded();
            }
          });
        }
      JS

      # Bind internal lifecycle callbacks
      bind("__crystal_page_loaded", JSProc.new { |_|
        on_load.try &.call
        JSON::Any.new(nil)
      })
    end

    # Helper method to check error codes and raise exceptions if needed
    private def check_error(result : LibWebView::Error, context : String? = nil)
      raise Error.new(result, context: context) unless result.ok?
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

    # Get a native handle of choice (window, widget, or browser controller)
    def native_handle(kind : NativeHandleKind)
      LibWebView.get_native_handle(@w, LibWebView::NativeHandleKind.new(kind.value))
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
      check_error(LibWebView.navigate(@w, url), "navigating to #{url}")
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

    # Evaluates JavaScript asynchronously with a callback
    def eval_async(js : String, &callback : ->)
      dispatch do
        eval(js)
        callback.call
      end
    end

    # Evaluates JavaScript and returns result via a channel (fiber-friendly)
    def eval_with_channel(js : String) : Channel(Nil)
      channel = Channel(Nil).new
      dispatch do
        eval(js)
        channel.send(nil)
      end
      channel
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

    # Type-safe binding for 1 parameter
    def bind_typed(name : String, t1 : T1.class, &block : T1 -> R) forall T1, R
      bind(name, JSProc.new { |args|
        raise ArgumentError.new("Expected 1 argument, got #{args.size}") if args.size != 1
        a1 = TypedBinding.convert_from_json(args[0], t1)
        result = block.call(a1)
        TypedBinding.convert_to_json(result)
      })
    end

    # Type-safe binding for 2 parameters
    def bind_typed(name : String, t1 : T1.class, t2 : T2.class, &block : T1, T2 -> R) forall T1, T2, R
      bind(name, JSProc.new { |args|
        raise ArgumentError.new("Expected 2 arguments, got #{args.size}") if args.size != 2
        a1 = TypedBinding.convert_from_json(args[0], t1)
        a2 = TypedBinding.convert_from_json(args[1], t2)
        result = block.call(a1, a2)
        TypedBinding.convert_to_json(result)
      })
    end

    # Type-safe binding for 3 parameters
    def bind_typed(name : String, t1 : T1.class, t2 : T2.class, t3 : T3.class, &block : T1, T2, T3 -> R) forall T1, T2, T3, R
      bind(name, JSProc.new { |args|
        raise ArgumentError.new("Expected 3 arguments, got #{args.size}") if args.size != 3
        a1 = TypedBinding.convert_from_json(args[0], t1)
        a2 = TypedBinding.convert_from_json(args[1], t2)
        a3 = TypedBinding.convert_from_json(args[2], t3)
        result = block.call(a1, a2, a3)
        TypedBinding.convert_to_json(result)
      })
    end
  end

  # Helper module for type conversions in bind_typed
  module TypedBinding
    def self.convert_from_json(json_val : JSON::Any, type : T.class) forall T
      {% if T == Int32 %}
        json_val.as_i.to_i32
      {% elsif T == Int64 %}
        json_val.as_i64
      {% elsif T == Float64 %}
        json_val.as_f
      {% elsif T == String %}
        json_val.as_s
      {% elsif T == Bool %}
        json_val.as_bool
      {% else %}
        T.from_json(json_val.to_json)
      {% end %}
    end

    def self.convert_to_json(value)
      case value
      when Int32, Int64, Float64, String, Bool, Nil
        JSON::Any.new(value)
      when Array
        JSON::Any.new(value.map { |v| JSON::Any.new(v) })
      when Hash
        JSON::Any.new(value.transform_values { |v| JSON::Any.new(v) })
      else
        JSON.parse(value.to_json)
      end
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

  # RAII-style resource management - automatically destroys webview when block exits
  def self.with_window(width : Int32, height : Int32, hint : SizeHints, title : String, debug = false, &)
    wv = window(width, height, hint, title, debug)
    begin
      yield wv
    ensure
      wv.destroy
    end
  end

  # RAII-style resource management with URL
  def self.with_window(width : Int32, height : Int32, hint : SizeHints, title : String, url : String, debug = false, &)
    wv = window(width, height, hint, title, url, debug)
    begin
      yield wv
    ensure
      wv.destroy
    end
  end

  # Get the library's version information.
  def self.version
    VersionInfo.new(LibWebView.version)
  end
end

require "./window_manager"
