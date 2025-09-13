# frozen_string_literal: true

require 'faraday'
require_relative './errors'

module PsyMantis
  module Steam
    module HTTP
      # Handles HTTP transport and error mapping for Steam API requests.
      class Transport
        # Default options for the transport.
        DFLT_OPTIONS = {
          open_timeout: 3,
          read_timeout: 5,
          max_retries: 2,
          base_backoff: 0.5,
          jitter: true
        }.freeze

        # Default headers for all requests.
        HEADERS = {
          'User-Agent' => 'psy-mantis-engine/1.0 (+https://github.com/gabr-moragarm/psy-mantis-engine)',
          'Accept' => 'application/json'
        }.freeze

        # Maps Faraday errors to custom error classes.
        FARADAY_ERROR_MAPPING = {
          Faraday::UnauthorizedError => PsyMantis::Steam::HTTP::Errors::Unauthorized,
          Faraday::ForbiddenError => PsyMantis::Steam::HTTP::Errors::Forbidden,
          Faraday::ResourceNotFound => PsyMantis::Steam::HTTP::Errors::NotFound,
          Faraday::ServerError => PsyMantis::Steam::HTTP::Errors::ServerError,
          Faraday::TooManyRequestsError => lambda do |error, attempts|
            retry_after = error.response[:headers]['Retry-After']&.to_i
            PsyMantis::Steam::HTTP::Errors::RateLimited.new(
              retry_after: retry_after,
              attempts: attempts,
              cause: error
            )
          end
        }.freeze

        # Initializes a new Transport instance.
        #
        # @param base_url [String] The base URL for the API.
        # @param opts [Hash] Optional configuration overrides.
        # @raise [ArgumentError] If base_url is not a non-empty String.
        def initialize(base_url:, **opts)
          unless base_url.is_a?(String) && !base_url.strip.empty?
            raise ArgumentError, "Base URL (base_url) must be a non-empty String (given: #{base_url.inspect})"
          end

          @opts = DFLT_OPTIONS.merge(opts)
          @conn = new_faraday_connection(base_url)
        end

        # Performs a GET request with retries and error handling.
        #
        # @param path [String] The request path.
        # @param params [Hash] Query parameters.
        # @return [Object] The parsed response body.
        # @raise [PsyMantis::Steam::HTTP::Errors::Timeout] If a timeout occurs.
        def get(path, params = {})
          with_retries do |attempts|
            handle_errors(attempts) do
              res = @conn.get(path) { |req| req.params.update(params) }

              res.body
            end
          end
        rescue Faraday::TimeoutError, Faraday::ConnectionFailed => e
          raise(PsyMantis::Steam::HTTP::Errors::Timeout, cause: e)
        end

        private

        # Creates a new Faraday connection.
        #
        # @param base_url [String] The base URL for the API.
        # @return [Faraday::Connection] The Faraday connection object.
        def new_faraday_connection(base_url)
          Faraday.new(
            url: base_url,
            headers: HEADERS,
            request: { open_timeout: @opts[:open_timeout], read_timeout: @opts[:read_timeout] }
          ) do |f|
            f.request :json
            f.response :raise_error
            f.response :json
          end
        end

        # Handles Faraday HTTP response errors using the FARADAY_ERROR_MAPPING.
        #
        # @param attempts [Integer] The current attempt number.
        # @yield The block to execute.
        # @raise [StandardError] If an error occurs and is mapped.
        def handle_errors(attempts)
          yield
        rescue StandardError => e
          handler = FARADAY_ERROR_MAPPING[e.class]
          raise(handler.call(e, attempts)) if handler.is_a?(Proc)
          raise(handler.new(cause: e)) if handler

          raise(e)
        end

        # Executes a block with retry logic for  errors.
        #
        # @yield [attempts] Gives the current attempt number to the block.
        # @raise [PsyMantis::Steam::HTTP::Errors::RateLimited] If retries are exhausted.
        # @raise [PsyMantis::Steam::HTTP::Errors::Timeout] If retries are exhausted.
        # @raise [PsyMantis::Steam::HTTP::Errors::ServerError] If retries are exhausted.
        def with_retries
          attempts = 0

          begin
            attempts += 1
            yield(attempts)
          rescue PsyMantis::Steam::HTTP::Errors::RateLimited, PsyMantis::Steam::HTTP::Errors::Timeout,
                 PsyMantis::Steam::HTTP::Errors::ServerError => e
            raise e if attempts > @opts[:max_retries]

            sleep_for(retry_delay_for(attempts, e.respond_to?(:retry_after) ? e.retry_after : nil))
            retry
          end
        end

        # Calculates the delay before the next retry.
        #
        # @param attempts [Integer] The current attempt number.
        # @param server_retry_after [Integer, nil] The server-specified retry delay, if any.
        # @return [Float, Integer] The delay in seconds.
        def retry_delay_for(attempts, server_retry_after = nil)
          return server_retry_after if server_retry_after

          base_delay = @opts[:base_backoff] * (2**(attempts - 1))
          @opts[:jitter] ? base_delay * rand(0.8..1.2) : base_delay
        end

        # Sleeps for the specified duration.
        # Used to be stubbed in the tests.
        #
        # @param duration [Float, Integer] The number of seconds to sleep.
        # @return [void]
        def sleep_for(duration)
          sleep(duration)
        end
      end
    end
  end
end
