module QueryCounter
  class Stat
    attr_reader :count,
                :time

    def initialize
      @count = 0
      @time = 0.0
    end

    def increment(duration, by=1)
      @count += by
      @time += duration
    end
  end
end
