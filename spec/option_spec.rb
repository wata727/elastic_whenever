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
                                                    schedule_file: "config/schedule.rb"
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
        schedule_file: "custom_schedule.rb"
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
    let(:shared_credentials) { double("Shared Credentials") }
    let(:static_credentials) { double("Static Credentials") }

    before do
      allow(Aws::SharedCredentials).to receive(:new).with(profile_name: "my-account").and_return(shared_credentials)
      allow(Aws::Credentials).to receive(:new).with("secret", "supersecret").and_return(static_credentials)
    end

    it "has no credentials" do
      expect(ElasticWhenever::Option.new(nil).aws_config).to eq({})
    end

    it "has shared credentials" do
      expect(ElasticWhenever::Option.new(%w(--profile my-account)).aws_config).to eq(credentials: shared_credentials)
    end

    it "has static credentials" do
      expect(ElasticWhenever::Option.new(%w(--access-key secret --secret-key supersecret)).aws_config).to eq(credentials: static_credentials)
    end

    it "has credentials with region" do
      expect(ElasticWhenever::Option.new(%w(--profile my-account --region us-east-1)).aws_config).to eq(credentials: shared_credentials, region: "us-east-1")
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

    it "doesn't raise exception" do
      ElasticWhenever::Option.new(%W(
          -f #{Pathname(__dir__) + "fixtures/schedule.rb"}
          --cluster test
          --task-definition wordpress:2
          --container testContainer
      )).validate!
    end
  end
end