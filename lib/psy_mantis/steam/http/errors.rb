# frozen_string_literal: true

module PsyMantis
  module Steam
    module HTTP
      module Errors
        # Raised when a request is rate limited by the server.
        class RateLimited < StandardError
          # @return [Integer, nil] The number of seconds to wait before retrying.
          attr_reader :retry_after
          # @return [Integer, nil] The number of attempts made.
          attr_reader :attempts
          # @return [Exception, nil] The underlying cause of the error.
          attr_reader :cause

          # @param msg [String] The error message.
          # @param retry_after [Integer, nil] Seconds to wait before retrying.
          # @param attempts [Integer, nil] Number of attempts made.
          # @param cause [Exception, nil] The underlying cause.
          def initialize(msg = 'Rate limited', retry_after: nil, attempts: nil, cause: nil)
            super(msg)
            @retry_after = retry_after
            @attempts    = attempts
            @cause       = cause
          end
        end

        # Raised when a request is unauthorized.
        class Unauthorized < StandardError
          # @return [Exception, nil] The underlying cause of the error.
          attr_reader :cause

          # @param msg [String] The error message.
          # @param cause [Exception, nil] The underlying cause.
          def initialize(msg = 'Unauthorized', cause: nil)
            super(msg)
            @cause = cause
          end
        end

        # Raised when a request is forbidden.
        class Forbidden < StandardError
          # @return [Exception, nil] The underlying cause of the error.
          attr_reader :cause

          # @param msg [String] The error message.
          # @param cause [Exception, nil] The underlying cause.
          def initialize(msg = 'Forbidden', cause: nil)
            super(msg)
            @cause = cause
          end
        end

        # Raised when a server error occurs.
        class ServerError < StandardError
          # @return [Exception, nil] The underlying cause of the error.
          attr_reader :cause

          # @param msg [String] The error message.
          # @param cause [Exception, nil] The underlying cause.
          def initialize(msg = 'Server error', cause: nil)
            super(msg)
            @cause = cause
          end
        end

        # Raised when a request times out.
        class Timeout < StandardError
          # @return [Exception, nil] The underlying cause of the error.
          attr_reader :cause

          # @param msg [String] The error message.
          # @param cause [Exception, nil] The underlying cause.
          def initialize(msg = 'Timeout', cause: nil)
            super(msg)
            @cause = cause
          end
        end

        # Raised when a requested resource is not found.
        class NotFound < StandardError
          # @return [Exception, nil] The underlying cause of the error.
          attr_reader :cause

          # @param msg [String] The error message.
          # @param cause [Exception, nil] The underlying cause.
          def initialize(msg = 'Not Found', cause: nil)
            super(msg)

            @cause = cause
          end
        end
      end
    end
  end
end
