# hummel

An HUML parser implementation in ruby.

> **Note:** The gem is named `hummel` because `huml` was already taken on rubygems.org.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'hummel'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install hummel
```

## Usage

### Parsing HUML

```ruby
require 'hummel'

huml_string = <<~HUML
  name: "John Doe"
  age: 30
  email: "john@example.com"
HUML

data = Hummel::Decode.parse(huml_string)
# => {"name"=>"John Doe", "age"=>30, "email"=>"john@example.com"}
```

### Encoding to HUML

```ruby
require 'hummel'

data = {
  name: "John Doe",
  age: 30,
  hobbies: ["reading", "coding", "hiking"]
}

huml_string = Hummel::Encode.stringify(data)
puts huml_string
# Output:
# age: 30
# hobbies::
#   - reading
#   - coding
#   - hiking
# name: John Doe
```

### Options

You can include the HUML version header when encoding:

```ruby
Hummel::Encode.stringify(data, include_version: true)
# Output:
# %HUML v0.1.0
#
# age: 30
# ...
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bin/rake install`.

To release a new version:

1. Run tests and linters: `bin/rake` and address any issues in separate commits.
2. Update the version number in `lib/hummel/version.rb`.
3. Update the `CHANGELOG.md` to include this version and brief summaries of changes.
4. Commit changes:

    git add lib/hummel/version.rb CHANGELOG.md
    git commit -m "Bump version to 0.2.0"

5. Run `bin/rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).
6. Create a GitHub Release from the tag with the CHANGELOG.md notes.

**Note**: In follow up commits to this release please re-add the [Unreleased] section to CHANGELOG.md for future work.

**Note**: Make sure you're authed with rubygems.org via `gem signin` before running the release command.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/djbender/hummel. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/djbender/hummel/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Hummel project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/djbender/hummel/blob/main/CODE_OF_CONDUCT.md).
