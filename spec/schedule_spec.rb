require "spec_helper"

RSpec.describe ElasticWhenever::Schedule do
  let(:schedule) { ElasticWhenever::Schedule.new((Pathname(__dir__) + "fixtures/schedule.rb").to_s, []) }

  describe "#initialize" do
    it "has attributes" do
      expect(schedule).to have_attributes(
                            cluster: "ecs-test",
                            task_definition: "example",
                            container: "cron",
                            chronic_options: {},
                          )
    end

    context "when received variables from cli" do
      let(:schedule) { ElasticWhenever::Schedule.new((Pathname(__dir__) + "fixtures/schedule.rb").to_s, [{ key: "environment", value: "staging" }]) }

      it "overrides attributes" do
        expect(schedule.instance_variable_get(:@environment)).to eq "staging"
      end
    end

    it "has tasks" do
      expect(schedule.tasks.count).to eq(2)
      expect(schedule.tasks[0]).to have_attributes(
                                     frequency: :day,
                                     options: { at: "03:00am" },
                                     commands: [
                                       %w(bundle exec bin/rails runner -e production Hoge.run)
                                     ]
                                   )
      expect(schedule.tasks[1]).to have_attributes(
                                     frequency: "0 0 1 * *",
                                     options: {},
                                     commands: [
                                       %w(bundle exec rake hoge:run --silent),
                                       %w(bundle exec bin/rails runner -e production Fuga.run)
                                     ]
                                   )
    end

    context "when use unsupported method" do
      let(:schedule) { ElasticWhenever::Schedule.new((Pathname(__dir__) + "fixtures/unsupported_schedule.rb").to_s, []) }

      it "does not have tasks" do
        expect(schedule.tasks.count).to eq(0)
      end
    end
  end

  describe "#set" do
    it "sets value" do
      expect {
        schedule.set("container", "original")
      }.to change { schedule.container }.from("cron").to("original")
    end

    it "doesnt set `tasks` value" do
      expect {
        schedule.set("tasks", "some value")
      }.not_to change { schedule.tasks }
    end
  end

  describe "#validate!" do
    it "doesnt raise exception" do
      schedule.validate!
    end

    context "when doesnt set cluster" do
      before { schedule.set("cluster", nil) }

      it "raises exception" do
        expect { schedule.validate! }.to raise_error(ElasticWhenever::Schedule::InvalidScheduleException, "You must set cluster")
      end
    end

    context "when doesnt set task definition" do
      before { schedule.set("task_definition", nil) }

      it "raises exception" do
        expect { schedule.validate! }.to raise_error(ElasticWhenever::Schedule::InvalidScheduleException, "You must set task definition")
      end
    end

    context "when doesnt set container" do
      before { schedule.set("container", nil) }

      it "raises exception" do
        expect { schedule.validate! }.to raise_error(ElasticWhenever::Schedule::InvalidScheduleException, "You must set container")
      end
    end
  end
end
