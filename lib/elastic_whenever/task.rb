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

    def rake(task)
      @commands << [
        "bundle",
        "exec",
        "rake",
        task,
        "--slient"
      ]
    end
  end
end
