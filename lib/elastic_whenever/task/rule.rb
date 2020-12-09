module ElasticWhenever
  class Task
    class Rule
      attr_reader :option
      attr_reader :name
      attr_reader :expression
      attr_reader :description

      class UnsupportedOptionException < StandardError; end

      def self.fetch(option)
        client = option.cloudwatch_events_client
        Logger.instance.message("Fetching Rules for #{option.identifier}")
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

      def self.convert(option, expression, command)
        self.new(
          option,
          name: rule_name(option, expression, command),
          expression: expression,
          description: rule_description(option.identifier, expression, command)
        )
      end

      def initialize(option, name:, expression:, description:, client: nil)
        @option = option
        @name = name
        @expression = expression
        @description = description
        if client != nil
          @client = client
        else
          @client = option.cloudwatch_events_client
        end
      end

      def create
        # See https://docs.aws.amazon.com/eventbridge/latest/APIReference/API_PutRule.html#API_PutRule_RequestSyntax
        Logger.instance.message("Creating Rule: #{name} #{expression}")
        client.put_rule(
          name: name,
          schedule_expression: expression,
          description: truncate(description, 512),
          state: option.rule_state,
        )
      end

      def delete
        Logger.instance.message("Listing Targets by Rule: #{name}")
        targets = client.list_targets_by_rule(rule: name).targets
        Logger.instance.message("Removing Targets") unless targets.empty?
        client.remove_targets(rule: name, ids: targets.map(&:id)) unless targets.empty?
        Logger.instance.message("Removing Rule: #{name}")
        client.delete_rule(name: name)
      end

      private

      def self.rule_name(option, expression, command)
        "#{option.identifier}_#{Digest::SHA1.hexdigest([option.key, expression, command.join("-")].join("-"))}"
      end

      def self.rule_description(identifier, expression, command)
        "#{identifier} - #{expression} - #{command.join(" ")}"
      end

      def truncate(string, max)
        string.length > max ? string[0...max] : string
      end

      attr_reader :client
    end
  end
end
