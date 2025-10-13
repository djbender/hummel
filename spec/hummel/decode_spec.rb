require "spec_helper"
require "json"

RSpec.shared_examples "a decoded HUML string" do |test_name, input, error_expected|
  it test_name do
    if error_expected
      expect { Hummel::Decode.parse(input) }.to raise_error(Hummel::Decode::Error)
    else
      expect { Hummel::Decode.parse(input) }.not_to raise_error(Hummel::Decode::Error)
    end
  end
end

RSpec.describe Hummel::Decode do
  context "Assertions" do
    Dir.glob("./tests/assertions/*.json").each do |file_path|
      File.open(file_path) do |file|
        tests = JSON.parse(file.read)
        tests.each_with_index do |test_case, i|
          test_name = "line #{i + 1}: #{test_case.fetch("name")}"
          it_behaves_like "a decoded HUML string", test_name, test_case.fetch("input"), test_case.fetch("error")
        end
      end
    end
  end

  context "Documents" do
    Dir.glob("./tests/documents/*.huml").each do |file_path|
      it "testing #{File.basename(file_path)}" do
        File.open(file_path) do |file|
          huml = Hummel::Decode.parse(file.read)
          normalized_huml = normalize_to_json(huml)

          # read corresponding json file
          json_file_path = file_path.sub(".huml", ".json")
          json = JSON.parse(File.read(json_file_path))

          # deep compare both
          expect(normalized_huml).to eq(json)
        end
      end
    end
  end

  context "Branch coverage tests" do
    it "rejects unsupported HUML version" do
      expect {
        Hummel::Decode.parse("%HUML v0.2.0\ntest")
      }.to raise_error(Hummel::Decode::Error, /unsupported version/)
    end

    it "rejects ':' indicator at document root without key-value pair" do
      expect {
        Hummel::Decode.parse(": value")
      }.to raise_error(Hummel::Decode::Error, /':' indicator not allowed at document root/)
    end

    it "rejects duplicate keys in inline dict" do
      expect {
        Hummel::Decode.parse("foo: 1, foo: 2")
      }.to raise_error(Hummel::Decode::Error, /duplicate key/)
    end

    it "rejects incomplete escape sequence at end of string" do
      expect {
        Hummel::Decode.parse('"test\\')
      }.to raise_error(Hummel::Decode::Error, /incomplete escape sequence/)
    end

    it "rejects multiline string with incorrect closing delimiter indent" do
      expect {
        Hummel::Decode.parse("foo: \"\"\"\n  content\n    \"\"\"")
      }.to raise_error(Hummel::Decode::Error, /multiline closing delimiter must be at same indentation/)
    end

    it "rejects multiple spaces after assert_space context" do
      expect {
        Hummel::Decode.parse("key:  value")
      }.to raise_error(Hummel::Decode::Error, /expected single space.*found multiple/)
    end

    it "rejects spaces before comma in inline collection" do
      expect {
        Hummel::Decode.parse("1 , 2")
      }.to raise_error(Hummel::Decode::Error, /no spaces allowed before comma/)
    end

    it "handles inline dict at root with content on next lines" do
      result = Hummel::Decode.parse("a: 1, b: 2")
      expect(result).to eq({"a" => 1, "b" => 2})
    end

    it "rejects '::' indicator at document root" do
      expect {
        Hummel::Decode.parse(":: value")
      }.to raise_error(Hummel::Decode::Error, /'::' indicator not allowed at document root/)
    end

    it "rejects trailing spaces at end of blank line" do
      expect {
        Hummel::Decode.parse("  ")
      }.to raise_error(Hummel::Decode::Error, /trailing spaces/)
    end

    it "rejects trailing spaces at end of comment" do
      expect {
        Hummel::Decode.parse("1 # comment  \n")
      }.to raise_error(Hummel::Decode::Error, /trailing spaces/)
    end

    it "handles HUML version without space after it" do
      result = Hummel::Decode.parse("%HUML\n\"test\"")
      expect(result).to eq("test")
    end

    it "rejects invalid key in inline dict" do
      expect {
        Hummel::Decode.parse("a: 1, b 2")
      }.to raise_error(Hummel::Decode::Error, /expected ':' in inline dict/)
    end

    it "rejects root value starting with : without key" do
      # This covers line 121 - peek_string(":") && !key_value_pair?
      # When a line starts with : but it's not a valid key-value pair
      expect {
        Hummel::Decode.parse(":nokey")
      }.to raise_error(Hummel::Decode::Error, /':' indicator not allowed/)
    end

    it "handles multiline list at document root" do
      result = Hummel::Decode.parse("- 1\n- 2")
      expect(result).to eq([1, 2])
    end

    it "rejects list item with bad indentation" do
      expect {
        Hummel::Decode.parse("- 1\n  - 2")
      }.to raise_error(Hummel::Decode::Error, /bad indent/)
    end

    it "handles list that breaks with non-dash character" do
      result = Hummel::Decode.parse("- 1\nkey: value")
      expect(result).to eq([1])
    end

    it "rejects missing colon after key in inline dict within vector" do
      expect {
        Hummel::Decode.parse("foo:: a: 1, b 2")
      }.to raise_error(Hummel::Decode::Error, /expected ':' in inline dict/)
    end

    it "rejects line with trailing spaces after content" do
      expect {
        Hummel::Decode.parse("key: 1 # comment  \n")
      }.to raise_error(Hummel::Decode::Error, /trailing spaces/)
    end

    it "rejects missing comma between inline list items" do
      expect {
        Hummel::Decode.parse("foo:: 1x")
      }.to raise_error(Hummel::Decode::Error, /expected a comma/)
    end

    it "handles %HUML without version string" do
      result = Hummel::Decode.parse("%HUML\n1")
      expect(result).to eq(1)
    end

    it "handles inline dict at root without following content" do
      result = Hummel::Decode.parse("a: 1, b: 2")
      expect(result).to eq({"a" => 1, "b" => 2})
    end

    it "rejects inline dict missing comma" do
      expect {
        Hummel::Decode.parse("a: 1 b: 2")
      }.to raise_error(Hummel::Decode::Error)
    end
  end
end

# no op for now
def normalize_to_json(huml)
  huml
end
