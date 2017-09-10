module ElasticWhenever
  class Task
    class Cluster
      def initialize(name)
        @client = Aws::ECS::Client.new
        @resp = client.describe_clusters(
          clusters: [name]
        )
      end

      def name
        resp&.clusters&.first&.cluster_name
      end

      def arn
        resp&.clusters&.first&.cluster_arn
      end

      private

      attr_reader :client
      attr_reader :resp
    end
  end
end