# Rbsfmt

The formatter for RBS.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rbsfmt'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install rbsfmt

## Usage

NOTE: It requires ruby-signature as a gem.

```bash
# Print formatted code
$ rbsfmt path/to/*.rbs

# Override file with formatted code
$ rbsfmt path/to/*.rbs -w
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

### Testing

Basically you can use `rake test`.

```bash
$ bundle exec rake test
```

We have smoke tests under `smoke/` directory.
It checks only `.rbs` files do not changed by rbsfmt.
You can execute the smoke test with `bin/smoke`.

```bash
$ bin/smoke smoke/alias.rbs
smoke/alias.rbs ⭕
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/pocke/rbsfmt.

