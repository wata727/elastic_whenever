set :cluster, 'ecs-test'
set :task_definition, 'example'
set :container, 'cron'

job_type :awesome, '/usr/local/bin/awesome :task :fun_level'
