# frozen_string_literal: true

require 'logger'

module RailsFlowMap
  # Centralized logging functionality for RailsFlowMap
  #
  # This module provides a standardized logging interface across all components
  # of the RailsFlowMap gem. It supports configurable log levels, structured
  # logging, and automatic context inclusion.
  #
  # @example Basic usage
  #   RailsFlowMap::Logging.logger.info("Processing graph with 10 nodes")
  #
  # @example With context
  #   RailsFlowMap::Logging.with_context(formatter: 'MermaidFormatter') do
  #     RailsFlowMap::Logging.logger.debug("Starting format operation")
  #   end
  #
  # @example Error logging with context
  #   begin
  #     risky_operation
  #   rescue => e
  #     RailsFlowMap::Logging.log_error(e, context: { operation: 'export' })
  #   end
  module Logging
    extend self

    # Custom formatter for structured log output
    class StructuredFormatter < Logger::Formatter
      def call(severity, time, progname, msg)
        context = Thread.current[:rails_flow_map_context] || {}
        context_str = context.empty? ? '' : " [#{context.map { |k, v| "#{k}=#{v}" }.join(', ')}]"
        
        "[#{time.strftime('%Y-%m-%d %H:%M:%S')}] #{severity}#{context_str}: #{msg}\n"
      end
    end

    # Custom log levels for domain-specific logging
    CUSTOM_LEVELS = {
      security: Logger::WARN,
      performance: Logger::INFO,
      graph_analysis: Logger::DEBUG
    }.freeze

    # @return [Logger] The shared logger instance
    def logger
      @logger ||= create_logger
    end

    # Sets a custom logger instance
    #
    # @param custom_logger [Logger] The logger to use
    def logger=(custom_logger)
      @logger = custom_logger
    end

    # Log an error with full context and backtrace
    #
    # @param error [Exception] The error to log
    # @param context [Hash] Additional context information
    # @param level [Symbol] Log level (:error, :warn, :info, :debug)
    def log_error(error, context: {}, level: :error)
      error_context = {
        error_class: error.class.name,
        error_message: error.message,
        **context
      }

      with_context(error_context) do
        logger.send(level, "#{error.class}: #{error.message}")
        
        if error.backtrace && logger.level <= Logger::DEBUG
          logger.debug("Backtrace:\n#{error.backtrace.join("\n")}")
        end
      end
    end

    # Execute a block with additional logging context
    #
    # @param context [Hash] Context to add to all log messages in the block
    # @yield The block to execute with context
    def with_context(context = {})
      old_context = Thread.current[:rails_flow_map_context] || {}
      Thread.current[:rails_flow_map_context] = old_context.merge(context)
      
      yield
    ensure
      Thread.current[:rails_flow_map_context] = old_context
    end

    # Log a performance metric
    #
    # @param operation [String] Name of the operation
    # @param duration [Float] Duration in seconds
    # @param additional_metrics [Hash] Additional metrics to log
    def log_performance(operation, duration, additional_metrics = {})
      return unless logger.level <= CUSTOM_LEVELS[:performance]

      metrics = {
        operation: operation,
        duration_seconds: duration.round(3),
        **additional_metrics
      }

      with_context(metrics) do
        logger.info("Performance: #{operation} completed in #{duration.round(3)}s")
      end
    end

    # Log a security event
    #
    # @param event [String] Description of the security event
    # @param severity [Symbol] Severity level (:high, :medium, :low)
    # @param details [Hash] Additional security-related details
    def log_security(event, severity: :medium, details: {})
      return unless logger.level <= CUSTOM_LEVELS[:security]

      security_context = {
        security_event: event,
        severity: severity,
        **details
      }

      with_context(security_context) do
        logger.warn("SECURITY: #{event}")
      end
    end

    # Log graph analysis information
    #
    # @param analysis_type [String] Type of analysis being performed
    # @param graph_metrics [Hash] Metrics about the graph being analyzed
    def log_graph_analysis(analysis_type, graph_metrics = {})
      return unless logger.level <= CUSTOM_LEVELS[:graph_analysis]

      analysis_context = {
        analysis_type: analysis_type,
        **graph_metrics
      }

      with_context(analysis_context) do
        logger.debug("Graph Analysis: #{analysis_type}")
        
        if graph_metrics.any?
          metrics_str = graph_metrics.map { |k, v| "#{k}=#{v}" }.join(', ')
          logger.debug("Graph metrics: #{metrics_str}")
        end
      end
    end

    # Time a block and log its performance
    #
    # @param operation [String] Name of the operation being timed
    # @param additional_metrics [Hash] Additional metrics to include
    # @yield The block to time
    # @return The result of the block
    def time_operation(operation, additional_metrics = {})
      start_time = Time.now
      
      begin
        result = yield
        duration = Time.now - start_time
        log_performance(operation, duration, additional_metrics)
        result
      rescue => e
        duration = Time.now - start_time
        log_error(e, context: { 
          operation: operation, 
          duration_seconds: duration.round(3),
          **additional_metrics 
        })
        raise
      end
    end

    # Configure logging for different environments
    #
    # @param environment [Symbol] The environment (:development, :test, :production)
    # @param options [Hash] Additional configuration options
    def configure_for_environment(environment, options = {})
      case environment
      when :development
        logger.level = Logger::DEBUG
        logger.formatter = StructuredFormatter.new
      when :test
        logger.level = Logger::WARN
        logger.formatter = Logger::Formatter.new
      when :production
        logger.level = Logger::INFO
        logger.formatter = StructuredFormatter.new
      end

      # Apply any custom options
      options.each do |key, value|
        case key
        when :level
          logger.level = value
        when :formatter
          logger.formatter = value
        end
      end
    end

    private

    def create_logger
      logger = Logger.new(STDOUT)
      logger.level = Logger::INFO
      logger.formatter = StructuredFormatter.new
      logger.progname = 'RailsFlowMap'
      logger
    end
  end
end