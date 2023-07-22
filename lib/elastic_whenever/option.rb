module ElasticWhenever
  class Option
    POSSIBLE_RULE_STATES = %w[ENABLED DISABLED].freeze

    DRYRUN_MODE = 1
    UPDATE_MODE = 2
    CLEAR_MODE = 3
    LIST_MODE = 4
    PRINT_VERSION_MODE = 5

    attr_reader :identifier
    attr_reader :mode
    attr_reader :verbose
    attr_reader :variables
    attr_reader :cluster
    attr_reader :task_definition
    attr_reader :container
    attr_reader :assign_public_ip
    attr_reader :launch_type
    attr_reader :platform_version
    attr_reader :security_groups
    attr_reader :subnets
    attr_reader :schedule_file
    attr_reader :iam_role
    attr_reader :rule_state
    attr_reader :aws_config
    attr_reader :ecs_client
    attr_reader :iam_client
    attr_reader :cloudwatch_events_client

    class InvalidOptionException < StandardError; end

    def initialize(args)
      @identifier = nil
      @mode = DRYRUN_MODE
      @verbose = false
      @variables = []
      @cluster = nil
      @task_definition = nil
      @container = nil
      @assign_public_ip = 'DISABLED'
      @launch_type = 'EC2'
      @platform_version = 'LATEST'
      @security_groups = []
      @subnets = []
      @schedule_file = 'config/schedule.rb'
      @iam_role = 'ecsEventsRole'
      @rule_state = 'ENABLED'
      @profile = nil
      @access_key = nil
      @secret_key = nil
      @region = nil

      OptionParser.new do |opts|
        opts.on('-i', '--update identifier', 'Creates and deletes tasks as needed by schedule file') do |identifier|
          @identifier = identifier
          @mode = UPDATE_MODE
        end
        opts.on('-c', '--clear identifier', 'Clear scheduled tasks') do |identifier|
          @identifier = identifier
          @mode = CLEAR_MODE
        end
        opts.on('-l', '--list identifier', 'List scheduled tasks') do |identifier|
          @identifier = identifier
          @mode = LIST_MODE
        end
        opts.on('-s' ,'--set variables', "Example: --set 'environment=staging'") do |set|
          pairs = set.split('&')
          pairs.each do |pair|
            unless pair.include?('=')
              Logger.instance.warn("Ignore variable set: #{pair}")
              next
            end
            key, value = pair.split('=')
            @variables << { key: key, value: value }
          end
        end
        opts.on('--cluster cluster', 'ECS cluster to run tasks') do |cluster|
          @cluster = cluster
        end
        opts.on('--task-definition task_definition', 'Task definition name, If omit a revision, use the latest revision of the family automatically. Example: --task-definition oneoff-application:2') do |definition|
          @task_definition = definition
        end
        opts.on('--container container', 'Container name defined in the task definition') do |container|
          @container = container
        end
        opts.on('--launch-type launch_type', 'Launch type. EC2 or FARGATE. Default: EC2') do |launch_type|
          @launch_type = launch_type
        end
        opts.on('--assign-public-ip', 'Assign a public IP. Default: DISABLED (FARGATE only)') do
          @assign_public_ip = 'ENABLED'
        end
        opts.on('--security-groups groups', "Example: --security-groups 'sg-2c503655,sg-72f0cb0a' (FARGATE only)") do |groups|
          @security_groups = groups.split(',')
        end
        opts.on('--subnets subnets', "Example: --subnets 'subnet-4973d63f,subnet-45827d1d' (FARGATE only)") do |subnets|
          @subnets = subnets.split(',')
        end
        opts.on('--platform-version version', "Optionally specify the platform version. Default: LATEST (FARGATE only)") do |version|
          @platform_version = version
        end
        opts.on('-f', '--file schedule_file', 'Default: config/schedule.rb') do |file|
          @schedule_file = file
        end
        opts.on('--iam-role name', 'IAM role name used by CloudWatch Events. Default: ecsEventsRole') do |role|
          @iam_role = role
        end
        opts.on('--rule-state state', 'The state of the CloudWatch Events Rule. Default: ENABLED') do |state|
          @rule_state = state
        end
        opts.on('--profile profile_name', 'AWS shared profile name') do |profile|
          @profile = profile
        end
        opts.on('--access-key aws_access_key_id', 'AWS access key ID') do |key|
          @access_key = key
        end
        opts.on('--secret-key aws_secret_access_key', 'AWS secret access key') do |key|
          @secret_key = key
        end
        opts.on('--region region', 'AWS region') do |region|
          @region = region
        end
        opts.on('-v', '--version', 'Print version') do
          @mode = PRINT_VERSION_MODE
        end
        opts.on('-V', '--verbose', 'Run rake jobs without --silent') do
          @verbose = true
        end
      end.parse(args)

      @credentials = if profile
                       Aws::SharedCredentials.new(profile_name: profile)
                     elsif access_key && secret_key
                       Aws::Credentials.new(access_key, secret_key)
                     end
    end

    def aws_config
      @aws_config ||= { credentials: credentials, region: region }.delete_if { |_k, v| v.nil? }
    end

    def ecs_client
      @ecs_client ||= Aws::ECS::Client.new(aws_config)
    end

    def iam_client
      @iam_client ||= Aws::IAM::Client.new(aws_config)
    end

    def cloudwatch_events_client
      @cloudwatch_events_client ||= Aws::CloudWatchEvents::Client.new(aws_config)
    end

    def validate!
      raise InvalidOptionException.new("Can't find file: #{schedule_file}") unless File.exist?(schedule_file)
      raise InvalidOptionException.new("You must set cluster") unless cluster
      raise InvalidOptionException.new("You must set task definition") unless task_definition
      raise InvalidOptionException.new("You must set container") unless container
      raise InvalidOptionException.new("Invalid rule state. Possible values are #{POSSIBLE_RULE_STATES.join(", ")}") unless POSSIBLE_RULE_STATES.include?(rule_state)
    end

    def key
      Digest::SHA1.hexdigest(
        [
          identifier,
          variables,
          cluster,
          task_definition,
          container,
          assign_public_ip,
          launch_type,
          platform_version,
          security_groups,
          subnets,
          iam_role,
          rule_state,
        ].join
      )
    end

    private

    attr_reader :profile
    attr_reader :access_key
    attr_reader :secret_key
    attr_reader :region
    attr_reader :credentials
  end
end
