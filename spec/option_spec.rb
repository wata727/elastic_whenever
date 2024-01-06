require "spec_helper"

RSpec.describe ElasticWhenever::Option do
  describe "#initialize" do
    it "has default config" do
      expect(ElasticWhenever::Option.new(nil)).to have_attributes(
                                                    identifier: nil,
                                                    mode: ElasticWhenever::Option::DRYRUN_MODE,
                                                    verbose: false,
                                                    assign_public_ip: 'DISABLED',
                                                    launch_type: 'EC2',
                                                    platform_version: 'LATEST',
                                                    variables: [],
                                                    subnets: [],
                                                    security_groups: [],
                                                    schedule_file: "config/schedule.rb",
                                                    iam_role: "ecsEventsRole",
                                                    rule_state: "ENABLED"
                                                  )
    end

    it "has custom config" do
      expect(
        ElasticWhenever::Option.new(%w(
          --set environment=staging&foo=bar
          -f custom_schedule.rb
          --cluster test
          --task-definition wordpress:2
          --container testContainer
          --launch_type FARGATE
          --assign-public-ip
          --security-groups sg-2c503655,sg-72f0cb0a
          --subnets subnet-4973d63f,subnet-45827d1d
          --platform-version 1.1.0
          --verbose
          --rule_state DISABLED
        ))
      ).to have_attributes(
        identifier: nil,
        mode: ElasticWhenever::Option::DRYRUN_MODE,
        verbose: true,
        assign_public_ip: 'ENABLED',
        launch_type: 'FARGATE',
        platform_version: '1.1.0',
        variables: [
          { key: "environment", value: "staging" },
          { key: "foo", value: "bar" },
        ],
        subnets: ["subnet-4973d63f", "subnet-45827d1d"],
        security_groups: ["sg-2c503655", "sg-72f0cb0a"],
        schedule_file: "custom_schedule.rb",
        iam_role: "ecsEventsRole",
        rule_state: "DISABLED"
      )
    end

    it "has update config" do
      expect(ElasticWhenever::Option.new(%w(-i elastic-whenever))).to have_attributes(
                                                                        identifier: "elastic-whenever",
                                                                        mode: ElasticWhenever::Option::UPDATE_MODE,
                                                                        variables: [],
                                                                        schedule_file: "config/schedule.rb"
                                                                      )
    end

    it "has clear config" do
      expect(ElasticWhenever::Option.new(%w(-c elastic-whenever))).to have_attributes(
                                                                        identifier: "elastic-whenever",
                                                                        mode: ElasticWhenever::Option::CLEAR_MODE,
                                                                        variables: [],
                                                                        schedule_file: "config/schedule.rb"
                                                                      )
    end

    it "has list config" do
      expect(ElasticWhenever::Option.new(%w(-l elastic-whenever))).to have_attributes(
                                                                        identifier: "elastic-whenever",
                                                                        mode: ElasticWhenever::Option::LIST_MODE,
                                                                        variables: [],
                                                                        schedule_file: "config/schedule.rb"
                                                                      )
    end

    it "has version config" do
      expect(ElasticWhenever::Option.new(%w(--version))).to have_attributes(
                                                              identifier: nil,
                                                              mode: ElasticWhenever::Option::PRINT_VERSION_MODE,
                                                              variables: [],
                                                              schedule_file: "config/schedule.rb"
                                                            )
    end
  end

  describe "#aws_config" do
    it "has no credentials" do
      expect(ElasticWhenever::Option.new(nil).aws_config).to eq({})
    end

    it "has a profile" do
      expect(ElasticWhenever::Option.new(%w(--profile my-account)).aws_config).to eq({profile: 'my-account'})
    end

    it "has a region" do
      expect(ElasticWhenever::Option.new(%w(--region=us-east-1)).aws_config).to eq({region: 'us-east-1'})
    end

    context 'static credentials' do
      let(:static_credentials) { double("Static Credentials") }

      before do
        allow(Aws::Credentials).to receive(:new).with("secret", "supersecret").and_return(static_credentials)
      end

      it "has credentials" do
        expect(ElasticWhenever::Option.new(%w(--access-key secret --secret-key supersecret)).aws_config).to eq(credentials: static_credentials)
      end

      it "has a region" do
        expect(ElasticWhenever::Option.new(%w(--access-key secret --secret-key supersecret --region=us-east-1)).aws_config).to eq({credentials: static_credentials, region: 'us-east-1'})
      end
    end
  end

  describe "#validate!" do
    it "raise exception when schedule file is not found" do
      expect {
        ElasticWhenever::Option.new(%W(
          -f invalid/file.rb
          --cluster test
          --task-definition wordpress:2
          --container testContainer
        )).validate!
      }.to raise_error(ElasticWhenever::Option::InvalidOptionException, "Can't find file: invalid/file.rb")
    end

    it "raise exception when cluster is undefined" do
      expect {
        ElasticWhenever::Option.new(%W(
          -f #{Pathname(__dir__) + "fixtures/schedule.rb"}
          --task-definition wordpress:2
          --container testContainer
        )).validate!
      }.to raise_error(ElasticWhenever::Option::InvalidOptionException, "You must set cluster")
    end

    it "raise exception when task definition is undefined" do
      expect {
        ElasticWhenever::Option.new(%W(
          -f #{Pathname(__dir__) + "fixtures/schedule.rb"}
          --cluster test
          --container testContainer
        )).validate!
      }.to raise_error(ElasticWhenever::Option::InvalidOptionException, "You must set task definition")
    end

    it "raise exception when container is undefined" do
      expect {
        ElasticWhenever::Option.new(%W(
          -f #{Pathname(__dir__) + "fixtures/schedule.rb"}
          --cluster test
          --task-definition wordpress:2
        )).validate!
      }.to raise_error(ElasticWhenever::Option::InvalidOptionException, "You must set container")
    end

    it "raises an exception if the rule state is invalid" do
      expect {
        ElasticWhenever::Option.new(%W(
          -f #{Pathname(__dir__) + "fixtures/schedule.rb"}
          --cluster test
          --task-definition wordpress:2
          --container testContainer
          --rule-state FOO
        )).validate!
      }.to raise_error(ElasticWhenever::Option::InvalidOptionException, "Invalid rule state. Possible values are ENABLED, DISABLED")
    end

    it "doesn't raise exception" do
      ElasticWhenever::Option.new(%W(
          -f #{Pathname(__dir__) + "fixtures/schedule.rb"}
          --cluster test
          --task-definition wordpress:2
          --container testContainer
      )).validate!
    end
  end

  describe "#key" do
    let(:configuration) { %w(
      --set environment=staging&foo=bar
      --cluster testCluster
      --task-definition wordpress:2
      --container testContainer
      --launch_type FARGATE
      --assign-public-ip
      --security-groups sg-2c503655,sg-72f0cb0a
      --subnets subnet-4973d63f,subnet-45827d1d
      --iam-role schedule-test
      --platform-version 1.1.0
      --rule_state DISABLED
      -i testId).freeze
    }

    it "creates a unique key for configuration options" do
      options = [
        configuration,
        replace_item(configuration, "environment=staging&foo=bar", "environment=test&baz=qux"),
        replace_item(configuration, "testCluster", "testCluster1"),
        replace_item(configuration, "testContainer", "testContainer2"),
        replace_item(configuration, "FARGATE", "EC2"),
        replace_item(configuration, "--assign-public-ip", ""),
        replace_item(configuration, "sg-2c503655,sg-72f0cb0a", "sg-2c503645,sg-72f0cbas"),
        replace_item(configuration, "subnet-4973d63f,subnet-45827d1d", "subnet-12345f,subnet-647382d"),
        replace_item(configuration, "schedule-test", "new-schedule-test"),
        replace_item(configuration, "1.1.0", "1.2.0"),
        replace_item(configuration, "DISABLED", "ENABLED"),
        replace_item(configuration, "testId", "testId2"),
      ].map { |conf| ElasticWhenever::Option.new(conf).key }

      expect(options.uniq).to eql(options)
      expect(options.uniq.length).to eql(12)
    end

    def replace_item(configuration, old_value, replacement_value)
      configuration.map { |val| val == old_value ? replacement_value : val }
    end
  end
end
