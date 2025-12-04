require "./spec_helper"

describe Webview::WindowManager do
  describe "window management" do
    it "initializes with empty window list" do
      manager = Webview::WindowManager.new

      manager.count.should eq(0)
      manager.windows.size.should eq(0)
    end

    it "has with_manager class method" do
      # Just verify the method exists without actually creating windows
      typeof(Webview::WindowManager.with_manager { |m| })
    end

    it "has create_window methods with correct signatures" do
      manager = Webview::WindowManager.new

      # Verify method signatures exist (compile-time check)
      typeof(manager.create_window(800, 600, Webview::SizeHints::NONE, "Test"))
      typeof(manager.create_window(800, 600, Webview::SizeHints::NONE, "Test", "http://example.com"))
    end

    it "has management methods" do
      manager = Webview::WindowManager.new

      # Verify methods exist
      typeof(manager.terminate_all)
      typeof(manager.destroy_all)
      typeof(manager.run_sequential)
      typeof(manager.run_all)
    end
  end
end
