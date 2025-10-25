# frozen_string_literal: true

require "simplecov"
if ENV.fetch("LIZARD_API_KEY", false) && ENV.fetch("LIZARD_URL", false)
  require "lizard"
end

SimpleCov.start do
  enable_coverage :branch
  add_filter "/spec/"
end

require "hummel"

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

  if ENV.fetch("LIZARD_API_KEY", false) && ENV.fetch("LIZARD_URL", false)
    config.add_formatter(Lizard::RSpecFormatter)
  end
end
