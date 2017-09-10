module ElasticWhenever
  class Option
    DRYRUN_UPDATE_CRONTAB_MODE = 1
    UPDATE_CRONTAB_MODE = 2
    CLEAR_CRONTAB_MODE = 3
    LIST_CRONTAB_MODE = 4
    PRINT_VERSION_MODE = 5

    attr_reader :identifier
    attr_reader :mode
    attr_reader :variables
    attr_reader :schedule_file

    class InvalidOptionException < StandardError; end

    def initialize(args)
      @identifier = nil
      @mode = DRYRUN_UPDATE_CRONTAB_MODE
      @variables = []
      @schedule_file = 'config/schedule.rb'

      OptionParser.new do |opts|
        opts.on('-i', '--update identifier', 'Clear and create scheduled tasks by schedule file') do |identifier|
          @identifier = identifier
          @mode = UPDATE_CRONTAB_MODE
        end
        opts.on('-c', '--clear identifier', 'Clear scheduled tasks') do |identifier|
          @identifier = identifier
          @mode = CLEAR_CRONTAB_MODE
        end
        opts.on('-l', '--list identifier', 'List scheduled tasks') do |identifier|
          @identifier = identifier
          @mode = LIST_CRONTAB_MODE
        end
        opts.on('-s' ,'--set variables', "Example: --set 'environment=staging&cluster=ecs-test'") do |set|
          pairs = set.split('&')
          pairs.each do |pair|
            unless pair.include?('=')
              Logger.instance.warn("Ignore variable set: #{pair}")
              next
            end
            key, value = pair.split('=')
            @variables = { key: key, value: value }
          end
        end
        opts.on('-f', '--file schedule_file', 'Default: config/schedule.rb') do |file|
          @schedule_file = file
        end
        opts.on('-v', '--version', 'Print version') do
          @mode = PRINT_VERSION_MODE
        end
      end.parse(args)

      validate!
    end

    def validate!
      raise InvalidOptionException.new("Can't find file: #{schedule_file}") unless File.exists?(schedule_file)
    end
  end
end