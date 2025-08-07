# frozen_string_literal: true

# Determines whether test coverage tracking is enabled.
#
# This method checks the `COVERAGE` environment variable and returns `true`
# only if its value is explicitly the string "true" (case-insensitive).
# This allows coverage to be toggled in different environments (e.g., local vs CI).
#
# @return [Boolean] true if coverage is enabled, false otherwise
def coverage_enabled?
  ENV['COVERAGE']&.downcase == 'true'
end

if coverage_enabled?
  require 'simplecov'
  SimpleCov.start do
    enable_coverage :branch
    add_filter '/spec/'
    add_filter '/config/'
  end

  puts '>>>> [COVERAGE] SimpleCov started with branch coverage enabled'
end

require 'bundler/setup'
require 'rack/test'
require 'rspec'
require 'webmock/rspec'
require_relative '../app'
require_relative '../lib/psy_mantis'

RSpec.configure do |config|
  config.include Rack::Test::Methods

  # FIX: fix the logging level variable
  config.after(:each, type: :request) do |example|
    if ENV['LOG_LEVEL'] == 'DEBUG' && example.exception && last_response
      puts '  --- REQUEST DEBUG ---'
      puts "  Host: #{last_request.host}"
      puts "  URL:  #{last_request.url}"
      puts "  Status: #{last_response.status}"
      puts "  Body: #{last_response.body}"
    end
  end
end
