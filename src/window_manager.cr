module Webview
  # Multi-window manager for handling multiple webview instances
  class WindowManager
    @windows = [] of Webview

    # Create a new window and add it to the manager
    def create_window(width : Int32, height : Int32, hint : SizeHints, title : String, debug = false)
      wv = Webview.new(debug, title)
      wv.size(width, height, hint)
      wv.title = title
      @windows << wv
      wv
    end

    # Create a new window with URL
    def create_window(width : Int32, height : Int32, hint : SizeHints, title : String, url : String, debug = false)
      wv = Webview.new(debug, title)
      wv.size(width, height, hint)
      wv.title = title
      wv.navigate(url)
      @windows << wv
      wv
    end

    # Run all windows in separate fibers
    # Note: This spawns fibers but returns immediately.
    # The caller needs to keep the main thread alive (e.g., with sleep or another blocking call)
    def run_all
      @windows.each do |wv|
        spawn do
          wv.run
        end
      end
    end

    # Run all windows sequentially (one at a time)
    def run_sequential
      @windows.each(&.run)
    end

    # Terminate all windows
    def terminate_all
      @windows.each do |wv|
        begin
          wv.terminate
        rescue ex
          # Ignore errors during termination
        end
      end
    end

    # Destroy all windows and clean up
    def destroy_all
      @windows.each do |wv|
        begin
          wv.destroy
        rescue ex
          # Ignore errors during cleanup
        end
      end
      @windows.clear
    end

    # Get all managed windows
    def windows
      @windows
    end

    # Get window count
    def count
      @windows.size
    end

    # RAII-style resource management for multiple windows
    def self.with_manager(&)
      manager = new
      begin
        yield manager
      ensure
        manager.destroy_all
      end
    end
  end
end
