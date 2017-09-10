module ElasticWhenever
  class Task
    class Cluster
      class InvalidInputException < StandardError; end

      def initialize(name: nil, arn: nil)
        raise InvalidInputException.new("Either name or arn must be specified") if !name && !arn
        @client = Aws::ECS::Client.new
        # "arn:aws:ecs:us-east-1:<aws_account_id>:cluster/default"
        name = arn.match(/arn:aws:ecs:.+:.+:cluster\/(.+)/)[0] if arn
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