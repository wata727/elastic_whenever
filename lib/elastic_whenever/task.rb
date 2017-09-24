module ElasticWhenever
  class Task
    attr_reader :commands
    attr_reader :expression

    def initialize(environment, bundle_command, expression)
      @environment = environment
      @bundle_command = bundle_command.split(" ")
      @expression = expression
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
