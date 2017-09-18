require "spec_helper"

RSpec.describe ElasticWhenever::Task::Rule do
  let(:client) { double("client") }
  let(:option) { ElasticWhenever::Option.new(%w(-i test)) }
  before { allow(Aws::CloudWatchEvents::Client).to receive(:new).and_return(client) }

  describe "fetch" do
    before do
      allow(client).to receive(:list_rules).with(name_prefix: "test").and_return(double(rules: [double(name: "example", schedule_expression: "cron(0 0 * * ? *)")]))
    end

    it "fetches rule" do
      rules = ElasticWhenever::Task::Rule.fetch(option)
      expect(rules.count).to eq 1
      expect(rules.first).to have_attributes(name: "example", expression: "cron(0 0 * * ? *)")
    end
  end

  describe "convert" do
    it "converts scheduled task syntax" do
      task = ElasticWhenever::Task.new("production", "0 0 * * ? *")
      task.rake "hoge:run"

      expect(ElasticWhenever::Task::Rule.convert(option, task)).to have_attributes(
                                                                     name: "test_b7ae861e5b0deb3dde12c9a65a179fad6ad36018",
                                                                     expression: "cron(0 0 * * ? *)"
                                                                   )
    end

    it "converts cron syntax" do
      task = ElasticWhenever::Task.new("production", "0 0 * * *")
      task.rake "hoge:run"

      expect(ElasticWhenever::Task::Rule.convert(option, task)).to have_attributes(
                                                                     name: "test_b7ae861e5b0deb3dde12c9a65a179fad6ad36018",
                                                                     expression: "cron(0 0 * * ? *)"
                                                                   )
    end

    it "converts specified week cron syntax" do
      task = ElasticWhenever::Task.new("production", "0 0 * * 0")
      task.rake "hoge:run"

      expect(ElasticWhenever::Task::Rule.convert(option, task)).to have_attributes(
                                                                     name: "test_b7ae861e5b0deb3dde12c9a65a179fad6ad36018",
                                                                     expression: "cron(0 0 ? * 1 *)"
                                                                   )
    end

    it "converts `day` shorthand with `at` option" do
      task = ElasticWhenever::Task.new("production", :day, at: "02:00pm")
      task.rake "hoge:run"

      expect(ElasticWhenever::Task::Rule.convert(option, task)).to have_attributes(
                                                                     name: "test_b7ae861e5b0deb3dde12c9a65a179fad6ad36018",
                                                                     expression: "cron(0 14 * * ? *)"
                                                                   )
    end

    it "converts `hour` shorthand" do
      task = ElasticWhenever::Task.new("production", :hour)
      task.rake "hoge:run"

      expect(ElasticWhenever::Task::Rule.convert(option, task)).to have_attributes(
                                                                     name: "test_b7ae861e5b0deb3dde12c9a65a179fad6ad36018",
                                                                     expression: "cron(0 * * * ? *)"
                                                                   )
    end

    it "converts `month` shorthand" do
      task = ElasticWhenever::Task.new("production", :month, at: "3rd")
      task.rake "hoge:run"

      expect(ElasticWhenever::Task::Rule.convert(option, task)).to have_attributes(
                                                                     name: "test_b7ae861e5b0deb3dde12c9a65a179fad6ad36018",
                                                                     expression: "cron(0 0 3 * ? *)"
                                                                   )
    end

    it "converts `year` shorthand" do
      task = ElasticWhenever::Task.new("production", :year)
      task.rake "hoge:run"

      expect(ElasticWhenever::Task::Rule.convert(option, task)).to have_attributes(
                                                                     name: "test_b7ae861e5b0deb3dde12c9a65a179fad6ad36018",
                                                                     expression: "cron(0 0 1 12 ? *)"
                                                                   )
    end

    it "converts `sunday` shorthand" do
      task = ElasticWhenever::Task.new("production", :sunday)
      task.rake "hoge:run"

      expect(ElasticWhenever::Task::Rule.convert(option, task)).to have_attributes(
                                                                     name: "test_b7ae861e5b0deb3dde12c9a65a179fad6ad36018",
                                                                     expression: "cron(0 0 ? * 1 *)"
                                                                   )
    end

    it "converts `monday` shorthand" do
      task = ElasticWhenever::Task.new("production", :monday, at: "10:00")
      task.rake "hoge:run"

      expect(ElasticWhenever::Task::Rule.convert(option, task)).to have_attributes(
                                                                     name: "test_b7ae861e5b0deb3dde12c9a65a179fad6ad36018",
                                                                     expression: "cron(0 10 ? * 2 *)"
                                                                   )
    end

    it "converts `tuesday` shorthand" do
      task = ElasticWhenever::Task.new("production", :tuesday)
      task.rake "hoge:run"

      expect(ElasticWhenever::Task::Rule.convert(option, task)).to have_attributes(
                                                                     name: "test_b7ae861e5b0deb3dde12c9a65a179fad6ad36018",
                                                                     expression: "cron(0 0 ? * 3 *)"
                                                                   )
    end

    it "converts `wednesday` shorthand" do
      task = ElasticWhenever::Task.new("production", :wednesday)
      task.rake "hoge:run"

      expect(ElasticWhenever::Task::Rule.convert(option, task)).to have_attributes(
                                                                     name: "test_b7ae861e5b0deb3dde12c9a65a179fad6ad36018",
                                                                     expression: "cron(0 0 ? * 4 *)"
                                                                   )
    end

    it "converts `thursday` shorthand" do
      task = ElasticWhenever::Task.new("production", :thursday)
      task.rake "hoge:run"

      expect(ElasticWhenever::Task::Rule.convert(option, task)).to have_attributes(
                                                                     name: "test_b7ae861e5b0deb3dde12c9a65a179fad6ad36018",
                                                                     expression: "cron(0 0 ? * 5 *)"
                                                                   )
    end

    it "converts `friday` shorthand" do
      task = ElasticWhenever::Task.new("production", :friday)
      task.rake "hoge:run"

      expect(ElasticWhenever::Task::Rule.convert(option, task)).to have_attributes(
                                                                     name: "test_b7ae861e5b0deb3dde12c9a65a179fad6ad36018",
                                                                     expression: "cron(0 0 ? * 6 *)"
                                                                   )
    end

    it "converts `saturday` shorthand" do
      task = ElasticWhenever::Task.new("production", :saturday)
      task.rake "hoge:run"

      expect(ElasticWhenever::Task::Rule.convert(option, task)).to have_attributes(
                                                                     name: "test_b7ae861e5b0deb3dde12c9a65a179fad6ad36018",
                                                                     expression: "cron(0 0 ? * 7 *)"
                                                                   )
    end

    it "converts `weekday` shorthand" do
      task = ElasticWhenever::Task.new("production", :weekday)
      task.rake "hoge:run"

      expect(ElasticWhenever::Task::Rule.convert(option, task)).to have_attributes(
                                                                     name: "test_b7ae861e5b0deb3dde12c9a65a179fad6ad36018",
                                                                     expression: "cron(0 0 ? * 2-6 *)"
                                                                   )
    end

    it "converts `weekend` shorthand" do
      task = ElasticWhenever::Task.new("production", :weekend, at: "06:30")
      task.rake "hoge:run"

      expect(ElasticWhenever::Task::Rule.convert(option, task)).to have_attributes(
                                                                     name: "test_b7ae861e5b0deb3dde12c9a65a179fad6ad36018",
                                                                     expression: "cron(30 6 ? * 1,7 *)"
                                                                   )
    end


    it "raise an exception when specify unsupported option" do
      task = ElasticWhenever::Task.new("production", :reboot)
      task.rake "hoge:run"

      expect { ElasticWhenever::Task::Rule.convert(option, task) }.to raise_error(ElasticWhenever::Task::Rule::UnsupportedOptionException)
    end
  end

  describe "#create" do
    it "creates new rule" do
      expect(client).to receive(:put_rule).with(name: "example", schedule_expression: "cron(0 0 * * ? *)", state: "ENABLED")
      ElasticWhenever::Task::Rule.new(option, name: "example", expression: "cron(0 0 * * ? *)").create
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
      ElasticWhenever::Task::Rule.new(option, name: "example", expression: "cron(0 0 * * ? *)").delete
    end
  end
end
