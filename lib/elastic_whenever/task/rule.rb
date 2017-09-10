module ElasticWhenever
  class Task
    class Rule
      attr_reader :name
      attr_reader :expression

      def self.delete(identifier)
        client = Aws::CloudWatchEvents::Client.new
        client.list_rules(name_prefix: identifier).rules.each do |rule|
          client.remove_targets(rule: rule.name, ids: [rule.name])
          client.delete_rule(name: rule.name)
        end
      end

      def initialize(task, option)
        @name = rule_name(option.identifier, task.commands)
        @expression = schedule_expression(task.frequency, task.options)
        @client = Aws::CloudWatchEvents::Client.new
        @rule = client.describe_rule(name: name)
      rescue Aws::CloudWatchEvents::Errors::ResourceNotFoundException
        @rule = nil
      end

      def create
        client.put_rule(
          name: name,
          schedule_expression: expression,
          state: "ENABLED",
        )
        @rule = client.describe_rule(name: name)
      end

      def exists?
        !!rule
      end

      private

      def rule_name(identifier, commands)
        "#{identifier}_#{Digest::SHA1.hexdigest(commands.join("-"))}"
      end

      def schedule_expression(frequency, options)
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
      attr_reader :rule
    end
  end
end
