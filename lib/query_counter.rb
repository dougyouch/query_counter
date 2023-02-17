module QueryCounter
  autoload :Collector, 'query_counter/collector'
  autoload :Global, 'query_counter/global'
  autoload :Middleware, 'query_counter/middleware'
  autoload :RequestHelper, 'query_counter/request_helper'
  autoload :Stat, 'query_counter/stat'

  @@callbacks = {}
  def self.callbacks
    @@callbacks
  end

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

  def self.collect
    Thread.current[:starting_gc_count] = GC.count
    Thread.current[:starting_count_objects] = ObjectSpace.count_objects
    reset
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

  def self.auto_subscribe!(resource, event_name, &block)
    require 'active_support/notifications'
    ActiveSupport::Notifications.subscribe(event_name) do |*args|
      ::QueryCounter.record_event(resource, ActiveSupport::Notifications::Event.new(*args))
    end
  end

  def self.auto_instrument!(resource, kls, method_name, &block)
    callback_name = "#{resource}.#{method_name}"

    method_name = method_name.to_s
    if method_name =~ /^(.*?)([!\?])$/
      method_name = $1
      punctuation = $2
    else
      punctuation = ''
    end

    callbacks[callback_name] = block if block

    original_method_name_with_alias = "#{method_name}_without_instrumentation#{punctuation}"
    new_method_name = "#{method_name}_with_instrumentation#{punctuation}"
    kls.class_eval <<STR
def #{new_method_name}(*args, &block)
  ::QueryCounter.callbacks[#{callback_name.inspect}].call(args) if ::QueryCounter.callbacks.has_key?(#{callback_name.inspect})
  started_at = Time.now
  result = #{original_method_name_with_alias}(*args, &block)
  ::QueryCounter.record(#{resource.inspect}, (Time.now - started_at) * 1_000.0)
  result
end
STR
    kls.send(:alias_method, original_method_name_with_alias, method_name + punctuation)
    kls.send(:alias_method, method_name + punctuation, new_method_name)
  end
end
