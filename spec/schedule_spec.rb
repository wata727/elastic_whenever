require "spec_helper"

RSpec.describe ElasticWhenever::Schedule do
  let(:schedule) { ElasticWhenever::Schedule.new((Pathname(__dir__) + "fixtures/schedule.rb").to_s) }

  describe "#initialize" do
    it "has attributes" do
      expect(schedule).to have_attributes(
                            cluster: "ecs-test",
                            task_definition: "example",
                            container: "cron",
                          )
    end

    it "has tasks" do
      runner_task = ElasticWhenever::Task.new("production", :day, at: "03:00am")
      runner_task.runner("Hoge.run")
      rake_task = ElasticWhenever::Task.new("production", "0 0 1 * *")
      rake_task.rake("hoge:run")

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
                                       %w(bundle exec rake hoge:run --slient),
                                       %w(bundle exec bin/rails runner -e production Fuga.run)
                                     ]
                                   )
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