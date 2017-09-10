module ElasticWhenever
  class Task
    class Target
      attr_reader :cluster
      attr_reader :definition
      attr_reader :container
      attr_reader :commands

      def self.fetch(rule)
        client = Aws::CloudWatchEvents::Client.new
        target = client.list_targets_by_rule(rule: rule.name).targets.first
        # arn:aws:ecs:us-east-1:<aws_account_id>:task-definition/wordpress:3
        definition_name = target.ecs_parameters.task_definition_arn.match(/arn:aws:ecs:.+:.+:task-definition\/(.+)/)[0]
        input = JSON.parse(target.input, symbolize_names: true)

        self.new(
          cluster: Cluster.new(arn: target.arn),
          definition: Definition.new(definition_name),
          container: input[:containerOverrides].first[:name],
          commands: input[:containerOverrides].first[:command],
          rule: rule,
          role: Role.new
        )
      end

      def initialize(cluster:, definition:, container:, commands:, rule:, role:)
        @cluster = cluster
        @definition = definition
        @container = container
        @commands = commands
        @rule = rule
        @role = role
        @client = Aws::CloudWatchEvents::Client.new
      end

      def create
        client.put_targets(
          rule: rule.name,
          targets: [
            {
              id: rule.name,
              arn: cluster.arn,
              input: input_json(container, commands),
              role_arn: role.arn,
              ecs_parameters: {
                task_definition_arn: definition.arn,
                task_count: 1,
              }
            }
          ]
        )
      end

      private

      def input_json(container, commands)
        {
          containerOverrides: [
            {
              name: container,
              command: commands
            }
          ]
        }.to_json
      end

      attr_reader :rule
      attr_reader :role
      attr_reader :client
    end
  end
end