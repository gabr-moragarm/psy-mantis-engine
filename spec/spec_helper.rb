# frozen_string_literal: true

if ENV['COVERAGE']&.downcase == 'true'
  require 'simplecov'
  SimpleCov.start do
    enable_coverage :branch
    add_filter '/spec/'
    add_filter '/config/'
  end

  puts '>>>> [COVERAGE] SimpleCov started with branch coverage enabled'
end

require 'rack/test'
require 'rspec'
require 'webmock/rspec'
require_relative '../app'

RSpec.configure do |config|
  config.include(
    Module.new do
      include Rack::Test::Methods

      def app
        Sinatra::Application
      end
    end,
    type: :internal_api
  )

  config.after(:each, type: :internal_api) do |example|
    if PsyMantis::Env.logs?(:debug) && example.exception && last_response
      puts '  --- REQUEST DEBUG ---'
      puts "  Host: #{last_request.host}"
      puts "  URL:  #{last_request.url}"
      puts "  Status: #{last_response.status}"
      puts "  Body: #{last_response.body}"
    end
  end
end
