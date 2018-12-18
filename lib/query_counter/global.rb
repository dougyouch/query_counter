require 'singleton'

# Purpose is to collect stats for the life time of the process
module QueryCounter
  class Global
    include Singleton

    def initialize
      @collector = ::QueryCounter::Collector.new
    end

    def record(resource, duration, by=1)
      @collector.record(resource, duration, by)
    end

    def reset
      @collector.reset
    end
  end
end
