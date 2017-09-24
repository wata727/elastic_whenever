require "spec_helper"

RSpec.describe ElasticWhenever::Task::Definition do
  describe "definition attributes" do
    let(:client) { double("client") }
    let(:option) { ElasticWhenever::Option.new(nil) }
    let(:definition) do
      double(
        task_definition_arn: "arn:aws:ecs:us-east-1:1234567890:task_definition/wordpress:1",
        family: "wordpress",
        revision: 1,
        container_definitions: [double(name: "testContainer")]
      )
    end

    before do
      allow(Aws::ECS::Client).to receive(:new).and_return(client)
      allow(client).to receive(:describe_task_definition).with(task_definition: "wordpress").and_return(double(task_definition: definition))
    end

    it "has task definition" do
      expect(ElasticWhenever::Task::Definition.new(option, "wordpress")).to have_attributes(
                                                                              name: "wordpress:1",
                                                                              arn: "arn:aws:ecs:us-east-1:1234567890:task_definition/wordpress:1",
                                                                              containers: ["testContainer"]
                                                                            )
    end
  end
end
