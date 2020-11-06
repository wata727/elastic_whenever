module ElasticWhenever
  class Task
    class Rule
      attr_reader :option
      attr_reader :name
      attr_reader :expression
      attr_reader :description

      class UnsupportedOptionException < StandardError; end

      def self.fetch(option)
        client = Aws::CloudWatchEvents::Client.new(option.aws_config)
        client.list_rules(name_prefix: option.identifier).rules.map do |rule|
          self.new(
            option,
            name: rule.name,
            expression: rule.schedule_expression,
            description: rule.description,
            client: client
          )
        end
      end

      def self.convert(option, task)
        self.new(
          option,
          name: rule_name(option.identifier, task.expression, task.commands),
          expression: task.expression,
          description: rule_description(option.identifier, task.expression, task.commands)
        )
      end

      def initialize(option, name:, expression:, description:, client: nil)
        @option = option
        @name = name
        @expression = expression
        @description = description
        if client != nil
          puts("using cached client")
          @client = client
        else
          @client = Aws::CloudWatchEvents::Client.new(option.aws_config)
        end
      end

      def create
        # See https://docs.aws.amazon.com/eventbridge/latest/APIReference/API_PutRule.html#API_PutRule_RequestSyntax
        client.put_rule(
          name: name,
          schedule_expression: expression,
          description: truncate(description, 512),
          state: option.rule_state,
        )
      end

      def delete
        targets = client.list_targets_by_rule(rule: name).targets
        client.remove_targets(rule: name, ids: targets.map(&:id)) unless targets.empty?
        client.delete_rule(name: name)
      end

      private

      def self.rule_name(identifier, expression, commands)
        "#{identifier}_#{Digest::SHA1.hexdigest([expression, commands.map { |command| command.join("-") }.join("-")].join("-"))}"
      end

      def self.rule_description(identifier, expression, commands)
        "#{identifier} - #{expression} - #{commands.map { |command| command.join(" ") }.join(" - ")}"
      end

      def truncate(string, max)
        string.length > max ? string[0...max] : string
      end

      attr_reader :client
    end
  end
end
