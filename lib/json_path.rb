# frozen_string_literal: true

require 'rordash'

%w[
  version
  default_data_wrapper
  path_context
  path_context_collection
  builder
].each do |filename|
  require File.expand_path("../json-path/#{filename}", Pathname.new(__FILE__).realpath)
end

module JsonPath; end
