module ElasticWhenever
  class Schedule
    attr_reader :tasks
    attr_reader :cluster
    attr_reader :task_definition
    attr_reader :container
    attr_reader :chronic_options
    attr_reader :bundle_command

    class InvalidScheduleException < StandardError; end
    class UnsupportedFrequencyException < StandardError; end

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
      @tasks << Task.new(@environment, @bundle_command, schedule_expression(frequency, options)).tap do |task|
        task.instance_eval(&block)
      end
    rescue UnsupportedFrequencyException => exn
      Logger.instance.warn(exn.message)
    end

    def validate!
      raise InvalidScheduleException.new("You must set cluster") unless cluster
      raise InvalidScheduleException.new("You must set task definition") unless task_definition
      raise InvalidScheduleException.new("You must set container") unless container
    end

    def schedule_expression(frequency, options)
      time = Chronic.parse(options[:at], @chronic_options) || Time.new(2017, 12, 1, 0, 0, 0)

      case frequency
      when :hour
        "cron(#{time.min} * * * ? *)"
      when :day
        "cron(#{time.min} #{time.hour} * * ? *)"
      when :month
        "cron(#{time.min} #{time.hour} #{time.day} * ? *)"
      when :year
        "cron(#{time.min} #{time.hour} #{time.day} #{time.month} ? *)"
      when :sunday
        "cron(#{time.min} #{time.hour} ? * 1 *)"
      when :monday
        "cron(#{time.min} #{time.hour} ? * 2 *)"
      when :tuesday
        "cron(#{time.min} #{time.hour} ? * 3 *)"
      when :wednesday
        "cron(#{time.min} #{time.hour} ? * 4 *)"
      when :thursday
        "cron(#{time.min} #{time.hour} ? * 5 *)"
      when :friday
        "cron(#{time.min} #{time.hour} ? * 6 *)"
      when :saturday
        "cron(#{time.min} #{time.hour} ? * 7 *)"
      when :weekend
        "cron(#{time.min} #{time.hour} ? * 1,7 *)"
      when :weekday
        "cron(#{time.min} #{time.hour} ? * 2-6 *)"
      # cron syntax
      when /^((\*?[\d\/,\-]*)\s*){5}$/
        min, hour, day, mon, week, year = frequency.split(" ")
        # You can't specify the Day-of-month and Day-of-week fields in the same Cron expression.
        # If you specify a value in one of the fields, you must use a ? (question mark) in the other.
        week.gsub!("*", "?") if day != "?"
        day.gsub!("*", "?") if week != "?"
        # cron syntax:          sunday -> 0
        # scheduled expression: sunday -> 1
        week.gsub!(/(\d)/) { (Integer($1) + 1) % 7 }
        year = year || "*"
        "cron(#{min} #{hour} #{day} #{mon} #{week} #{year})"
      # schedule expression syntax
      when /^((\*?\??L?W?[\d\/,\-]*)\s*){6}$/
        "cron(#{frequency})"
      else
        raise UnsupportedFrequencyException.new("`#{frequency}` is not supported option. Ignore this task.")
      end
    end

    def method_missing(name, *args)
      Logger.instance.warn("Skipping unsupported method: #{name}")
    end
  end
end
