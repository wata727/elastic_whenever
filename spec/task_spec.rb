require "spec_helper"

RSpec.describe ElasticWhenever::Task do
  let(:task) { ElasticWhenever::Task.new("production", false, "bundle exec", "cron(0 17 * * ? *)") }

  describe "#initialize" do
    it "has attributes" do
      expect(task).to have_attributes(expression: "cron(0 17 * * ? *)")
    end
  end

  describe "#command" do
    it "generates commands" do
      task.command("hoge fuga bar:baz")
      expect(task.commands).to eq([%w(hoge fuga bar:baz)])
    end
  end

  describe "#rake" do
    it "generates rake commands" do
      task.rake("hoge:run")
      expect(task.commands).to eq([%w(bundle exec rake hoge:run --silent)])
    end

    context "when unset bundle command" do
      let(:task) { ElasticWhenever::Task.new("production", false, "", "cron(0 17 * * ? *)") }

      it "generates rake commands" do
        task.rake("hoge:run")
        expect(task.commands).to eq([%w(rake hoge:run --silent)])
      end
    end

    context "when set verbose flag" do
      let(:task) { ElasticWhenever::Task.new("production", true, "bundle exec", "cron(0 17 * * ? *)") }

      it "generates rake commands" do
        task.rake("hoge:run")
        expect(task.commands).to eq([%w(bundle exec rake hoge:run)])
      end
    end
  end

  describe "#runner" do
    it "generates rails runner commands" do
      task.runner("Hoge.run")
      expect(task.commands).to eq([%w(bundle exec bin/rails runner -e production Hoge.run)])
    end

    context "when unset bundle command" do
      let(:task) { ElasticWhenever::Task.new("production", false, "", "cron(0 17 * * ? *)") }

      it "generates rake commands" do
        task.runner("Hoge.run")
        expect(task.commands).to eq([%w(bin/rails runner -e production Hoge.run)])
      end
    end
  end

  describe "script" do
    it "generates script commands" do
      task.script("runner.rb")
      expect(task.commands).to eq([%w(bundle exec script/runner.rb)])
    end

    context "when unset bundle command" do
      let(:task) { ElasticWhenever::Task.new("production", false, "", "cron(0 17 * * ? *)") }

      it "generates rake commands" do
        task.script("runner.rb")
        expect(task.commands).to eq([%w(script/runner.rb)])
      end
    end
  end

  describe "unsupported method" do
    it "does not change commands" do
      expect {
        task.unsupported("hoge")
      }.not_to change { task.commands }
    end
  end
end
