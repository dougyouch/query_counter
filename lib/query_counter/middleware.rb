module QueryCounter
  class Middleware
    def initialize(app)
      @app = app
    end

    def call(env)
      Thread.current[:starting_gc_count] = GC.count
      Thread.current[:starting_count_objects] = ObjectSpace.count_objects
      QueryCounter.reset
      @app.call(env)
    end
  end
end
