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
                                     expression: "cron(0 3 * * ? *)",
                                     commands: [
                                       %w(bundle exec bin/rails runner -e production Hoge.run)
                                     ]
                                   )
      expect(schedule.tasks[1]).to have_attributes(
                                     expression: "cron(0 0 1 * ? *)",
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

  describe "#schedule_expression" do
    it "converts from schedule expression" do
      expect(schedule.schedule_expression("0 0 * * ? *", {})).to eq "cron(0 0 * * ? *)"
    end

    it "converts from cron syntax" do
      expect(schedule.schedule_expression("0 0 * * *", {})).to eq "cron(0 0 * * ? *)"
    end

    it "converts from cron syntax specified week" do
      expect(schedule.schedule_expression("0 0 * * 0", {})).to eq "cron(0 0 ? * 1 *)"
    end

    it "converts from day shortcuts" do
      expect(schedule.schedule_expression(:day, {})).to eq "cron(0 0 * * ? *)"
    end

    it "converts from day shortcuts with `at` option" do
      expect(schedule.schedule_expression(:day, at: "2:00")).to eq "cron(0 14 * * ? *)"
    end

    it "converts from day shortcuts with `at` option and chronic option" do
      schedule.instance_variable_set(:@chronic_options, { :hours24 => true })
      expect(schedule.schedule_expression(:day, at: "2:00")).to eq "cron(0 2 * * ? *)"
    end

    it "converts from hour shortcuts" do
      expect(schedule.schedule_expression(:hour, {})).to eq "cron(0 * * * ? *)"
    end

    it "converts from month shortcuts with `at` option" do
      expect(schedule.schedule_expression(:month, at: "3rd")).to eq "cron(0 0 3 * ? *)"
    end

    it "converts from year shortcuts" do
      expect(schedule.schedule_expression(:year, {})).to eq "cron(0 0 1 12 ? *)"
    end

    it "converts from sunday shortcuts" do
      expect(schedule.schedule_expression(:sunday, {})).to eq "cron(0 0 ? * 1 *)"
    end

    it "converts from monday shortcuts" do
      expect(schedule.schedule_expression(:monday, {})).to eq "cron(0 0 ? * 2 *)"
    end

    it "converts from tuesday shortcuts" do
      expect(schedule.schedule_expression(:tuesday, {})).to eq "cron(0 0 ? * 3 *)"
    end

    it "converts from wednesday shortcuts" do
      expect(schedule.schedule_expression(:wednesday, {})).to eq "cron(0 0 ? * 4 *)"
    end

    it "converts from thursday shortcuts" do
      expect(schedule.schedule_expression(:thursday, {})).to eq "cron(0 0 ? * 5 *)"
    end

    it "converts from friday shortcuts" do
      expect(schedule.schedule_expression(:friday, {})).to eq "cron(0 0 ? * 6 *)"
    end

    it "converts from saturday shortcuts" do
      expect(schedule.schedule_expression(:saturday, {})).to eq "cron(0 0 ? * 7 *)"
    end

    it "converts from weekday shortcuts" do
      expect(schedule.schedule_expression(:weekday, {})).to eq "cron(0 0 ? * 2-6 *)"
    end

    it "converts from weekend shortcuts with `at` option" do
      expect(schedule.schedule_expression(:weekend, at: "06:30")).to eq "cron(30 6 ? * 1,7 *)"
    end

    it "raises an exception when specified unsupported shortcuts" do
      expect { schedule.schedule_expression(:reboot, {}) }.to raise_error(ElasticWhenever::Schedule::UnsupportedFrequencyException)
    end
  end
end
