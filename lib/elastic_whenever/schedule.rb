module ElasticWhenever
  class Schedule
    attr_reader :tasks
    attr_reader :cluster
    attr_reader :task_definition
    attr_reader :container
    attr_reader :chronic_options
    attr_reader :bundle_command
    attr_reader :environment

    class InvalidScheduleException < StandardError; end
    class UnsupportedFrequencyException < StandardError; end

    module WheneverNumeric
      refine Numeric do
        def seconds
          self
        end
        alias :second :seconds

        def minutes
          self * 60
        end
        alias :minute :minutes

        def hours
          (self * 60).minutes
        end
        alias :hour :hours

        def days
          (self * 24).hours
        end
        alias :day :days

        def weeks
          (self * 7).days
        end
        alias :week :weeks

        def months
          (self * 30).days
        end
        alias :month :months

        def years
          (self * 365.25).days
        end
        alias :year :years
      end
    end
    using WheneverNumeric

    def initialize(file, verbose, variables)
      @environment = "production"
      @verbose = verbose
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
      @tasks << Task.new(@environment, @verbose, @bundle_command, schedule_expression(frequency, options)).tap do |task|
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
      opts =  { :now => Time.new(2017, 12, 1, 0, 0, 0) }.merge(@chronic_options)
      time = Chronic.parse(options[:at], opts) || Time.new(2017, 12, 1, 0, 0, 0)

      case frequency
      when 1.minute
        "cron(* * * * ? *)"
      when :hour, 1.hour
        "cron(#{time.min} * * * ? *)"
      when :day, 1.day
        "cron(#{time.min} #{time.hour} * * ? *)"
      when :month, 1.month
        "cron(#{time.min} #{time.hour} #{time.day} * ? *)"
      when :year, 1.year
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
      when 1.second...1.minute
        raise UnsupportedFrequencyException.new("Time must be in minutes or higher. Ignore this task.")
      when 1.minute...1.hour
        step = (frequency / 60).round
        min = []
        (60 % step == 0 ? 0 : step).step(59, step) { |i| min << i }
        "cron(#{min.join(",")} * * * ? *)"
      when 1.hour...1.day
        step = (frequency / 60 / 60).round
        hour = []
        (24 % step == 0 ? 0 : step).step(23, step) { |i| hour << i }
        "cron(#{time.min} #{hour.join(",")} * * ? *)"
      when 1.day...1.month
        step = (frequency / 24 / 60 / 60).round
        day = []
        (step <= 16 ? 1 : step).step(30, step) { |i| day << i }
        "cron(#{time.min} #{time.hour} #{day.join(",")} * ? *)"
      when 1.month...12.months
        step = (frequency / 30 / 24 / 60 / 60).round
        month = []
        (step <= 6 ? 1 : step).step(12, step) { |i| month << i }
        "cron(#{time.min} #{time.hour} #{time.day} #{month.join(",")} ? *)"
      when 12.months...Float::INFINITY
        raise UnsupportedFrequencyException.new("Time must be in months or lower. Ignore this task.")
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
