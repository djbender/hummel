require "spec_helper"
require "json"

RSpec.describe Huml::Encode do
  context "TestEncodeDoc" do
    it "encodes and re-parses mixed.huml correctly" do
      # Read source data as HUML
      huml_content = File.read("./tests/documents/mixed.huml")
      res_huml = Huml::Decode.parse(huml_content)

      # Marshal it back to HUML
      encoded = Huml::Encode.stringify(res_huml)

      # Read it again using the HUML parser
      res_huml_converted = Huml::Decode.parse(encoded)
      out = normalize_to_json(res_huml_converted)

      # Read test.json and parse it
      json_content = File.read("./tests/documents/mixed.json")
      res_json = JSON.parse(json_content)

      # Deep compare both
      expect(out).to eq(res_json)
    end
  end
end

def normalize_to_json(obj)
  return nil if obj.nil?

  if obj.is_a?(Numeric)
    return nil if obj.respond_to?(:nan?) && obj.nan?
    return nil if obj.respond_to?(:infinite?) && obj.infinite?
    return obj
  end

  if obj.is_a?(Array)
    return obj.map { |item| normalize_to_json(item) }
  end

  if obj.is_a?(Hash)
    result = {}
    obj.each do |key, value|
      result[key] = normalize_to_json(value)
    end
    return result
  end

  obj
end
