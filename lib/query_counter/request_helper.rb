module QueryCounter
  module RequestHelper
    def qc_log_resource_usage_around
      yield
    ensure
      qc_log_resource_usage
    end

    def qc_log_count_objects_around
      yield
    ensure
      qc_log_count_objects
    end

    def qc_log_resource_usage
      gc = GC.count - Thread.current[:starting_gc_count]
      stats = []
      stats << "gc: #{gc}" if gc > 0
      QueryCounter.current_collector.stats.each do |resource, stat|
        stats << "#{resource}: #{stat.count} [#{stat.time.to_i}ms]"
      end

      logger.info 'Resource Stats ' + stats.join(', ')
    end

    def qc_log_count_objects
      diff_count_objects = {}
      ObjectSpace.count_objects.each do |name, count|
        if (diff = (count - Thread.current[:starting_count_objects][name].to_i)) > 0
          diff_count_objects[name] = diff
        end
      end

      logger.info "Objects: #{diff_count_objects}"
    end
  end
end
