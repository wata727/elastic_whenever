module ElasticWhenever
  class Task
    class Definition
      def initialize(option, family)
        @client = option.ecs_client
        @definition = client.describe_task_definition(
          task_definition: family
        ).task_definition
      end

      def name
        "#{definition.family}:#{definition.revision}" if definition
      end

      def arn
        definition&.task_definition_arn
      end

      def containers
        definition&.container_definitions&.map(&:name)
      end

      private

      attr_reader :client
      attr_reader :definition
    end
  end
end
