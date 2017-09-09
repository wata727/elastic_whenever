module ElasticWhenever
  class Logger
    include Singleton

    def fail(message)
      puts "[fail] #{message}"
    end

    def warn(message)
      puts "[warn] #{message}"
    end
  end
end