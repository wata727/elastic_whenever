module ElasticWhenever
  class Option
    UPDATE_CRONTAB_MODE = 1
    CLEAR_CRONTAB_MODE = 2
    PRINT_VERSION_MODE = 3

    attr_reader :identifier
    attr_reader :mode
    attr_reader :variables

    def initialize(args)
      @identifier = 'elastic-whenever'
      @mode = nil
      @variables = []

      OptionParser.new do |opts|
        opts.on('-i', '--update-crontab', 'Default: full path to schedule.rb file') do |identifier|
          @identifier = identifier if identifier.is_a? String
          @mode = UPDATE_CRONTAB_MODE
        end
        opts.on('-c', '--clear-crontab') do |identifier|
          @identifier = identifier if identifier.is_a? String
          @mode = CLEAR_CRONTAB_MODE
        end
        opts.on('-s' ,'--set', "Example: --set 'environment=staging&path=/my/sweet/path'") do |set|
          pairs = set.split('&')
          pairs.each do |pair|
            next unless pair.include?('=')
            key, value = pair.split('=')
            @variables = { key: key, value: value }
          end
        end
        opts.on('-v', '--version') do
          @mode = PRINT_VERSION_MODE
        end
      end.parse(args)
    end
  end
end