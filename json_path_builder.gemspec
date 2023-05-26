# frozen_string_literal: true

require 'English'
require File.expand_path('lib/json-path-builder/version', __dir__)

Gem::Specification.new do |gem|
  gem.authors = ["Desmond O'Leary"]
  gem.email = ["desoleary@gmail.com"]
  gem.description = 'Declarative mapping JSON/Hash data structures'
  gem.summary = 'Declarative mapping JSON/Hash data structures'
  gem.homepage = "https://github.com/omnitech-solutions/json-path-builder"
  gem.license = "MIT"

  gem.files = `git ls-files`.split($OUTPUT_RECORD_SEPARATOR)
  gem.executables = gem.files.grep(%r{^exe/}).map { |f| File.basename(f) }
  gem.name = "json-path-builder"
  gem.require_paths = ["lib"]
  gem.version = JsonPathBuilder::VERSION
  gem.required_ruby_version = ">= 2.7"

  gem.metadata["homepage_uri"] = gem.homepage
  gem.metadata["source_code_uri"] = gem.homepage
  gem.metadata["changelog_uri"] = "#{gem.homepage}/CHANGELOG.md"

  gem.add_runtime_dependency 'activesupport', '>= 5'
  gem.add_runtime_dependency 'rordash', '~> 0.1.2'

  gem.add_development_dependency("codecov", "~> 0.6.0")
  gem.add_development_dependency("rake", "~> 13.0.6")
  gem.add_development_dependency("rspec", "~> 3.12.0")
  gem.add_development_dependency("simplecov", "~> 0.21.2")
  gem.metadata['rubygems_mfa_required'] = 'true'
end
