module ElasticWhenever
  class Task
    class Role
      NAME = "ecsEventsRole"

      def initialize
        client = Aws::IAM::Client.new
        @resource = Aws::IAM::Resource.new(client: client)
        @role = resource.role(NAME)
      end

      def create
        @role = resource.create_role(
          role_name: NAME,
          assume_role_policy_document: role_json,
        )
        role.attach_policy(
          policy_arn: "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceEventsRole"
        )
      end

      def exists?
        !!role
      end

      def arn
        role&.arn
      end

      private

      attr_reader :resource
      attr_reader :role

      def role_json
        {
          Version: "2012-10-17",
          Statement: [
            {
              Sid: "",
              Effect: "Allow",
              Principal: {
                Service: "events.amazonaws.com",
              },
              Action: "sts:AssumeRole",
            }
          ],
        }.to_json
      end
    end
  end
end