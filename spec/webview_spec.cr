require "./spec_helper"

describe Webview do
  it "has a version number" do
    Webview::VERSION.should be_a(String)
  end
end
