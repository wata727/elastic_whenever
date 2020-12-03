module ElasticWhenever
  class Task
    class Cluster
      class InvalidInputException < StandardError; end

      def initialize(option, name)
        @client = option.ecs_client
        @cluster = client.describe_clusters(
          clusters: [name]
        ).clusters.first
      end

      def name
        cluster.cluster_name
      end

      def arn
        cluster.cluster_arn
      end

      private

      attr_reader :client
      attr_reader :cluster
    end
  end
end