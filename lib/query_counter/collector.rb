module QueryCounter
  class Collector
    attr_reader :stats,
                :notification_events

    def initialize
      reset
    end

    def record(resource, duration, by=1)
      @stats[resource] ||= ::QueryCounter::Stat.new
      @stats[resource].increment(duration, by)
    end

    # used for debugging resource events
    def record_event(resource, event)
      record(resource, event.duration)

      @notification_events ||= {}
      @notification_events[resource] ||= []
      @notification_events[resource] << event
    end

    def reset
      if instance_variable_defined?(:@notification_events)
        remove_instance_variable(:@notification_events)
      end

      # just away to return the current stats and reset them back to an empty hash
      @stats.tap { @stats = {} }
    end

    def count(resource)
      (@stats[resource] && @stats[resource].count) || 0
    end

    def events(resource)
      (@notification_events && @notification_events[resource]) || []
    end

    def add(collector)
      if collector.notification_events
        collector.notification_events.each do |resource, list|
          list.each { |event| record_event(resource, event) }
        end
      else
        collector.stats.each do |resource, stat|
          record(record, stat.time, stat.count)
        end
      end
      self
    end
  end
end
