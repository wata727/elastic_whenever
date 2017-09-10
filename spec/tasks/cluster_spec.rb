require "spec_helper"

RSpec.describe ElasticWhenever::Task::Cluster do
  describe "cluster attributes" do
    let(:client) { double("client") }
    let(:option) { ElasticWhenever::Option.new(nil) }
    let(:cluster) { double(cluster_name: "ecs-test", cluster_arn: "arn:aws:ecs:us-east-1:1234567890:cluster/ecs-test") }

    before do
      allow(Aws::ECS::Client).to receive(:new).and_return(client)
      allow(client).to receive(:describe_clusters).with(clusters: ["ecs-test"]).and_return(double(clusters: [cluster]))
    end

    it "has cluster" do
      expect(ElasticWhenever::Task::Cluster.new(option, "ecs-test")).to have_attributes(
                                                                                name: "ecs-test",
                                                                                arn: "arn:aws:ecs:us-east-1:1234567890:cluster/ecs-test",
                                                                              )
    end
  end
end