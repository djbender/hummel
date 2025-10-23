# frozen_string_literal: true

source "https://gem.coop"

gemspec

group :development do
  gem "irb"
  gem "rake", "~> 13.0"
  gem "standard", "~> 1.3"
  gem "byebug"
end

group :development, :test do
  gem "simplecov", "~> 0.22.0"
  gem "rspec", "~> 3.0"
end

group :test do
  gem "lizard", branch: :main, github: "djbender/lizard-ruby", require: false
end
