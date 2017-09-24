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

However, please be aware that you must specify an identifier. Also, you must specify the cluster, task definition and container name in schedule file.

```ruby
set :cluster, 'ecs-test' # ECS cluster name
set :task_definition, 'oneoff-application:2' # Task definition name, If omit the revision, use the latest revision of family automatically.
set :container, 'oneoff' # Container name of task definition

every :day, at: '03:00am' do
  runner 'Hoge.run'
end
```

If you do not write it in the schedule file, specify it with arguments.

```
$ elastic_whenever -i test --set 'environment=staging&cluster=ecs-test&task_definition=oneoff-application:2&container=oneoff'
```

NOTE: Currently, it supports only the syntax of whenever partially. We recommend to check what happens beforehand with the `elastic_whenever` command.

```
$ elastic_whenever
cron(0 3 * * ? *) ecs-test example:2 cron bundle exec rake hoge:run

## [message] Above is your schedule file converted to scheduled tasks; your scheduled tasks was not updated.
## [message] Run `elastic_whenever --help' for more options.
```

## How it works
Elastic Whenever creates CloudWatch Events as many as `every` block. The number of jobs declared in it corresponds to the target.

```ruby
every '0 0 * * *' do # scheduled task (identifier_68237a3b152a6c44359e1cf5cd8e7cf0def303d7)
  rake "hoge:run"    # target for `identifier_68237a3b152a6c44359e1cf5cd8e7cf0def303d7`
  command "awesome"  # target for `identifier_68237a3b152a6c44359e1cf5cd8e7cf0def303d7`
end
```

The name of the scheduled task is the identifier passed in CLI and the digest value calculated from the command etc.
Because CloudWatch Events rule names are unique across all clusters, you should not use the same identifier across different clusters.

## Compatible with Whenever
### `job_type` method is not supported
Whenever supports custom job type using `job_type` method, but Elastic Whenever does not support it.

```ruby
# [warn] Skipping unsupported method: job_type
job_type :awesome, '/usr/local/bin/awesome :task :fun_level'
```

### `env` method is not supported
Whenever supports environment variables using `env` method, but Elastic Whenever does not support it.
You should use task definitions to set environment variables.

```ruby
# [warn] Skipping unsupported method: env
env "VERSION", "v1"
```

### `:job_template` option is not supported.
Whenever has a template to describe as cron, but Elastic Whenever does not have the template.
Therefore, `:job_template` option is ignored.

```ruby
set :job_template, "/bin/zsh -l -c ':job'" # ignored
```

### Behavior of frequency
Elastic Whenever processes the frequency received by `every` block almost like whenever.

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

However, handling of the day of week is partially different because it follows the scheduled expression.

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

Therefore, the cron syntax is converted to scheduled tasks.

```ruby
# cron(0 0 ? * 2 *) ecs-test myapp:2 web awesome
every "0 0 * * 1" do
  command "awesome"
end
```

Of course, you can write the scheduled expression.

```ruby
# cron(0 0 ? * 2 *) ecs-test myapp:2 web awesome
every "0 0 ? * 2 *" do
  command "awesome"
end
```

#### `:reboot` option is not supported
Whenever supports `:reboot` which is a function of cron, but Elastic Whenever does not support it.

```ruby
# [warn] `reboot` is not supported option. Ignore this task.
every :reboot do
  rake "hoge:run"
end
```

### Behavior of bundle commands
Whenever checks if the application uses bundler and automatically adds the prefix to commands.
However, Elastic Whenever always adds the prefix on the premise that the application is using bundler.

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

### Drop support for for Rails 3 or below
Whenever supports `runner` job with old Rails version, but Elastic Whenever supports Rails 4 and above only.

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
