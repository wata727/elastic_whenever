module ElasticWhenever
  class CLI
    SUCCESS_EXIT_CODE = 0
    ERROR_EXIT_CODE = 1

    class << self
      def run(args)
        option = Option.new(args)
        case option.mode
        when Option::DRYRUN_MODE
          option.validate!
          update_tasks(option, dry_run: true)
          Logger.instance.message("Above is your schedule file converted to scheduled tasks; your scheduled tasks was not updated.")
          Logger.instance.message("Run `elastic_whenever --help' for more options.")
        when Option::UPDATE_MODE
          option.validate!
          update_tasks(option, dry_run: false)
          Logger.instance.log("write", "scheduled tasks updated")
        when Option::CLEAR_MODE
          clear_tasks(option)
          Logger.instance.log("write", "shceduled tasks cleared")
        when Option::LIST_MODE
          list_tasks(option)
          Logger.instance.message("Above is your scheduled tasks.")
          Logger.instance.message("Run `elastic_whenever --help` for more options.")
        when Option::PRINT_VERSION_MODE
          print_version
        end

        SUCCESS_EXIT_CODE
      rescue OptionParser::MissingArgument,
        Option::InvalidOptionException,
        Schedule::InvalidScheduleException,
        Aws::Errors::MissingCredentialsError => exn

        Logger.instance.fail(exn.message)
        ERROR_EXIT_CODE
      end

      private

      def update_tasks(option, dry_run:)
        schedule = Schedule.new(option.schedule_file)
        option.variables.each do |var|
          schedule.set(var[:key], var[:value])
        end
        schedule.validate!

        cluster = Task::Cluster.new(option, schedule.cluster)
        definition = Task::Definition.new(option, schedule.task_definition)
        role = Task::Role.new(option)
        if !role.exists? && !dry_run
          role.create
        end

        clear_tasks(option) unless dry_run
        schedule.tasks.each do |task|
          rule = Task::Rule.convert(option, task)
          targets = task.commands.map do |command|
            Task::Target.new(
              option,
              cluster: cluster,
              definition: definition,
              container: schedule.container,
              commands: command,
              rule: rule,
              role: role,
            )
          end

          if dry_run
            print_task(rule, targets)
          else
            rule.create
            targets.each(&:create)
          end
        end
      end

      def clear_tasks(option)
        Task::Rule.fetch(option).each(&:delete)
      end

      def list_tasks(option)
        Task::Rule.fetch(option).each do |rule|
          target = Task::Target.fetch(option, rule)
          print_task(rule, target)
        end
      end

      def print_version
        puts "Elastic Whenever v#{ElasticWhenever::VERSION}"
      end

      def print_task(rule, targets)
        targets.each do |target|
          puts "#{rule.expression} #{target.cluster.name} #{target.definition.name} #{target.container} #{target.commands.join(" ")}"
          puts
        end
      end
    end
  end
end
