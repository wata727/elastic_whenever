require "spec_helper"

RSpec.describe ElasticWhenever::Task::Rule do
  let(:client) { double("client") }
  let(:option) { ElasticWhenever::Option.new(%w(-i test)) }
  before { allow(Aws::CloudWatchEvents::Client).to receive(:new).and_return(client) }

  describe "fetch" do
    before do
      allow(client).to receive(:list_rules).with(name_prefix: "test").and_return(double(rules: [double(name: "example", schedule_expression: "cron(0 0 * * ? *)", description: "test")]))
    end

    it "fetches rule" do
      rules = ElasticWhenever::Task::Rule.fetch(option)
      expect(rules.count).to eq 1
      expect(rules.first).to have_attributes(name: "example", expression: "cron(0 0 * * ? *)")
    end
  end

  describe "convert" do
    it "converts scheduled task syntax" do
      task = ElasticWhenever::Task.new("production", false, "bundle exec", "cron(0 0 * * ? *)")
      task.rake "hoge:run"
      task.rake "command:foo"

      expect(ElasticWhenever::Task::Rule.convert(option, task.expression, task.commands.first)).to have_attributes(
                                                                     name: "test_6a6abf21a362cde702bd39f4679704598fad7ead",
                                                                     expression: "cron(0 0 * * ? *)",
                                                                     description: "test - cron(0 0 * * ? *) - bundle exec rake hoge:run --silent"
                                                                   )
    end
  end

  describe "#create" do
    it "creates new rule" do
      expect(client).to receive(:put_rule).with(name: "example", schedule_expression: "cron(0 0 * * ? *)", description: "test", state: "ENABLED")
      ElasticWhenever::Task::Rule.new(option, name: "example", expression: "cron(0 0 * * ? *)", description: "test").create
    end

    it "truncates the description at 512 characters" do
      expect(client).to receive(:put_rule).with(name: "example", schedule_expression: "cron(0 0 * * ? *)", description: "a" * 512, state: "ENABLED")
      ElasticWhenever::Task::Rule.new(option, name: "example", expression: "cron(0 0 * * ? *)", description: "a" * 600).create
    end

    context "with custom rule state" do
      let(:option) { ElasticWhenever::Option.new(%w(-i test --rule-state DISABLED)) }

      it "uses the rule state when creating the rule" do
        expect(client).to receive(:put_rule).with(name: "example", schedule_expression: "cron(0 0 * * ? *)", description: "test", state: "DISABLED")
        ElasticWhenever::Task::Rule.new(option, name: "example", expression: "cron(0 0 * * ? *)", description: "test").create
      end
    end
  end

  describe "#delete" do
    let(:targets) { [double(id: "example_id")] }
    before do
      allow(client).to receive(:list_targets_by_rule).with(rule: "example").and_return(double(targets: targets))
    end

    it "remove rule and targets" do
      expect(client).to receive(:remove_targets).with(rule: "example", ids: ["example_id"])
      expect(client).to receive(:delete_rule).with(name: "example")
      ElasticWhenever::Task::Rule.new(option, name: "example", expression: "cron(0 0 * * ? *)", description: "test").delete
    end
  end
end
