# frozen_string_literal: true

require 'sinatra'
require_relative 'lib/psy_mantis/logger'
require_relative 'lib/psy_mantis/env'

PsyMantis::Env.check_required_env!

configure do
  puts "[CONFIG] Started in #{PsyMantis::Env.rack_env} environment"
  set :logger, PsyMantis::Logger.initialize_from_env
end

configure :test do
  set :protection, except: :host_authorization
end

get '/analyze' do
  steam_id = params[:steam_id]

  halt 400, { error: 'Missing steam_id' }.to_json unless steam_id

  # TODO: Implement the analysis logic here

  content_type :json
  { message: "Analysis for Steam ID #{steam_id} is not yet implemented." }.to_json
end
