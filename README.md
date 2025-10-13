# hummel

An HUML parser implementation in ruby.

> **Note:** The gem is named `hummel` because `huml` was already taken on rubygems.org.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'hummel', source: 'https://gem.coop'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install hummel --source https://gem.coop
```

## Usage

### Parsing HUML

```ruby
require 'hummel'

huml_string = <<~HUML
  name: John Doe
  age: 30
  email: john@example.com
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

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [gem.coop](https://gem.coop).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/djbender/hummel. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/djbender/hummel/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Hummel project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/djbender/hummel/blob/main/CODE_OF_CONDUCT.md).
