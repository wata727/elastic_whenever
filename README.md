# Elastic Whenever

Manage ECS scheduled tasks like whenever gem.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'elastic_whenever'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install elastic_whenever

## Usage

You can use it almost like whenever :)

```
$ elastic_whenever --help
Usage: elastic_whenever [options]
    -i, --update identifier          Clear and create scheduled tasks by schedule file
    -c, --clear identifier           Clear scheduled tasks
    -l, --list identifier            List scheduled tasks
    -s, --set variables              Example: --set 'environment=staging&cluster=ecs-test'
    -f, --file schedule_file         Default: config/schedule.rb
        --profile profile_name       AWS shared profile name
        --access-key aws_access_key_id
                                     AWS access key ID
        --secret-key aws_secret_access_key
                                     AWS secret access key
        --region region              AWS region
    -v, --version                    Print version
```

However, please be aware that you must specify an identifier.

NOTE: Currently, it supports only the syntax of whenever partially. We recommend to check what happens beforehand with the `elastic_whenever` command.

```
$ elastic_whenever
cron(0 3 * * ? *) ecs-test example:2 cron bundle exec rake hoge:run

## [message] Above is your schedule file converted to scheduled tasks; your scheduled tasks was not updated.
## [message] Run `elastic_whenever --help' for more options.
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/wata727/elastic_whenever.
