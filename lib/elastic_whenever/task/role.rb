module ElasticWhenever
  class Task
    class Role
      def initialize(option)
        client = Aws::IAM::Client.new(option.aws_config)
        @resource = Aws::IAM::Resource.new(client: client)
        @role_name = option.iam_role
        @role = resource.role(@role_name)
      end

      def create
        @role = resource.create_role(
          role_name: @role_name,
          assume_role_policy_document: role_json,
        )
        role.attach_policy(
          policy_arn: "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceEventsRole"
        )
      end

      def exists?
        !!arn
      rescue Aws::IAM::Errors::NoSuchEntity
        false
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
