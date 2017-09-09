module ElasticWhenever
  class Option
    UPDATE_CRONTAB_MODE = 1
    CLEAR_CRONTAB_MODE = 2
    PRINT_VERSION_MODE = 3

    attr_reader :identifier
    attr_reader :mode
    attr_reader :variables
    attr_reader :schedule_file

    def initialize(args)
      @identifier = 'elastic-whenever'
      @mode = nil
      @variables = []
      @schedule_file = 'config/schedule.rb'

      OptionParser.new do |opts|
        opts.on('-i', '--update-crontab [identifier]', 'Default: elastic-whenever') do |identifier|
          @identifier = identifier if identifier.is_a? String
          @mode = UPDATE_CRONTAB_MODE
        end
        opts.on('-c', '--clear-crontab [identifier]', 'Default: elastic-whenever') do |identifier|
          @identifier = identifier if identifier.is_a? String
          @mode = CLEAR_CRONTAB_MODE
        end
        opts.on('-s' ,'--set [variables]', "Example: --set 'environment=staging&cluster=ecs-test'") do |set|
          pairs = set.split('&')
          pairs.each do |pair|
            next unless pair.include?('=')
            key, value = pair.split('=')
            @variables = { key: key, value: value }
          end
        end
        opts.on('-f', '--load-file [schedule file]', 'Default: config/schedule.rb') do |file|
          @schedule_file = file
        end
        opts.on('-v', '--version', 'Print version') do
          @mode = PRINT_VERSION_MODE
        end
      end.parse(args)
    end
  end
end