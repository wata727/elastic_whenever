module ElasticWhenever
  class Task
    attr_reader :commands
    attr_reader :frequency
    attr_reader :options

    def initialize(environment, frequency, options = {})
      @environment = environment
      @frequency = frequency
      @options = options
      @commands = []
    end

    def command(task)
      @commands << task.split(" ")
    end

    def rake(task)
      @commands << [
        "bundle",
        "exec",
        "rake",
        task,
        "--silent"
      ]
    end

    def runner(src)
      @commands << [
        "bundle",
        "exec",
        "bin/rails",
        "runner",
        "-e",
        @environment,
        src
      ]
    end

    def script(script)
      @commands << [
        "bundle",
        "exec",
        "script/#{script}"
      ]
    end

    def method_missing(name, *args)
      Logger.instance.warn("Skipping unsupported method: #{name}")
    end
  end
end
