# frozen_string_literal: true

require 'sinatra'
require_relative './logger'
require_relative './env'

PsyMantis::Env.check_required_env!

module PsyMantis
  # PsyMantis::API is the main web interface for the Psycho Mantis Engine.
  #
  # This class defines the HTTP endpoints used to analyze a user's Steam library
  # and generate personalized commentary inspired by the Psycho Mantis character.
  #
  # It inherits from `Sinatra::Base`, making it a Rack-compatible application
  # suitable for multithreaded web servers like Puma. The modular structure
  # ensures thread safety by instantiating a new object per request.
  #
  # @example Mounting the API in config.ru
  #   require_relative 'lib/psy_mantis/api'
  #   run PsyMantis::API
  #
  # @see Sinatra::Base
  # @author gabr-moragarm
  class API < Sinatra::Base
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
  end
end
