## v0.6.0 (2019-10-16)

### Enhancements

- [#46](https://github.com/wata727/elastic_whenever/pull/46): Add option to disable rule ([@tobscher](https://github.com/tobscher))

## v0.5.1 (2019-10-09)

### Enhancements

- [#45](https://github.com/wata727/elastic_whenever/pull/45): Add description to CloudWatch rule ([@tobscher](https://github.com/tobscher))

## v0.5.0 (2019-09-19)

### Enhancements

- [#44](https://github.com/wata727/elastic_whenever/pull/44): Make CloudWatch Events IAM role name configurable ([@domcleal](https://github.com/domcleal))

## v0.4.2 (2019-09-17)

### BugFixes

- [#43](https://github.com/wata727/elastic_whenever/pull/43): Add expression to task rule name hash computation ([@korbin](https://github.com/korbin))

### Chore

- [#42](https://github.com/wata727/elastic_whenever/pull/42): Fix typo in clear task log line ([@HistoireDeBabar](https://github.com/HistoireDeBabar))

## v0.4.1 (2019-07-23)

### BugFixes

- Retry for concurrent modification ([#41](https://github.com/wata727/elastic_whenever/pull/41))

### Chore

- CI against Ruby 2.6 ([#40](https://github.com/wata727/elastic_whenever/pull/40))

## v0.4.0 (2018-12-19)

Elastic Whenever now supports Fargate launch type. Thanks @avinson.

From this release, ECS parameters must be passed as arguments. Previously, it supported schedule file variables, but it will be ignored.

```
# Before
$ elastic_whenever --set 'cluster=ecs-test&task_definition=oneoff-application:2&container=oneoff'

# After
$ elastic_whenever --cluster ecs-test --task-definition oneoff-application:2 --container oneoff
```

### Enhancements

- update elastic_whenever for FARGATE launch type ([#34](https://github.com/wata727/elastic_whenever/pull/34))

### Changes

- Bump aws-sdk-cloudwatchevents dependency ([#36](https://github.com/wata727/elastic_whenever/pull/36))
- Pass ECS params as an argument ([#37](https://github.com/wata727/elastic_whenever/pull/37))

### Chore

- CI against Ruby 2.4.5 and 2.5.3 ([#35](https://github.com/wata727/elastic_whenever/pull/35))
- Set nil as verbose mode ([#38](https://github.com/wata727/elastic_whenever/pull/38))
- Revise task's target ([#39](https://github.com/wata727/elastic_whenever/pull/39))

## v0.3.2 (2018-06-25)

### BugFix

- fix: `Task::Role#exists?` always return true ([#33](https://github.com/wata727/elastic_whenever/pull/33))

## v0.3.1 (2018-06-25)

### BugFix

- add `attr_reader :enviroment` ([#32](https://github.com/wata727/elastic_whenever/pull/32))

### Others

- CI against Ruby 2.5 ([#30](https://github.com/wata727/elastic_whenever/pull/30))
- Use `File.exist?` instead of `File.exists?` ([#31](https://github.com/wata727/elastic_whenever/pull/31))

