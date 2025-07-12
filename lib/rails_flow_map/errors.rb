# frozen_string_literal: true

module RailsFlowMap
  # Base error class for all RailsFlowMap errors
  #
  # This class provides a common interface for all errors raised by the
  # RailsFlowMap gem, including error categorization, context preservation,
  # and structured error reporting.
  class Error < StandardError
    attr_reader :context, :error_code, :category

    # Initialize a new error with context and categorization
    #
    # @param message [String] The error message
    # @param context [Hash] Additional context about the error
    # @param error_code [String] Unique error code for programmatic handling
    # @param category [Symbol] Error category for classification
    def initialize(message, context: {}, error_code: nil, category: :general)
      super(message)
      @context = context
      @error_code = error_code || self.class.name.split('::').last.downcase
      @category = category
    end

    # @return [Hash] Full error information including context
    def to_h
      {
        error_class: self.class.name,
        message: message,
        error_code: error_code,
        category: category,
        context: context,
        backtrace: backtrace&.first(10)
      }
    end

    # @return [String] JSON representation of the error
    def to_json(*args)
      require 'json'
      to_h.to_json(*args)
    end
  end

  # Raised when graph parsing fails
  class GraphParseError < Error
    def initialize(message, context: {})
      super(message, context: context, category: :parsing)
    end
  end

  # Raised when graph validation fails
  class GraphValidationError < Error
    def initialize(message, context: {})
      super(message, context: context, category: :validation)
    end
  end

  # Raised when formatter encounters an error
  class FormatterError < Error
    def initialize(message, context: {})
      super(message, context: context, category: :formatting)
    end
  end

  # Raised when file operations fail
  class FileOperationError < Error
    def initialize(message, context: {})
      super(message, context: context, category: :file_operation)
    end
  end

  # Raised when security validation fails
  class SecurityError < Error
    def initialize(message, context: {})
      super(message, context: context, category: :security)
    end
  end

  # Raised when configuration is invalid
  class ConfigurationError < Error
    def initialize(message, context: {})
      super(message, context: context, category: :configuration)
    end
  end

  # Raised when a feature is not implemented
  class NotImplementedError < Error
    def initialize(message = "Feature not yet implemented", context: {})
      super(message, context: context, category: :not_implemented)
    end
  end

  # Raised when invalid input is provided
  class InvalidInputError < Error
    def initialize(message, context: {})
      super(message, context: context, category: :invalid_input)
    end
  end

  # Raised when resource limits are exceeded
  class ResourceLimitError < Error
    def initialize(message, context: {})
      super(message, context: context, category: :resource_limit)
    end
  end

  # Error handling utilities
  module ErrorHandler
    extend self

    # Maximum number of retry attempts for transient errors
    MAX_RETRIES = 3

    # Errors that can be retried
    RETRYABLE_ERRORS = [
      Errno::ENOENT,
      Errno::EACCES,
      Errno::EAGAIN,
      Errno::EWOULDBLOCK
    ].freeze

    # Execute a block with comprehensive error handling
    #
    # @param operation [String] Description of the operation
    # @param context [Hash] Additional context for error reporting
    # @param retries [Integer] Number of retry attempts for transient errors
    # @yield The block to execute
    # @return The result of the block
    # @raise [RailsFlowMap::Error] Re-raised as appropriate RailsFlowMap error
    def with_error_handling(operation, context: {}, retries: MAX_RETRIES)
      attempt = 0

      begin
        Logging.with_context(operation: operation, **context) do
          yield
        end
      rescue *RETRYABLE_ERRORS => e
        attempt += 1
        if attempt <= retries
          Logging.logger.warn("Retrying #{operation} (attempt #{attempt}/#{retries}): #{e.message}")
          sleep(0.1 * attempt) # Exponential backoff
          retry
        else
          handle_error(e, operation, context.merge(max_retries_exceeded: true))
        end
      rescue RailsFlowMap::Error => e
        # Already a RailsFlowMap error, just log and re-raise
        Logging.log_error(e, context: context.merge(operation: operation))
        raise
      rescue => e
        handle_error(e, operation, context)
      end
    end

    # Convert standard errors to RailsFlowMap errors with context
    #
    # @param error [Exception] The original error
    # @param operation [String] Description of the operation that failed
    # @param context [Hash] Additional context
    # @raise [RailsFlowMap::Error] Appropriate RailsFlowMap error type
    def handle_error(error, operation, context = {})
      error_context = context.merge(
        operation: operation,
        original_error: error.class.name
      )

      rails_flow_map_error = case error
      when JSON::ParserError, YAML::SyntaxError
        GraphParseError.new("Failed to parse data during #{operation}: #{error.message}", context: error_context)
      when Errno::ENOENT, Errno::EACCES
        FileOperationError.new("File operation failed during #{operation}: #{error.message}", context: error_context)
      when ArgumentError
        InvalidInputError.new("Invalid input during #{operation}: #{error.message}", context: error_context)
      when SystemStackError
        ResourceLimitError.new("Stack overflow during #{operation}, input too complex", context: error_context)
      when NoMemoryError
        ResourceLimitError.new("Out of memory during #{operation}", context: error_context)
      else
        Error.new("Unexpected error during #{operation}: #{error.message}", context: error_context)
      end

      Logging.log_error(rails_flow_map_error, context: error_context)
      raise rails_flow_map_error
    end

    # Validate input parameters and raise errors if invalid
    #
    # @param validations [Hash] Hash of parameter_name => validation_proc pairs
    # @param context [Hash] Additional context for error reporting
    # @raise [InvalidInputError] If any validation fails
    def validate_input!(validations, context: {})
      validations.each do |param_name, validation|
        begin
          next if validation.call
        rescue => e
          raise InvalidInputError.new(
            "Validation failed for parameter '#{param_name}': #{e.message}",
            context: context.merge(parameter: param_name)
          )
        end

        raise InvalidInputError.new(
          "Invalid value for parameter '#{param_name}'",
          context: context.merge(parameter: param_name)
        )
      end
    end

    # Check if an error is retryable
    #
    # @param error [Exception] The error to check
    # @return [Boolean] True if the error can be retried
    def retryable?(error)
      RETRYABLE_ERRORS.any? { |retryable_class| error.is_a?(retryable_class) }
    end

    # Extract user-friendly error message from any error
    #
    # @param error [Exception] The error to extract message from
    # @return [String] User-friendly error message
    def user_friendly_message(error)
      case error
      when RailsFlowMap::GraphParseError
        "Failed to parse the graph data. Please check your input format."
      when RailsFlowMap::FileOperationError
        "File operation failed. Please check file permissions and paths."
      when RailsFlowMap::InvalidInputError
        "Invalid input provided. #{error.message}"
      when RailsFlowMap::SecurityError
        "Security validation failed. Operation blocked for safety."
      when RailsFlowMap::ResourceLimitError
        "Operation exceeded resource limits. Please try with smaller input."
      when RailsFlowMap::Error
        error.message
      else
        "An unexpected error occurred. Please try again."
      end
    end
  end
end