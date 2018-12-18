require "spec_helper"

RSpec.describe ElasticWhenever::Schedule do
  let(:schedule) { ElasticWhenever::Schedule.new((Pathname(__dir__) + "fixtures/schedule.rb").to_s, false, []) }

  describe "#initialize" do
    it "has attributes" do
      expect(schedule).to have_attributes(chronic_options: {})
    end

    context "when received variables from cli" do
      let(:schedule) { ElasticWhenever::Schedule.new((Pathname(__dir__) + "fixtures/schedule.rb").to_s, false, [{ key: "environment", value: "staging" }]) }

      it "overrides attributes" do
        expect(schedule.instance_variable_get(:@environment)).to eq "staging"
      end
    end

    context "when received verbose from cli" do
      let(:schedule) { ElasticWhenever::Schedule.new((Pathname(__dir__) + "fixtures/schedule.rb").to_s, true, []) }

      it "set verbose flag" do
        expect(schedule.instance_variable_get(:@verbose)).to be true
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
      let(:schedule) { ElasticWhenever::Schedule.new((Pathname(__dir__) + "fixtures/unsupported_schedule.rb").to_s, false, []) }

      it "does not have tasks" do
        expect(schedule.tasks.count).to eq(0)
      end
    end
  end

  describe "WheneverNumeric" do
    before do
      allow(File).to receive(:read).and_return(file)
    end

    context "when use 1.minute" do
      let(:file) do
        <<~FILE
          every 1.minute do
            rake "hoge:run"
          end
        FILE
      end

      it "has expression" do
        expect(schedule.tasks.first).to have_attributes(expression: "cron(* * * * ? *)")
      end
    end

    context "when use 5.minutes" do
      let(:file) do
        <<~FILE
          every 5.minutes do
            rake "hoge:run"
          end
        FILE
      end

      it "has expression" do
        expect(schedule.tasks.first).to have_attributes(expression: "cron(0,5,10,15,20,25,30,35,40,45,50,55 * * * ? *)")
      end
    end

    context "when use 21.minutes" do
      let(:file) do
        <<~FILE
          every 21.minutes do
            rake "hoge:run"
          end
        FILE
      end

      it "has expression" do
        expect(schedule.tasks.first).to have_attributes(expression: "cron(21,42 * * * ? *)")
      end
    end

    context "when use 120.minutes" do
      let(:file) do
        <<~FILE
          every 120.minutes do
            rake "hoge:run"
          end
        FILE
      end

      it "has expression" do
        expect(schedule.tasks.first).to have_attributes(expression: "cron(0 0,2,4,6,8,10,12,14,16,18,20,22 * * ? *)")
      end
    end

    context "when use 1.hour" do
      let(:file) do
        <<~FILE
          every 1.hour do
            rake "hoge:run"
          end
        FILE
      end

      it "has expression" do
        expect(schedule.tasks.first).to have_attributes(expression: "cron(0 * * * ? *)")
      end
    end

    context "when use 4.hours" do
      let(:file) do
        <<~FILE
          every 4.hours do
            rake "hoge:run"
          end
        FILE
      end

      it "has expression" do
        expect(schedule.tasks.first).to have_attributes(expression: "cron(0 0,4,8,12,16,20 * * ? *)")
      end
    end

    context "when use 11.hours" do
      let(:file) do
        <<~FILE
          every 11.hours do
            rake "hoge:run"
          end
        FILE
      end

      it "has expression" do
        expect(schedule.tasks.first).to have_attributes(expression: "cron(0 11,22 * * ? *)")
      end
    end

    context "when use 1.day" do
      let(:file) do
        <<~FILE
          every 1.day do
            rake "hoge:run"
          end
        FILE
      end

      it "has expression" do
        expect(schedule.tasks.first).to have_attributes(expression: "cron(0 0 * * ? *)")
      end
    end

    context "when use 10.days" do
      let(:file) do
        <<~FILE
          every 10.days do
            rake "hoge:run"
          end
        FILE
      end

      it "has expression" do
        expect(schedule.tasks.first).to have_attributes(expression: "cron(0 0 1,11,21 * ? *)")
      end
    end

    context "when use 17.days" do
      let(:file) do
        <<~FILE
          every 17.days do
            rake "hoge:run"
          end
        FILE
      end

      it "has expression" do
        expect(schedule.tasks.first).to have_attributes(expression: "cron(0 0 17 * ? *)")
      end
    end

    context "when use 1.month" do
      let(:file) do
        <<~FILE
          every 1.month do
            rake "hoge:run"
          end
        FILE
      end

      it "has expression" do
        expect(schedule.tasks.first).to have_attributes(expression: "cron(0 0 1 * ? *)")
      end
    end

    context "when use 2.months" do
      let(:file) do
        <<~FILE
          every 2.months do
            rake "hoge:run"
          end
        FILE
      end

      it "has expression" do
        expect(schedule.tasks.first).to have_attributes(expression: "cron(0 0 1 1,3,5,7,9,11 ? *)")
      end
    end

    context "when use 2.months with `at` option" do
      let(:file) do
        <<~FILE
          every 2.months, :at => "3:00" do
            rake "hoge:run"
          end
        FILE
      end

      it "has expression" do
        expect(schedule.tasks.first).to have_attributes(expression: "cron(0 15 1 1,3,5,7,9,11 ? *)")
      end
    end

    context "when use 7.months" do
      let(:file) do
        <<~FILE
          every 7.months do
            rake "hoge:run"
          end
        FILE
      end

      it "has expression" do
        expect(schedule.tasks.first).to have_attributes(expression: "cron(0 0 1 7 ? *)")
      end
    end

    context "when use 1.year" do
      let(:file) do
        <<~FILE
          every 1.year do
            rake "hoge:run"
          end
        FILE
      end

      it "has expression" do
        expect(schedule.tasks.first).to have_attributes(expression: "cron(0 0 1 12 ? *)")
      end
    end
  end

  describe "#set" do
    it "sets value" do
      expect {
        schedule.set("foo", "bar")
      }.to change { schedule.instance_variable_get("@foo") }.from(nil).to("bar")
    end

    it "doesnt set `tasks` value" do
      expect {
        schedule.set("tasks", "some value")
      }.not_to change { schedule.tasks }
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
