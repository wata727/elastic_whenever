module ElasticWhenever
  class Schedule
    attr_reader :tasks
    attr_reader :cluster
    attr_reader :task_definition
    attr_reader :container

    def initialize(file, environment: "production")
      @environment = environment
      @tasks = []
      @cluster = nil
      @task_definition = nil
      @container = nil
      instance_eval(File.read(file), file)
    end

    def set(key, value)
      instance_variable_set("@#{key}", value) unless key == 'tasks'
    end

    def every(frequency, options = {}, &block)
      @tasks << Task.new(@environment, frequency, options).tap do |task|
        task.instance_eval(&block)
      end
    end

    def validate!
      raise "You must specify cluster name" unless cluster
      raise "You must specify task definition" unless task_definition
      raise "You must specify container name" unless container
    end
  end
end
