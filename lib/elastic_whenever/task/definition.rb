module ElasticWhenever
  class Task
    class Definition
      def initialize(option, family)
        @client = option.ecs_client
        @family = family
        @definition = client.describe_task_definition(
          task_definition: family
        ).task_definition
      end

      def name
        "#{definition.family}:#{definition.revision}" if definition
      end

      def arn
        arn = definition&.task_definition_arn
        if family_with_revision?
          arn
        else
          remove_revision(arn)
        end
      end

      def containers
        definition&.container_definitions&.map(&:name)
      end

      private

      attr_reader :client
      attr_reader :definition

      def family_with_revision?
        @family.include?(":")
      end

      def remove_revision(arn)
        arn.split(":")[0...-1].join(":")
      end
    end
  end
end
