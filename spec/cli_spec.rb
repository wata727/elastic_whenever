require "spec_helper"

RSpec.describe ElasticWhenever::CLI do
  describe "run" do
    let(:task) do
      ElasticWhenever::Task.new("production", "bundle exec", "0 0 * * ? *").tap do |task|
        task.runner("Hoge.run")
      end
    end
    let(:schedule) do
      double(
        environment: "production",
        cluster: "test",
        task_definition: "wordpress:2",
        container: "testContainer",
        chronic_options: {},
        tasks: [task]
      )
    end
    let(:cluster) { double(arn: "arn:aws:ecs:us-east-1:123456789:cluster/test", name: "test") }
    let(:definition) { double(arn: "arn:aws:ecs:us-east-1:123456789:task-definition/wordpress:2", name: "wordpress:2") }
    let(:role) { double(arn: "arn:aws:ecs:us-east-1:123456789:role/testRole") }
    before do
      allow(ElasticWhenever::Schedule).to receive(:new).with((Pathname(__dir__) + "fixtures/schedule.rb").to_s, kind_of(Array)).and_return(schedule)
      allow(ElasticWhenever::Task::Cluster).to receive(:new).with(kind_of(ElasticWhenever::Option), "test").and_return(cluster)
      allow(ElasticWhenever::Task::Definition).to receive(:new).with(kind_of(ElasticWhenever::Option), "wordpress:2").and_return(definition)
      allow(ElasticWhenever::Task::Role).to receive(:new).with(kind_of(ElasticWhenever::Option)).and_return(role)
      allow(schedule).to receive(:validate!)
      allow(role).to receive(:exists?).and_return(false)
    end

    context "with dry run mode" do
      it "updates tasks with dry run" do
        expect(role).not_to receive(:create)
        expect(ElasticWhenever::CLI).not_to receive(:clear_tasks)
        expect_any_instance_of(ElasticWhenever::Task::Rule).not_to receive(:create)
        expect_any_instance_of(ElasticWhenever::Task::Target).not_to receive(:create)

        expect {
          ElasticWhenever::CLI.run(%W(--region us-east-1 -f #{(Pathname(__dir__) + "fixtures/schedule.rb").to_s}))
        }.to output(<<~OUTPUT).to_stdout
          cron(0 0 * * ? *) test wordpress:2 testContainer bundle exec bin/rails runner -e production Hoge.run

          ## [message] Above is your schedule file converted to scheduled tasks; your scheduled tasks was not updated.
          ## [message] Run `elastic_whenever --help' for more options.
        OUTPUT
      end

      it "retruns success status code" do
        expect(ElasticWhenever::CLI.run(%W(--region us-east-1 -f #{(Pathname(__dir__) + "fixtures/schedule.rb").to_s}))).to eq ElasticWhenever::CLI::SUCCESS_EXIT_CODE
      end

      context "when validation is failed" do
        before { allow(schedule).to receive(:validate!).and_raise(ElasticWhenever::Schedule::InvalidScheduleException) }

        it "returns error status code" do
          expect(ElasticWhenever::CLI.run(%W(--region us-east-1 -f #{(Pathname(__dir__) + "fixtures/schedule.rb").to_s}))).to eq ElasticWhenever::CLI::ERROR_EXIT_CODE
        end
      end
    end

    context "with update mode" do
      before do
        allow(role).to receive(:create)
        allow(ElasticWhenever::CLI).to receive(:clear_tasks).with(kind_of(ElasticWhenever::Option))
        allow_any_instance_of(ElasticWhenever::Task::Rule).to receive(:create)
        allow_any_instance_of(ElasticWhenever::Task::Target).to receive(:create)
      end

      it "updates tasks and returns success status code" do
        expect(role).to receive(:create)
        expect(ElasticWhenever::CLI).to receive(:clear_tasks).with(kind_of(ElasticWhenever::Option))
        expect_any_instance_of(ElasticWhenever::Task::Rule).to receive(:create)
        expect_any_instance_of(ElasticWhenever::Task::Target).to receive(:create)

        expect(ElasticWhenever::CLI.run(%W(-i test --region us-east-1 -f #{(Pathname(__dir__) + "fixtures/schedule.rb").to_s}))).to eq ElasticWhenever::CLI::SUCCESS_EXIT_CODE
      end

      it "receives schedule file name and variables" do
        expect(ElasticWhenever::Schedule).to receive(:new).with((Pathname(__dir__) + "fixtures/schedule.rb").to_s, [{ key: "environment", value: "staging" }, { key: "cluster", value: "ecs-test" }])

        ElasticWhenever::CLI.run(%W(-i test --set environment=staging&cluster=ecs-test --region us-east-1 -f #{(Pathname(__dir__) + "fixtures/schedule.rb").to_s}))
      end

      context "when validation is failed" do
        before { allow(schedule).to receive(:validate!).and_raise(ElasticWhenever::Schedule::InvalidScheduleException) }

        it "returns error status code" do
          expect(ElasticWhenever::CLI.run(%W(-i test --region us-east-1 -f #{(Pathname(__dir__) + "fixtures/schedule.rb").to_s}))).to eq ElasticWhenever::CLI::ERROR_EXIT_CODE
        end
      end

      context "when raises unsupported exception" do
        before { allow(ElasticWhenever::Task::Rule).to receive(:convert).and_raise(ElasticWhenever::Task::Rule::UnsupportedOptionException) }

        it "does not create tasks" do
          expect_any_instance_of(ElasticWhenever::Task::Rule).not_to receive(:create)
          expect_any_instance_of(ElasticWhenever::Task::Target).not_to receive(:create)

          ElasticWhenever::CLI.run(%W(-i test --region us-east-1 -f #{(Pathname(__dir__) + "fixtures/schedule.rb").to_s}))
        end
      end
    end

    context "with clear mode" do
      let(:rule) { double("Rule") }

      it "clear tasks" do
        expect(ElasticWhenever::Task::Rule).to receive(:fetch).with(kind_of(ElasticWhenever::Option)).and_return([rule])
        expect(rule).to receive(:delete)

        expect(ElasticWhenever::CLI.run(%W(-c test --region us-east-1 -f #{(Pathname(__dir__) + "fixtures/schedule.rb").to_s}))).to eq ElasticWhenever::CLI::SUCCESS_EXIT_CODE
      end
    end

    context "with list mode" do
      let(:rule) { double(expression: "cron(0 0 * * ? *)") }
      let(:target) do
        double(
          cluster: cluster,
          definition: definition,
          container: "testContainer",
          commands: ["bundle", "exec", "bin/rails", "runner", "-e", "production", "Hoge.run"]
        )
      end

      before do
        allow(ElasticWhenever::Task::Rule).to receive(:fetch).with(kind_of(ElasticWhenever::Option)).and_return([rule])
        allow(ElasticWhenever::Task::Target).to receive(:fetch).with(kind_of(ElasticWhenever::Option), rule).and_return([target])
      end

      it "lists tasks" do
        expect {
          ElasticWhenever::CLI.run(%W(-l test --region us-east-1 -f #{(Pathname(__dir__) + "fixtures/schedule.rb").to_s}))
        }.to output(<<~OUTPUT).to_stdout
          cron(0 0 * * ? *) test wordpress:2 testContainer bundle exec bin/rails runner -e production Hoge.run

          ## [message] Above is your scheduled tasks.
          ## [message] Run `elastic_whenever --help` for more options.
        OUTPUT
      end
    end

    context "with print version mode" do
      it "prints version" do
        expect {
          ElasticWhenever::CLI.run(%w(-v))
        }.to output("Elastic Whenever v#{ElasticWhenever::VERSION}\n").to_stdout
      end
    end
  end
end
