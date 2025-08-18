# frozen_string_literal: true

require 'logger'

module PsyMantis
  # PsyMantis::Env centralizes access to environment variables
  # required by the application, enforcing strict validation
  # and providing defaults where applicable.
  #
  # This class is designed to:
  # - Validate the presence and correctness of critical environment variables
  #   at application startup.
  # - Provide accessor methods for common configuration keys.
  # - Offer helpers to check the current environment and log level.
  #
  # Environment Variables:
  # - RACK_ENV (required, must be one of: "development", "test", "production")
  # - STEAM_API_KEY(required in non test environments)
  # - LOG_LEVEL (optional, must be one of: "DEBUG", "INFO", "WARN", "ERROR", "FATAL")
  # - HOST (optional, default: "0.0.0.0")
  # - CONTAINER_PORT (optional, default: "4567")
  # - HOST_PORT (optional, default: "4567")
  # - COVERAGE (optional, enables SimpleCov if set to "true")
  #
  # Example:
  #   PsyMantis::Env.check_required_env!  # Abort if RACK_ENV is missing/invalid
  #   PsyMantis::Env.log_level            # => ::Logger::INFO
  #
  class Env
    # List of valid environments for the application.
    #
    # @return [Array<String>]
    ENVIRONMENTS = %w[development test production].freeze

    # Mapping of string log level names to their corresponding
    # Logger constant values.
    #
    # @return [Hash<Integer>] where Integer is a Logger constant (e.g., ::Logger::INFO)
    LOG_LEVELS = {
      'DEBUG' => ::Logger::DEBUG,
      'INFO' => ::Logger::INFO,
      'WARN' => ::Logger::WARN,
      'ERROR' => ::Logger::ERROR,
      'FATAL' => ::Logger::FATAL
    }.freeze

    # Validates that all required environment variables are present and valid.
    # Aborts the application with an error message if any are missing or invalid.
    #
    # @return [void]
    def self.check_required_env!
      missing_vars = []
      missing_vars << 'RACK_ENV' unless valid_rack_env?
      missing_vars << 'STEAM_API_KEY' if rack_env != 'test' && steam_api_key.nil?
      return if missing_vars.empty?

      Kernel.abort("Aborting for missing or invalid required environment variables: #{missing_vars.join(', ')}")
    end

    # Checks whether the current RACK_ENV is valid.
    #
    # @return [Boolean] true if RACK_ENV is one of: "development", "test", "production"
    def self.valid_rack_env?
      ENVIRONMENTS.include?(rack_env)
    end

    # Returns the current RACK_ENV value.
    #
    # @return [String, nil] the RACK_ENV value, or nil if not set
    def self.rack_env
      environment = ENV['RACK_ENV']
      Kernel.warn('RACK_ENV is not set!') if environment.nil?
      environment
    end

    # Returnd the current STEAM_API_KEY value.
    #
    # @return [String, nil] the STEAM_API_KEY value, or nil if not set
    def self.steam_api_key
      key = ENV['STEAM_API_KEY'] || nil
      Kernel.warn('STEAM_API_KEY is not set!') if key.nil?
      key
    end

    # Returns the log level constant based on LOG_LEVEL.
    # Defaults to ::Logger::INFO if LOG_LEVEL is not set or invalid.
    #
    # @return [Integer] a Logger constant (e.g., ::Logger::INFO)
    def self.log_level
      raw_level = ENV['LOG_LEVEL']&.upcase
      return LOG_LEVELS[raw_level] if LOG_LEVELS.key?(raw_level)

      Kernel.warn("Invalid LOG_LEVEL '#{raw_level || 'nil'}', defaulting to INFO")
      ::Logger::INFO
    end

    # Returns the host to bind the application to.
    #
    # @return [String] the host value, defaults to "0.0.0.0"
    def self.host
      ENV.fetch('HOST', '0.0.0.0')
    end

    # Returns the internal container port.
    #
    # @return [Integer] the container port, defaults to 4567
    def self.container_port
      ENV.fetch('CONTAINER_PORT', '4567').to_i
    end

    # Returns the port exposed on the host machine.
    #
    # @return [Integer] the host port, defaults to 4567
    def self.host_port
      ENV.fetch('HOST_PORT', '4567').to_i
    end

    # Checks if code coverage reporting should be enabled.
    #
    # @return [Boolean] true if COVERAGE is set to "true"
    def self.coverage_enabled?
      ENV['COVERAGE']&.downcase == 'true'
    end

    # Checks if the application is running in the test environment.
    #
    # @return [Boolean]
    def self.test_env?
      rack_env == 'test'
    end

    # Checks if the application is running in the development environment.
    #
    # @return [Boolean]
    def self.development_env?
      rack_env == 'development'
    end

    # Checks if the application is running in the production environment.
    #
    # @return [Boolean]
    def self.production_env?
      rack_env == 'production'
    end

    # Checks whether the current log level is less than or equal to a given threshold.
    #
    # @param threshold [Integer, String, Symbol] the target log level
    # @return [Boolean] true if current log level <= target
    # @raise [ArgumentError] if threshold is not a recognized log level
    def self.logs?(threshold)
      target =
        case threshold
        when Integer then threshold
        when String, Symbol
          LOG_LEVELS[threshold.to_s.upcase] || raise(ArgumentError, "Unknown log level: #{threshold.inspect}")
        else
          raise ArgumentError, "Threshold must be Integer, String or Symbol (given: #{threshold.class})"
        end

      log_level <= target
    end
  end
end
