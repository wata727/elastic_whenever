module ElasticWhenever
  class Option
    DRYRUN_MODE = 1
    UPDATE_MODE = 2
    CLEAR_MODE = 3
    LIST_MODE = 4
    PRINT_VERSION_MODE = 5

    attr_reader :identifier
    attr_reader :mode
    attr_reader :variables
    attr_reader :schedule_file

    class InvalidOptionException < StandardError; end

    def initialize(args)
      @identifier = nil
      @mode = DRYRUN_MODE
      @variables = []
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
      raise InvalidOptionException.new("Can't find file: #{schedule_file}") unless File.exists?(schedule_file)
    end

    private

    attr_reader :profile
    attr_reader :access_key
    attr_reader :secret_key
    attr_reader :region
    attr_reader :credentials
  end
end