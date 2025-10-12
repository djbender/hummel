# frozen_string_literal: true

require "huml"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
  config.raise_errors_for_deprecations!
  # disable warning on potential false positives
  RSpec::Expectations.configuration.warn_about_potential_false_positives = false
end
