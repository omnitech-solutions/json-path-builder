if ENV['RUN_COVERAGE_REPORT']
  require 'simplecov'

  SimpleCov.start do
    add_filter 'vendor/'
    add_filter %r{^/spec/}
  end
  SimpleCov.minimum_coverage_by_file 90

  require 'codecov'
  SimpleCov.formatter = SimpleCov::Formatter::Codecov
end
