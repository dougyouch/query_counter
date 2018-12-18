module QueryCounter
  autoload :Collector, 'query_counter/collector'
  autoload :Global, 'query_counter/global'
  autoload :Stat, 'query_counter/stat'

  def self.global_collector
    ::QueryCounter::Global.instance
  end

  def self.current_collector
    Thread.current[:query_counter_collector] ||= ::QueryCounter::Collector.new
  end

  def self.temporary_collector
    Thread.current[:temporary_query_counter_collector]
  end

  def self.record(resource, duration, by=1)
    global_collector.record(resource, duration, by)
    current_collector.record(resource, duration, by)
  end

  def self.record_event(resource, event)
    temporary_collector && temporary_collector.record_event(resource, event)
    record(resource, event.duration)
  end

  def self.reset
    current_collector.reset
  end

  def self.around
    new_collector = ::QueryCounter::Collector.new
    old_collector, Thread.current[:temporary_query_counter_collector] = Thread.current[:temporary_query_counter_collector], new_collector

    yield

    if old_collector
      Thread.current[:temporary_query_counter_collector] = old_collector.add(new_collector)
    else
      Thread.current[:temporary_query_counter_collector] = nil
    end

    new_collector
  end

  def self.count(resource)
    current_collector.count(resource)
  end

  def self.global_count(resource)
    current_collector.count(resource)
  end

  def self.auto_subscribe!(resource, event_name)
    require 'active_support/notifications'
    ActiveSupport::Notifications.subscribe(event_name) do |*args|
      ::QueryCounter.record_event(resource, ActiveSupport::Notifications::Event.new(*args))
    end
  end
end
