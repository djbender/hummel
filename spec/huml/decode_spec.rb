require "spec_helper"
require "json"

RSpec.shared_examples "a decoded HUML string" do |test_name, input, error_expected|
  it test_name do
    if error_expected
      expect { Huml::Decode.parse(input) }.to raise_error(Huml::Decode::Error)
    else
      expect { Huml::Decode.parse(input) }.not_to raise_error(Huml::Decode::Error)
    end
  end
end

RSpec.describe Huml::Decode do
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
          huml = Huml::Decode.parse(file.read)
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
end

# no op for now
def normalize_to_json(huml)
  huml
end
