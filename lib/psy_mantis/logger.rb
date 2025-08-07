# frozen_string_literal: true

require 'logger'

module PsyMantis
  # PsyMantis::Logger is a wrapper around Ruby's standard Logger,
  # providing configurability from environment variables and dynamic delegation.
  #
  # This class is intended for use inside Sinatra applications or other services
  # that require structured logging with a pluggable interface.
  #
  # All method calls not explicitly defined in this class are automatically
  # delegated to the internal Logger instance via `method_missing` and
  # `respond_to_missing?`. This allows full access to the standard Logger API
  # while retaining the flexibility to extend or customize logging behavior.
  #
  # Example:
  #   logger = PsyMantis::Logger.initialize_from_env
  #   logger.info("App started")  # Delegated to internal Logger
  #
  # Environment Variables:
  # - LOG_LEVEL: DEBUG, INFO, WARN, ERROR, FATAL (defaults to INFO)
  class Logger
    # Initializes a new logger instance.
    #
    # @param io [IO] the output stream (defaults to $stdout)
    # @param level [Integer] the Logger log level (e.g., Logger::INFO)
    def initialize(io = $stdout, level: ::Logger::INFO)
      @logger = ::Logger.new(io)
      @logger.level = level
    end

    # Builds a configured logger based on environment variables.
    #
    # @param env [Hash] the environment hash (defaults to ENV)
    # @return [PsyMantis::Logger] an instance with level configured from LOG_LEVEL
    def self.initialize_from_env(env = ENV)
      @logger = Logger.new($stdout)
      @logger.level = log_level_from_env(env)

      @logger
    end

    # Resolves the log level from environment variables.
    #
    # @param env [Hash] the environment hash
    # @return [Integer] a constant from Logger (e.g., Logger::INFO)
    def self.log_level_from_env(env)
      log_level = env.fetch('LOG_LEVEL', 'INFO').upcase

      begin
        Object.const_get("::Logger::#{log_level}")
      rescue NameError
        puts "Invalid LOG_LEVEL '#{log_level}', defaulting to INFO" if ENV['RACK_ENV']&.upcase != 'TEST'
        ::Logger::INFO
      end
    end

    # Checks whether the underlying logger responds to a method.
    #
    # @param method [Symbol] the method name being checked
    # @param include_private [Boolean] whether to include private methods
    # @return [Boolean] true if the method exists on the internal logger
    def respond_to_missing?(method, include_private = false)
      @logger.respond_to?(method, include_private)
    end

    # Delegates missing methods to the internal logger instance.
    #
    # @param method [Symbol] the method name being called
    # @param args [Array] any arguments passed to the method
    # @param block [Proc] optional block passed to the method
    # @return [Object] the return value from the delegated logger method
    def method_missing(method, *args, &block)
      @logger.send(method, *args, &block)
    end
  end
end
