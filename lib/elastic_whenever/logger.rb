module ElasticWhenever
  class Logger
    include Singleton

    def fail(message)
      STDERR.puts "[fail] #{message}"
    end

    def warn(message)
      STDERR.puts "[warn] #{message}"
    end

    def log(event, message)
      puts "[#{event}] #{message}"
    end

    def message(message)
      puts "## [message] #{message}"
    end
  end
end
