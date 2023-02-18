module Webview
  {% if flag?(:darwin) %}
    @[Link(framework: "WebKit")]
    @[Link(ldflags: "-L#{__DIR__}/../ext -lwebview.o -lc++")]
  {% elsif flag?(:linux) %}
    @[Link(ldflags: "`command -v pkg-config > /dev/null && pkg-config --cflags --libs gtk+-3.0 webkit2gtk-4.0`")]
    @[Link(ldflags: "#{__DIR__}/../ext/libwebview.a -lstdc++")]
  {% elsif flag?(:windows) %}
    @[Link("webview")]
    # TODO - Windows requires special linker flags for GUI apps, but this doesn't work with crystal stdlib (tried with Crystal 1.6.2).
    # @[Link(ldflags: "/subsystem:windows")]
  {% else %}
    raise "Platform not supported"
  {% end %}
  lib LibWebView
    alias T = Void*

    # Creates a new webview instance. If debug is non-zero - developer tools will
    # be enabled (if the platform supports them). Window parameter can be a
    # pointer to the native window handle. If it's non-null - then child WebView
    # is embedded into the given parent window. Otherwise a new window is created.
    # Depending on the platform, a GtkWindow, NSWindow or HWND pointer can be
    # passed here.
    fun create = webview_create(debug : LibC::Int, window : Void*) : T
    # Destroys a webview and closes the native window.
    fun destroy = webview_destroy(w : T)
    # Runs the main loop until it's terminated. After this function exits - you
    # must destroy the webview.
    fun run = webview_run(w : T)
    # Stops the main loop. It is safe to call this function from another other
    # background thread.
    fun terminate = webview_terminate(w : T)
    # Posts a function to be executed on the main thread. You normally do not need
    # to call this function, unless you want to tweak the native window.
    fun dispatch = webview_dispatch(w : T, fn : (T, Void* -> Void), arg : Void*)
    # Returns a native window handle pointer. When using GTK backend the pointer
    # is GtkWindow pointer, when using Cocoa backend the pointer is NSWindow
    # pointer, when using Win32 backend the pointer is HWND pointer.
    fun get_window = webview_get_window(w : T) : Void*
    # Updates the title of the native window. Must be called from the UI thread.
    fun set_title = webview_set_title(w : T, title : LibC::Char*)
    # Updates native window size. See WEBVIEW_HINT constants.
    fun set_size = webview_set_size(w : T, width : LibC::Int, height : LibC::Int, hints : LibC::Int)
    # Navigates webview to the given URL. URL may be a data URI, i.e.
    # "data:text/text,<html>...</html>". It is often ok not to url-encode it
    # properly, webview will re-encode it for you.
    fun navigate = webview_navigate(w : T, url : LibC::Char*)
    # Set webview HTML directly.
    # Example: webview_set_html(w, "<h1>Hello</h1>");
    fun set_html = webview_set_html(w : T, html : LibC::Char*)
    # Injects JavaScript code at the initialization of the new page. Every time
    # the webview will open a the new page - this initialization code will be
    # executed. It is guaranteed that code is executed before window.onload.
    fun init = webview_init(w : T, js : LibC::Char*)
    # Evaluates arbitrary JavaScript code. Evaluation happens asynchronously, also
    # the result of the expression is ignored. Use RPC bindings if you want to
    # receive notifications about the results of the evaluation.
    fun eval = webview_eval(w : T, js : LibC::Char*)
    # Binds a native C callback so that it will appear under the given name as a
    # global JavaScript function. Internally it uses webview_init(). Callback
    # receives a request string and a user-provided argument pointer. Request
    # string is a JSON array of all the arguments passed to the JavaScript
    # function.
    fun bind = webview_bind(w : T, name : LibC::Char*, fn : (LibC::Char*, LibC::Char*, Void* -> Void), arg : Void*)
    # Removes a native C callback that was previously set by webview_bind.
    fun unbind = webview_unbind(w : T, name : LibC::Char*)
    # Allows to return a value from the native binding. Original request pointer
    # must be provided to help internal RPC engine match requests with responses.
    # If status is zero - result is expected to be a valid JSON result value.
    # If status is not zero - result is an error JSON object.
    fun webview_return(w : T, seq : LibC::Char*, status : LibC::Int, result : LibC::Char*)
    # Get the library's version information.
    # @since 0.10
    fun version = webview_version : WebviewVersionInfo*

    # Holds the library's version information.
    struct WebviewVersionInfo
      # The elements of the version number.
      version : WebviewVersion
      # SemVer 2.0.0 version number in MAJOR.MINOR.PATCH format.
      version_number : LibC::Char[32]
      # SemVer 2.0.0 pre-release labels prefixed with "-" if specified, otherwise
      # an empty string.
      pre_release : LibC::Char[48]
      # SemVer 2.0.0 build metadata prefixed with "+", otherwise an empty string.
      build_metadata : LibC::Char[48]
    end

    # Holds the elements of a MAJOR.MINOR.PATCH version number.
    struct WebviewVersion
      major : LibC::UInt
      minor : LibC::UInt
      patch : LibC::UInt
    end
  end
end
