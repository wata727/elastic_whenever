module ElasticWhenever
  class Task
    class Target
      attr_reader :cluster
      attr_reader :definition
      attr_reader :container
      attr_reader :commands
      attr_reader :assign_public_ip
      attr_reader :launch_type
      attr_reader :platform_version
      attr_reader :security_groups
      attr_reader :subnets

      class InvalidContainerException < StandardError; end

      def self.fetch(option, rule)
        client = Aws::CloudWatchEvents::Client.new(option.aws_config)
        targets = client.list_targets_by_rule(rule: rule.name).targets
        targets.map do |target|
          input = JSON.parse(target.input, symbolize_names: true)

          self.new(
            option,
            cluster: Cluster.new(option, target.arn),
            definition: Definition.new(option, target.ecs_parameters.task_definition_arn),
            container: input[:containerOverrides].first[:name],
            commands: input[:containerOverrides].first[:command],
            rule: rule,
            role: Role.new(option)
          )
        end
      end

      def initialize(option, cluster:, definition:, container:, commands:, rule:, role:)
        unless definition.containers.include?(container)
          raise InvalidContainerException.new("#{container} is invalid container. valid=#{definition.containers.join(",")}")
        end

        @cluster = cluster
        @definition = definition
        @container = container
        @commands = commands
        @rule = rule
        @role = role
        @assign_public_ip = option.assign_public_ip
        @launch_type = option.launch_type
        @platform_version = option.platform_version
        @security_groups = option.security_groups
        @subnets = option.subnets
        @state_machine_arn = option.state_machine_arn
        @client = Aws::CloudWatchEvents::Client.new(option.aws_config)
      end

      def create
        if @state_machine_arn
          client.put_targets(
            rule: rule.name,
            targets: [
              {
                id: Digest::SHA1.hexdigest(commands.join("-")),
                arn: @state_machine_arn,
                # revision番号を取り除く
                input: { "task-def": definition.arn.gsub(/:\d+$/, ''), commands: commands }.to_json,
                role_arn: role.arn,
              }
            ]
          )
        else
          client.put_targets(
            rule: rule.name,
            targets: [
              {
                id: Digest::SHA1.hexdigest(commands.join("-")),
                arn: cluster.arn,
                input: input_json(container, commands),
                role_arn: role.arn,
                ecs_parameters: ecs_parameters,
              }
            ]
          )
        end
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

      def ecs_parameters
        if launch_type == "FARGATE"
          {
            launch_type: launch_type,
            task_definition_arn: definition.arn,
            task_count: 1,
            network_configuration: {
              awsvpc_configuration: {
                subnets: subnets,
                security_groups: security_groups,
                assign_public_ip: assign_public_ip,
              }
            },
            platform_version: platform_version,
          }
        else
          {
            launch_type: launch_type,
            task_definition_arn: definition.arn,
            task_count: 1,
          }
        end
      end

      attr_reader :rule
      attr_reader :role
      attr_reader :client
    end
  end
end
