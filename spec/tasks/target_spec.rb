require "spec_helper"

RSpec.describe ElasticWhenever::Task::Target do
  let(:client) { double("client") }
  let(:option) { ElasticWhenever::Option.new(%w(-i test)) }
  let(:rule) { double(name: "test_rule") }
  let(:cluster) { double(arn: "arn:aws:ecs:us-east-1:123456789:cluster/test") }
  let(:definition) { double(arn: "arn:aws:ecs:us-east-1:123456789:task-definition/wordpress:2", containers: ["testContainer"]) }
  let(:role) { double(arn: "arn:aws:ecs:us-east-1:123456789:role/testRole") }

  before do
    allow(Aws::CloudWatchEvents::Client).to receive(:new).and_return(client)
  end

  describe "#initialize" do
    it "raises exception" do
      expect {
        ElasticWhenever::Task::Target.new(
          option,
          cluster: cluster,
          definition: definition,
          container: "invalidContainer",
          commands: ["bundle", "exec", "rake", "spec"],
          rule: rule,
          role: role,
        )
      }.to raise_error(ElasticWhenever::Task::Target::InvalidContainerException)
    end
  end

  describe "fetch" do
    let(:targets) do
      [
        double(
          input: {
            containerOverrides: [
              {
                name: "testContainer",
                command: ["bundle", "exec", "rake", "spec"]
              }
            ]
          }.to_json,
          arn: "arn:aws:ecs:us-east-1:123456789:cluster/test",
          ecs_parameters: double(task_definition_arn: "arn:aws:ecs:us-east-1:123456789:task-definition/wordpress:2")
        )
      ]
    end
    before do
      allow(ElasticWhenever::Task::Cluster).to receive(:new).with(option, "arn:aws:ecs:us-east-1:123456789:cluster/test").and_return(cluster)
      allow(ElasticWhenever::Task::Definition).to receive(:new).with(option, "arn:aws:ecs:us-east-1:123456789:task-definition/wordpress:2").and_return(definition)
      allow(ElasticWhenever::Task::Role).to receive(:new).with(option).and_return(role)
    end

    it "fetch targets" do
      expect(client).to receive(:list_targets_by_rule).with(rule: "test_rule").and_return(double(targets: targets))
      whenever_targets = ElasticWhenever::Task::Target.fetch(option, rule)
      expect(whenever_targets.count).to eq 1
      expect(whenever_targets.first).to have_attributes(
                                          cluster: cluster,
                                          definition: definition,
                                          container: "testContainer",
                                          commands: ["bundle", "exec", "rake", "spec"],
                                        )
    end
  end

  describe "#create" do
    it "creates target" do
      expect(client).to receive(:put_targets).with(
        rule: "test_rule",
        targets: [
          {
            id: "26d98175755bb458e8ba55a1f5cfb2dc0e10dd81",
            arn: "arn:aws:ecs:us-east-1:123456789:cluster/test",
            input: {
              containerOverrides: [
                {
                  name: "testContainer",
                  command: ["bundle", "exec", "rake", "spec"]
                }
              ]
            }.to_json,
            role_arn: "arn:aws:ecs:us-east-1:123456789:role/testRole",
            ecs_parameters: {
              launch_type: "EC2",
              task_definition_arn: "arn:aws:ecs:us-east-1:123456789:task-definition/wordpress:2",
              task_count: 1,
            }
          }
        ]
      )

      ElasticWhenever::Task::Target.new(
        option,
        cluster: cluster,
        definition: definition,
        container: "testContainer",
        commands: ["bundle", "exec", "rake", "spec"],
        rule: rule,
        role: role,
      ).create
    end

    context "when FARGATE launch type" do
      let(:option) do
        ElasticWhenever::Option.new(%w(
          -i test
          --launch-type FARGATE
          --platform-version LATEST
          --subnets subnet-4973d63f,subnet-45827d1d
          --security-groups sg-2c503655,sg-72f0cb0a
          --assign-public-ip
        ))
      end

      it "creates target" do
        expect(client).to receive(:put_targets).with(
          rule: "test_rule",
          targets: [
            {
              id: "26d98175755bb458e8ba55a1f5cfb2dc0e10dd81",
              arn: "arn:aws:ecs:us-east-1:123456789:cluster/test",
              input: {
                containerOverrides: [
                  {
                    name: "testContainer",
                    command: ["bundle", "exec", "rake", "spec"]
                  }
                ]
              }.to_json,
              role_arn: "arn:aws:ecs:us-east-1:123456789:role/testRole",
              ecs_parameters: {
                launch_type: "FARGATE",
                task_definition_arn: "arn:aws:ecs:us-east-1:123456789:task-definition/wordpress:2",
                task_count: 1,
                network_configuration: {
                  awsvpc_configuration: {
                    subnets: ["subnet-4973d63f", "subnet-45827d1d"],
                    security_groups: ["sg-2c503655", "sg-72f0cb0a"],
                    assign_public_ip: "ENABLED",
                  }
                },
                platform_version: "LATEST",
              }
            }
          ]
        )

        ElasticWhenever::Task::Target.new(
          option,
          cluster: cluster,
          definition: definition,
          container: "testContainer",
          commands: ["bundle", "exec", "rake", "spec"],
          rule: rule,
          role: role,
        ).create
      end
    end
  end
end
