# frozen_string_literal: true

require_relative "lib/hummel/version"

Gem::Specification.new do |spec|
  spec.name = "hummel"
  spec.version = Hummel::VERSION
  spec.authors = ["Derek Bender"]
  spec.email = ["170351+djbender@users.noreply.github.com"]

  spec.summary = "A Ruby parser and encoder for HUML (Human Markup Language)"
  spec.description = "HUML (Human Markup Language) is a data serialization format designed for human readability. This gem provides a complete Ruby implementation including a parser for decoding HUML documents and an encoder for converting Ruby objects to HUML format."
  spec.homepage = "https://github.com/djbender/hummel"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["allowed_push_host"] = "https://gem.coop"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/djbender/hummel"
  spec.metadata["changelog_uri"] = "https://github.com/djbender/hummel/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
