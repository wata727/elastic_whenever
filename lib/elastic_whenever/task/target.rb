module ElasticWhenever
  class Task
    class Target
      attr_reader :cluster
      attr_reader :definition
      attr_reader :container
      attr_reader :task

      def initialize(cluster:, definition:, container:, task:, rule:, role:)
        @cluster = cluster
        @definition = definition
        @container = container
        @task = task
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
              input: input_json(container, task.commands),
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