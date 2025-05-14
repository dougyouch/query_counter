# QueryCounter

A Ruby gem for monitoring and counting requests to external systems. This gem provides tools to track the number and duration of external calls in your application.

## Features

- Track requests to external systems with timing information
- Support for both global and per-request tracking
- Integration with ActiveSupport::Notifications
- Thread-safe operation
- Automatic instrumentation of methods
- Temporary collectors for specific code blocks

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'query_counter'
```

And then execute:

```bash
$ bundle install
```

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

## Development

After checking out the repo, run `bundle install` to install dependencies.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/evertrue/query_counter.

## License

The gem is available as open source under the terms of the MIT License.
