module ElasticWhenever
  class CLI
    class << self
      def run(args)
        option = Option.new(args)
        case option.mode
        when Option::UPDATE_CRONTAB_MODE
          update_crontab(option)
        when Option::PRINT_VERSION_MODE
          version
        end
      end

      def version
        puts "Elastic Whenever v#{ElasticWhenever::VERSION}"
      end

      def update_crontab(option)
        schedule = Schedule.new("config/schedule.rb")
        option.variables.each do |var|
          schedule.set(var[:key], var[:value])
        end

        cluster = Task::Cluster.new(schedule.cluster)
        definition = Task::Definition.new(schedule.task_definition)

        role = Task::Role.new
        unless role.exists?
          role.create
        end

        schedule.tasks.each do |task|
          rule = Task::Rule.new(task, option).create
          Task::Target.new(
            cluster: cluster,
            definition: definition,
            container: schedule.container,
            task: task,
            rule: rule,
            role: role,
          ).create
        end
      end
    end
  end
end
