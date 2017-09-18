module ElasticWhenever
  class Task
    class Rule
      attr_reader :name
      attr_reader :expression

      class UnsupportedOptionException < StandardError; end

      def self.fetch(option)
        client = Aws::CloudWatchEvents::Client.new(option.aws_config)
        client.list_rules(name_prefix: option.identifier).rules.map do |rule|
          self.new(
            option,
            name: rule.name,
            expression: rule.schedule_expression,
          )
        end
      end

      def self.convert(option, task)
        self.new(
          option,
          name: rule_name(option.identifier, task.commands),
          expression: schedule_expression(task.frequency, task.options)
        )
      end

      def initialize(option, name:, expression:)
        @name = name
        @expression = expression
        @client = Aws::CloudWatchEvents::Client.new(option.aws_config)
      end

      def create
        client.put_rule(
          name: name,
          schedule_expression: expression,
          state: "ENABLED",
        )
      end

      def delete
        targets = client.list_targets_by_rule(rule: name).targets
        client.remove_targets(rule: name, ids: targets.map(&:id)) unless targets.empty?
        client.delete_rule(name: name)
      end

      private

      def self.rule_name(identifier, commands)
        "#{identifier}_#{Digest::SHA1.hexdigest(commands.map { |command| command.join("-") }.join("-"))}"
      end

      def self.schedule_expression(frequency, options)
        time = Chronic.parse(options[:at]) || Time.new(2017, 12, 1, 0, 0, 0)

        case frequency
        when :hour
          "cron(#{time.min} * * * ? *)"
        when :day
          "cron(#{time.min} #{time.hour} * * ? *)"
        when :month
          "cron(#{time.min} #{time.hour} #{time.day} * ? *)"
        when :year
          "cron(#{time.min} #{time.hour} #{time.day} #{time.month} ? *)"
        when :sunday
          "cron(#{time.min} #{time.hour} ? * 1 *)"
        when :monday
          "cron(#{time.min} #{time.hour} ? * 2 *)"
        when :tuesday
          "cron(#{time.min} #{time.hour} ? * 3 *)"
        when :wednesday
          "cron(#{time.min} #{time.hour} ? * 4 *)"
        when :thursday
          "cron(#{time.min} #{time.hour} ? * 5 *)"
        when :friday
          "cron(#{time.min} #{time.hour} ? * 6 *)"
        when :saturday
          "cron(#{time.min} #{time.hour} ? * 7 *)"
        when :weekend
          "cron(#{time.min} #{time.hour} ? * 1,7 *)"
        when :weekday
          "cron(#{time.min} #{time.hour} ? * 2-6 *)"
        when /^((\*?\??[\d\/,\-]*)\s*){5,6}$/
          min, hour, day, mon, week, year = frequency.split(" ")
          week.gsub!("*", "?")
          year = year || "*"
          "cron(#{min} #{hour} #{day} #{mon} #{week} #{year})"
        else
          raise UnsupportedOptionException.new("`#{frequency}` is not supported option. Ignore this task.")
        end
      end

      attr_reader :client
    end
  end
end
