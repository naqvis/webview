require "./spec_helper"

describe "Webview::TypedBinding" do
  describe "convert_from_json" do
    it "converts JSON to Int32" do
      json_val = JSON::Any.new(42_i64)
      result = Webview::TypedBinding.convert_from_json(json_val, Int32)

      result.should eq(42)
      result.should be_a(Int32)
    end

    it "converts JSON to Int64" do
      json_val = JSON::Any.new(1000000000_i64)
      result = Webview::TypedBinding.convert_from_json(json_val, Int64)

      result.should eq(1000000000_i64)
      result.should be_a(Int64)
    end

    it "converts JSON to Float64" do
      json_val = JSON::Any.new(3.14)
      result = Webview::TypedBinding.convert_from_json(json_val, Float64)

      result.should be_close(3.14, 0.001)
      result.should be_a(Float64)
    end

    it "converts JSON to String" do
      json_val = JSON::Any.new("hello")
      result = Webview::TypedBinding.convert_from_json(json_val, String)

      result.should eq("hello")
      result.should be_a(String)
    end

    it "converts JSON to Bool" do
      json_val = JSON::Any.new(true)
      result = Webview::TypedBinding.convert_from_json(json_val, Bool)

      result.should eq(true)
      result.should be_a(Bool)
    end

    it "handles zero values" do
      json_val = JSON::Any.new(0_i64)
      result = Webview::TypedBinding.convert_from_json(json_val, Int32)

      result.should eq(0)
    end

    it "handles negative numbers" do
      json_val = JSON::Any.new(-42_i64)
      result = Webview::TypedBinding.convert_from_json(json_val, Int32)

      result.should eq(-42)
    end

    it "handles empty strings" do
      json_val = JSON::Any.new("")
      result = Webview::TypedBinding.convert_from_json(json_val, String)

      result.should eq("")
    end

    it "handles large numbers" do
      json_val = JSON::Any.new(1000000000_i64)
      result = Webview::TypedBinding.convert_from_json(json_val, Int64)

      result.should eq(1000000000_i64)
    end
  end

  describe "convert_to_json" do
    it "converts Int32 to JSON::Any" do
      result = Webview::TypedBinding.convert_to_json(42)

      result.should be_a(JSON::Any)
      result.as_i.should eq(42)
    end

    it "converts String to JSON::Any" do
      result = Webview::TypedBinding.convert_to_json("hello")

      result.should be_a(JSON::Any)
      result.as_s.should eq("hello")
    end

    it "converts Bool to JSON::Any" do
      result = Webview::TypedBinding.convert_to_json(true)

      result.should be_a(JSON::Any)
      result.as_bool.should eq(true)
    end

    it "converts Float64 to JSON::Any" do
      result = Webview::TypedBinding.convert_to_json(3.14)

      result.should be_a(JSON::Any)
      result.as_f.should be_close(3.14, 0.001)
    end

    it "converts nil to JSON::Any" do
      result = Webview::TypedBinding.convert_to_json(nil)

      result.should be_a(JSON::Any)
      result.raw.should be_nil
    end
  end
end

describe "Webview::Webview#bind_typed" do
  describe "type-safe bindings" do
    it "validates argument count for 2 parameters" do
      # This would be tested in integration, but we can verify the signature exists
      # by checking it compiles
      typeof(Webview::Webview.new(false, "test").bind_typed("test", Int32, Int32) { |a, b| a + b })
    end

    it "validates argument count for 3 parameters" do
      # This would be tested in integration, but we can verify the signature exists
      typeof(Webview::Webview.new(false, "test").bind_typed("test", Int32, String, Bool) { |a, b, c| "#{a}-#{b}-#{c}" })
    end
  end

  describe "error handling" do
    it "raises TypeCastError on type mismatch" do
      json_val = JSON::Any.new("not a number")

      expect_raises(TypeCastError) do
        Webview::TypedBinding.convert_from_json(json_val, Int32)
      end
    end
  end

  describe "complex scenarios" do
    it "handles chained operations with multiple types" do
      a = Webview::TypedBinding.convert_from_json(JSON::Any.new(10_i64), Int32)
      b = Webview::TypedBinding.convert_from_json(JSON::Any.new(5_i64), Int32)
      c = Webview::TypedBinding.convert_from_json(JSON::Any.new(2_i64), Int32)
      result = (a + b) * c

      result.should eq(30)
    end

    it "handles string formatting with numbers" do
      count = Webview::TypedBinding.convert_from_json(JSON::Any.new(42_i64), Int32)
      label = Webview::TypedBinding.convert_from_json(JSON::Any.new("items"), String)
      result = "You have #{count} #{label}"

      result.should eq("You have 42 items")
    end

    it "handles boolean logic combinations" do
      a = Webview::TypedBinding.convert_from_json(JSON::Any.new(true), Bool)
      b = Webview::TypedBinding.convert_from_json(JSON::Any.new(true), Bool)
      c = Webview::TypedBinding.convert_from_json(JSON::Any.new(false), Bool)
      result = (a && b) || c

      result.should eq(true)
    end

    it "handles floating point precision" do
      a = Webview::TypedBinding.convert_from_json(JSON::Any.new(3.14159), Float64)
      b = Webview::TypedBinding.convert_from_json(JSON::Any.new(2.71828), Float64)
      result = a + b

      result.should be_close(5.85987, 0.00001)
    end
  end
end
