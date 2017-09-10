module ElasticWhenever
  class Task
    class Rule
      attr_reader :name
      attr_reader :expression

      def self.fetch(identifier)
        client = Aws::CloudWatchEvents::Client.new
        client.list_rules(name_prefix: identifier).rules.map do |rule|
          self.new(
            name: rule.name,
            expression: rule.schedule_expression,
          )
        end
      end

      def self.convert(task, option)
        self.new(
          name: rule_name(option.identifier, task.commands),
          expression: schedule_expression(task.frequency, task.options)
        )
      end

      def initialize(name:, expression:)
        @name = name
        @expression = expression
        @client = Aws::CloudWatchEvents::Client.new
      end

      def create
        client.put_rule(
          name: name,
          schedule_expression: expression,
          state: "ENABLED",
        )
      end

      def delete
        client.remove_targets(rule: name, ids: [name])
        client.delete_rule(name: name)
      end

      private

      def self.rule_name(identifier, commands)
        "#{identifier}_#{Digest::SHA1.hexdigest(commands.join("-"))}"
      end

      def self.schedule_expression(frequency, options)
        time = Chronic.parse(options[:at]) || Time.new(2017, 9, 9, 0, 0, 0)

        case frequency
        when :hour
          "cron(#{time.hour} * * * ? *)"
        when :day
          "cron(#{time.min} #{time.hour} * * ? *)"
        else
          min, hour, day, mon, week, year = frequency.split(" ")
          week.gsub!("*", "?")
          year = year || "*"
          "cron(#{min} #{hour} #{day} #{mon} #{week} #{year})"
        end
      end

      attr_reader :client
    end
  end
end
