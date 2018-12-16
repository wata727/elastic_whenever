module ElasticWhenever
  class Option
    DRYRUN_MODE = 1
    UPDATE_MODE = 2
    CLEAR_MODE = 3
    LIST_MODE = 4
    PRINT_VERSION_MODE = 5

    attr_reader :identifier
    attr_reader :mode
    attr_reader :verbose
    attr_reader :variables
    attr_reader :assign_public_ip
    attr_reader :launch_type
    attr_reader :platform_version
    attr_reader :security_groups
    attr_reader :subnets
    attr_reader :schedule_file

    class InvalidOptionException < StandardError; end

    def initialize(args)
      @identifier = nil
      @mode = DRYRUN_MODE
      @verbose = false
      @variables = []
      @assign_public_ip = 'DISABLED'
      @launch_type = 'EC2'
      @platform_version = 'LATEST'
      @security_groups = nil
      @subnets = nil
      @schedule_file = 'config/schedule.rb'
      @profile = nil
      @access_key = nil
      @secret_key = nil
      @region = nil

      OptionParser.new do |opts|
        opts.on('-i', '--update identifier', 'Clear and create scheduled tasks by schedule file') do |identifier|
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
        opts.on('-s' ,'--set variables', "Example: --set 'environment=staging&cluster=ecs-test'") do |set|
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
        opts.on('--assign_public_ip', 'Assign a public IP.') do
          @assign_public_ip = 'ENABLED'
        end
        opts.on('--launch_type launch_type', 'Launch type. Defualt: EC2') do |launch_type|
          @launch_type = launch_type
        end
        opts.on('--security_groups groups', "Example: --security_groups 'sg-2c503655,sg-72f0cb0a'") do |groups|
          @security_groups = groups
        end
        opts.on('--subnets subnets', "Example: --subnets 'subnet-4973d63f,subnet-45827d1d'") do |subnets|
          @subnets = subnets
        end
        opts.on('--platform_version version', "For Fargate launch type, optionally specify the platform version. Example: --platform_version 1.2.0") do |version|
          @platform_version = version
        end
        opts.on('-f', '--file schedule_file', 'Default: config/schedule.rb') do |file|
          @schedule_file = file
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
      { credentials: credentials, region: region }.delete_if { |_k, v| v.nil? }
    end

    def validate!
      raise InvalidOptionException.new("Can't find file: #{schedule_file}") unless File.exist?(schedule_file)
    end

    private

    attr_reader :profile
    attr_reader :access_key
    attr_reader :secret_key
    attr_reader :region
    attr_reader :credentials
  end
end
