module ElasticWhenever
  class Schedule
    attr_reader :tasks
    attr_reader :cluster
    attr_reader :task_definition
    attr_reader :container
    attr_reader :chronic_options
    attr_reader :bundle_command

    class InvalidScheduleException < StandardError; end

    def initialize(file, variables)
      @environment = "production"
      @tasks = []
      @cluster = nil
      @task_definition = nil
      @container = nil
      @chronic_options = {}
      @bundle_command = "bundle exec"

      variables.each { |var| set(var[:key], var[:value]) }
      instance_eval(File.read(file), file)
    end

    def set(key, value)
      instance_variable_set("@#{key}", value) unless key == 'tasks'
    end

    def every(frequency, options = {}, &block)
      @tasks << Task.new(@environment, @bundle_command, frequency, options).tap do |task|
        task.instance_eval(&block)
      end
    end

    def validate!
      raise InvalidScheduleException.new("You must set cluster") unless cluster
      raise InvalidScheduleException.new("You must set task definition") unless task_definition
      raise InvalidScheduleException.new("You must set container") unless container
    end

    def method_missing(name, *args)
      Logger.instance.warn("Skipping unsupported method: #{name}")
    end
  end
end
