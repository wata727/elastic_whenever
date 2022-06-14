# Elastic Whenever
[![Build Status](https://github.com/wata727/elastic_whenever/workflows/build/badge.svg?branch=master)](https://github.com/wata727/elastic_whenever/actions)
[![MIT License](http://img.shields.io/badge/license-MIT-blue.svg?style=flat)](LICENSE.txt)
[![Gem Version](https://badge.fury.io/rb/elastic_whenever.svg)](https://badge.fury.io/rb/elastic_whenever)

Manage ECS scheduled tasks like [Whenever](https://github.com/javan/whenever) gem.

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

You can use it almost like Whenever. However, please be aware that you must specify an identifier.

```
$ elastic_whenever --help
Usage: elastic_whenever [options]
    -i, --update identifier          Clear and create scheduled tasks by schedule file
    -c, --clear identifier           Clear scheduled tasks
    -l, --list identifier            List scheduled tasks
    -s, --set variables              Example: --set 'environment=staging'
        --cluster cluster            ECS cluster to run tasks
        --task-definition task_definition
                                     Task definition name, If omit a revision, use the latest revision of the family automatically. Example: --task-deifinition oneoff-application:2
        --container container        Container name defined in the task definition
        --launch-type launch_type    Launch type. EC2 or FARGATE. Default: EC2
        --assign-public-ip           Assign a public IP. Default: DISABLED (FARGATE only)
        --security-groups groups     Example: --security-groups 'sg-2c503655,sg-72f0cb0a' (FARGATE only)
        --subnets subnets            Example: --subnets 'subnet-4973d63f,subnet-45827d1d' (FARGATE only)
        --platform-version version   Optionally specify the platform version. Default: LATEST (FARGATE only)
    -f, --file schedule_file         Default: config/schedule.rb
        --iam-role name              IAM role name used by CloudWatch Events. Default: ecsEventsRole
        --rule-state state           The state of the CloudWatch Events Rule (ENABLED or DISABLED), default: ENABLED
        --profile profile_name       AWS shared profile name
        --access-key aws_access_key_id
                                     AWS access key ID
        --secret-key aws_secret_access_key
                                     AWS secret access key
        --region region              AWS region
    -v, --version                    Print version
    -V, --verbose                    Run rake jobs without --silent
```

NOTE: Currently, Elastic Whenever supports the Whenever syntax partially. We strongly encourage to use dry-run mode for verifying tasks to be created.

```
$ elastic_whenever --cluster ecs-test --task-definition example:2 --container cron
cron(0 3 * * ? *) ecs-test example:2 cron bundle exec rake hoge:run

## [message] Above is your schedule file converted to scheduled tasks; your scheduled tasks was not updated.
## [message] Run `elastic_whenever --help' for more options.
```

### Setting variables
Elastic Whenever supports setting variables via the `--set` option [as Whenever does](https://github.com/javan/whenever/wiki/Setting-variables-on-the-fly).

Example:

`elastic_whenever --set 'environment=staging&some_var=foo'`

```ruby
if @environment == 'staging'
  every '0 1 * * *' do
    rake 'some_task_on_staging'
  end
elsif @some_var == 'foo'
  every '0 10 * * *' do
    rake 'some_task'
  end
end
```

Especially, `@environment` defaults to `"production"`.

## How it works
Elastic Whenever creates CloudWatch Events for every command. Each rule has a one to one mapping to a target.
for example, the following input will generate two Rules each with one Target.

```ruby
every '0 0 * * *' do
  rake "hoge:run"
  command "awesome"
end
```

The scheduled task's name is a digest value calculated from an identifier, commands, and so on.

NOTE: You should not use the same identifier across different clusters because CloudWatch Events rule names are unique across all clusters.

## Compatibility with Whenever
### `job_type`
Whenever supports custom job type with `job_type` method, but Elastic Whenever doesn't support it.

```ruby
# [warn] Skipping unsupported method: job_type
job_type :awesome, '/usr/local/bin/awesome :task :fun_level'
```

### `env`
Whenever supports environment variables with `env` method, but Elastic Whenever doesn't support it.
You should use task definitions to set environment variables.

```ruby
# [warn] Skipping unsupported method: env
env "VERSION", "v1"
```

### `:job_template`
Whenever has a template to describe as cron, but Elastic Whenever doesn't have the template.
Therefore, `:job_template` option is ignored.

```ruby
set :job_template, "/bin/zsh -l -c ':job'" # ignored
```

### Frequency
Elastic Whenever processes frequency passed to `every` block almost like Whenever.

```ruby
# Whenever
#   0 15 * * * /bin/bash -l -c 'cd /home/user/app && RAILS_ENV=production bundle exec rake hoge:run --silent'
#
# Elastic Whenever
#   cron(0 15 * * ? *) ecs-test myapp:2 web bundle exec rake hoge:run --silent
#
every :day, at: "3:00" do
  rake "hoge:run"
end

# Whenever
#   0,10,20,30,40,50 * * * * /bin/bash -l -c 'awesome'
#
# Elastic Whenever
#   cron(0,10,20,30,40,50 * * * ? *) ecs-test myapp:2 web awesome
#
every 10.minutes do
  command "awesome"
end
```

However, handling of the day of week is partially different because it follows scheduled expression.

```ruby
# Whenever
#   0 0 * * 1 /bin/bash -l -c 'awesome'
#
# Elastic Whenever
#   cron(0 0 ? * 2 *) ecs-test myapp:2 web awesome
#
every :monday do
  command "awesome"
end
```

Therefore, cron syntax is converted to scheduled expression like the following:

```ruby
# cron(0 0 ? * 2 *) ecs-test myapp:2 web awesome
every "0 0 * * 1" do
  command "awesome"
end
```

Absolutely, you can also write scheduled expression.

```ruby
# cron(0 0 ? * 2 *) ecs-test myapp:2 web awesome
every "0 0 ? * 2 *" do
  command "awesome"
end
```

#### `:reboot`
Whenever supports `:reboot` as a cron option, but Elastic Whenever doesn't support it.

```ruby
# [warn] `reboot` is not supported option. Ignore this task.
every :reboot do
  rake "hoge:run"
end
```

### Bundle commands
Whenever checks if the application uses bundler and automatically adds a prefix to commands.
However, Elastic Whenever always adds a prefix on a premise that the application is using bundler.

```ruby
# Whenever
#   With bundler    -> bundle exec rake hoge:run
#   Without bundler -> rake hoge:run
#
# Elastic Whenever
#   bundle exec rake hoge:run
#
rake "hoge:run"
```

If you don't want to add the prefix, set `bundle_command` to empty as follows:

```ruby
set :bundle_command, ""
```

### Rails
Whenever supports `runner` job with old Rails versions, but Elastic Whenever supports Rails 4 and above only.

```ruby
# Whenever
#   Before them -> script/runner Hoge.run
#   Rails 3     -> script/rails runner Hoge.run
#   Rails 4     -> bin/rails runner Hoge.run
#
# Elastic Whenever
#   bin/rails runner Hoge.run
#
runner "Hoge.run"
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/wata727/elastic_whenever.
