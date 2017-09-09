module ElasticWhenever
  class CLI
    SUCCESS_EXIT_CODE = 0
    ERROR_EXIT_CODE = 1

    class << self
      def run(args)
        option = Option.new(args)
        case option.mode
        when Option::UPDATE_CRONTAB_MODE
          update_crontab(option)
        when Option::CLEAR_CRONTAB_MODE
          clear_crontab(option)
        when Option::PRINT_VERSION_MODE
          print_version
        end

        SUCCESS_EXIT_CODE
      rescue Option::InvalidOptionException,
        Schedule::InvalidScheduleException => exn
        Logger.instance.fail(exn.message)
        ERROR_EXIT_CODE
      end

      private

      def update_crontab(option)
        schedule = Schedule.new(option.schedule_file)
        option.variables.each do |var|
          schedule.set(var[:key], var[:value])
        end
        schedule.validate!

        cluster = Task::Cluster.new(schedule.cluster)
        definition = Task::Definition.new(schedule.task_definition)

        role = Task::Role.new
        unless role.exists?
          role.create
        end

        clear_crontab(option)
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

      def clear_crontab(option)
        Task::Rule.delete(option.identifier)
      end

      def print_version
        puts "Elastic Whenever v#{ElasticWhenever::VERSION}"
      end
    end
  end
end
