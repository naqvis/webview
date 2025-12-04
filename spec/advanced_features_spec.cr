require "./spec_helper"

describe "Advanced Features" do
  describe "Error handling with context" do
    it "includes context in error messages" do
      error = Webview::Error.new(
        Webview::LibWebView::Error::INVALID_ARGUMENT,
        "Invalid URL",
        "navigating to http://example.com"
      )

      msg = error.message
      msg.should_not be_nil
      msg.includes?("Invalid URL").should be_true if msg
      msg.includes?("navigating to http://example.com").should be_true if msg
      error.context.should eq("navigating to http://example.com")
    end

    it "works without context" do
      error = Webview::Error.new(Webview::LibWebView::Error::INVALID_ARGUMENT)

      error.context.should be_nil
      msg = error.message
      msg.includes?("context:").should be_false if msg
    end
  end

  describe "NativeHandleKind enum" do
    it "has correct values" do
      Webview::NativeHandleKind::UI_WINDOW.value.should eq(0)
      Webview::NativeHandleKind::UI_WIDGET.value.should eq(1)
      Webview::NativeHandleKind::BROWSER_CONTROLLER.value.should eq(2)
    end
  end

  describe "TypedBinding with 1 parameter" do
    it "converts single parameter correctly" do
      json_val = JSON::Any.new(42_i64)
      result = Webview::TypedBinding.convert_from_json(json_val, Int32)

      result.should eq(42)
      result.should be_a(Int32)
    end
  end

  describe "RAII resource management" do
    it "with_window ensures cleanup" do
      # This test verifies the method signature exists
      # Actual cleanup testing would require integration tests
      typeof(Webview.with_window(800, 600, Webview::SizeHints::NONE, "Test") { |wv| })
    end
  end

  describe "Lifecycle hooks" do
    it "has on_load property" do
      # Just verify the property exists without creating a window (CI-safe)
      typeof(Webview::Webview.allocate.on_load)
    end

    it "has on_navigate property" do
      # Just verify the property exists without creating a window (CI-safe)
      typeof(Webview::Webview.allocate.on_navigate)
    end
  end
end
