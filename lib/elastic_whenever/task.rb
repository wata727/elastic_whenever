module ElasticWhenever
  class Task
    attr_reader :commands
    attr_reader :frequency
    attr_reader :options

    def initialize(environment, bundle_command, frequency, options = {})
      @environment = environment
      @bundle_command = bundle_command.split(" ")
      @frequency = frequency
      @options = options
      @commands = []
    end

    def command(task)
      @commands << task.split(" ")
    end

    def rake(task)
      @commands << [@bundle_command, "rake", task, "--silent"].flatten
    end

    def runner(src)
      @commands << [@bundle_command, "bin/rails", "runner", "-e", @environment, src].flatten
    end

    def script(script)
      @commands << [@bundle_command, "script/#{script}"].flatten
    end

    def method_missing(name, *args)
      Logger.instance.warn("Skipping unsupported method: #{name}")
    end
  end
end
