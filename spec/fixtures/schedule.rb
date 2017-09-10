set :cluster, 'ecs-test'
set :task_definition, 'example'
set :container, 'cron'

every :day, at: '03:00am' do
  runner 'Hoge.run'
end

every '0 0 1 * *' do
  rake 'hoge:run'
  runner 'Fuga.run'
end
