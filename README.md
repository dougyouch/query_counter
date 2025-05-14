# QueryCounter

A Ruby gem designed to help troubleshoot performance bottlenecks by tracking and analyzing external system requests. This gem provides detailed insights into API calls by monitoring:
- Which resources are being accessed
- How many times each resource is called
- Total time spent on each resource
- Timing information for individual requests

## Features

- Track requests to external systems with timing information
- Support for both global and per-request tracking
- Integration with ActiveSupport::Notifications
- Thread-safe operation
- Automatic instrumentation of methods
- Temporary collectors for specific code blocks
- Rack middleware for automatic request tracking
- Detailed resource usage summaries

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'query_counter'
```

And then execute:

```bash
$ bundle install
```

## Rails Integration

To enable automatic request tracking in a Rails application, add the middleware to your `config/application.rb`:

```ruby
module YourApp
  class Application < Rails::Application
    # ... other configuration ...
    
    # Add QueryCounter middleware after the Rails logger
    config.middleware.use QueryCounter::Middleware
  end
end
```

The middleware will automatically track all external requests during each web request and provide a summary in your logs.

## Usage

### Basic Usage

```ruby
# Record a request
QueryCounter.record('external_api', duration_in_milliseconds)

# Get count for a specific resource
count = QueryCounter.count('external_api')

# Reset the current collector
QueryCounter.reset
```

### Using Collectors

```ruby
# Get the global collector
global = QueryCounter.global_collector

# Get the current thread's collector
current = QueryCounter.current_collector

# Use a temporary collector for a specific block
QueryCounter.around do
  # Your code here
  # All queries will be collected separately
end
```

### Automatic Instrumentation

```ruby
# Subscribe to ActiveSupport notifications
QueryCounter.auto_subscribe!('database', 'sql.active_record') do |*args|
  # Custom handling if needed
end

# Instrument a specific method
QueryCounter.auto_instrument!('external_api', MyClass, :fetch_data) do |args|
  # Custom handling if needed
end
```

### Analyzing Resource Usage

The gem provides detailed insights into resource usage. For example, in a Rails application with the middleware enabled, you'll see log output like:

```
QueryCounter Summary:
  - external_api: 5 calls, total time: 1500ms
  - database: 12 calls, total time: 800ms
  - cache: 3 calls, total time: 50ms
```

This helps identify:
- Which resources are being called most frequently
- Which resources are taking the most time
- Potential bottlenecks in your application

## Development

After checking out the repo, run `bundle install` to install dependencies.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/evertrue/query_counter.

## License

The gem is available as open source under the terms of the MIT License.
