module QueryCounter
  class Middleware
    def initialize(app)
      @app = app
    end

    def call(env)
      QueryCounter.collect
      @app.call(env)
    end
  end
end
