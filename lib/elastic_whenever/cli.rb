module ElasticWhenever
  class CLI
    SUCCESS_EXIT_CODE = 0
    ERROR_EXIT_CODE = 1

    class << self
      def run(args)
        option = Option.new(args)
        case option.mode
        when Option::DRYRUN_UPDATE_CRONTAB_MODE
          update_crontab(option, dry_run: true)
          Logger.instance.message("Above is your schedule file converted to scheduled tasks; your scheduled tasks was not updated.")
          Logger.instance.message("Run `elastic_whenever --help' for more options.")
        when Option::UPDATE_CRONTAB_MODE
          update_crontab(option, dry_run: false)
          Logger.instance.log("write", "scheduled tasks updated")
        when Option::CLEAR_CRONTAB_MODE
          clear_crontab(option)
          Logger.instance.log("write", "shceduled tasks")
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

      def update_crontab(option, dry_run:)
        schedule = Schedule.new(option.schedule_file)
        option.variables.each do |var|
          schedule.set(var[:key], var[:value])
        end
        schedule.validate!

        cluster = Task::Cluster.new(schedule.cluster)
        definition = Task::Definition.new(schedule.task_definition)

        role = Task::Role.new
        if !role.exists? && !dry_run
          role.create
        end

        clear_crontab(option) unless dry_run
        schedule.tasks.each do |task|
          rule = Task::Rule.new(task, option)
          target = Task::Target.new(
            cluster: cluster,
            definition: definition,
            container: schedule.container,
            task: task,
            rule: rule,
            role: role,
          )

          if dry_run
            puts "#{rule.expression} #{target.cluster.name} #{target.definition.name} #{target.container} #{target.task.commands.join(" ")}"
            puts
          else
            rule.create
            target.create
          end
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
