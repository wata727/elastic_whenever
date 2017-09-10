module ElasticWhenever
  class Task
    class Definition
      def initialize(family)
        @client = Aws::ECS::Client.new
        @resp = client.describe_task_definition(
          task_definition: family
        )
      end

      def name
        definition = resp&.task_definition
        "#{definition.family}:#{definition.revision}" if definition
      end

      def arn
        resp&.task_definition&.task_definition_arn
      end

      private

      attr_reader :client
      attr_reader :resp
    end
  end
end