require "spec_helper"

RSpec.describe ElasticWhenever::Task::Role do
  let(:resource) { double("resource") }
  let(:option) { ElasticWhenever::Option.new(%w(--region us-east-1)) }
  let(:role) { double(arn: "arn:aws:iam::123456789:role/ecsEventsRole") }

  before do
    allow(Aws::IAM::Resource).to receive(:new).and_return(resource)
    allow(resource).to receive(:role).with(ElasticWhenever::Task::Role::NAME).and_return(role)
  end

  describe "#initialize" do
    it "has role" do
      expect(ElasticWhenever::Task::Role.new(option)).to have_attributes(arn: "arn:aws:iam::123456789:role/ecsEventsRole")
    end
  end

  describe "#create" do
    it "creates IAM role" do
      expect(resource).to receive(:create_role).with({
                                                       role_name: ElasticWhenever::Task::Role::NAME,
                                                       assume_role_policy_document: {
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
                                                     }).and_return(role)
      expect(role).to receive(:attach_policy).with(policy_arn: "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceEventsRole")

      role = ElasticWhenever::Task::Role.new(option)
      role.create
    end
  end

  describe "#exists?" do
    it "returns true" do
      expect(ElasticWhenever::Task::Role.new(option)).to be_exists
    end

    context "when role not found" do
      before do
        allow(resource).to receive(:role).with(ElasticWhenever::Task::Role::NAME).and_return(nil)
      end

      it "returns false" do
        expect(ElasticWhenever::Task::Role.new(option)).not_to be_exists
      end
    end
    context "when role not found (deloay load)" do
      before do
        allow(role).to receive(:arn).and_raise(Aws::IAM::Errors::NoSuchEntity.new('context','error'))
      end

      it "returns false" do
        expect(ElasticWhenever::Task::Role.new(option)).not_to be_exists
      end
    end
  end
end
