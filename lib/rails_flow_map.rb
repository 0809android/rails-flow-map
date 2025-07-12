require "set"
require "json"
require "yaml"
require "cgi"
require "rails_flow_map/version"
require "rails_flow_map/configuration"
require "rails_flow_map/logging"
require "rails_flow_map/errors"
require "rails_flow_map/engine" if defined?(Rails)

# RailsFlowMap is a comprehensive tool for visualizing data flows in Rails applications
#
# It analyzes your Rails application's structure and generates various visualization
# formats to help understand the architecture, dependencies, and data flow patterns.
#
# @example Basic usage
#   # Analyze the entire application
#   graph = RailsFlowMap.analyze
#   
#   # Export to different formats
#   RailsFlowMap.export(graph, format: :mermaid, output: 'architecture.md')
#   RailsFlowMap.export(graph, format: :d3js, output: 'interactive.html')
#
# @example Analyzing specific endpoints
#   graph = RailsFlowMap.analyze_endpoint('/api/v1/users')
#   RailsFlowMap.export(graph, format: :sequence, endpoint: '/api/v1/users')
#
# @example Comparing versions
#   before = RailsFlowMap.analyze_at('v1.0.0')
#   after = RailsFlowMap.analyze
#   diff = RailsFlowMap.diff(before, after)
#
module RailsFlowMap

  autoload :ModelAnalyzer, "rails_flow_map/analyzers/model_analyzer"
  autoload :ControllerAnalyzer, "rails_flow_map/analyzers/controller_analyzer"
  autoload :FlowNode, "rails_flow_map/models/flow_node"
  autoload :FlowEdge, "rails_flow_map/models/flow_edge"
  autoload :FlowGraph, "rails_flow_map/models/flow_graph"
  
  autoload :MermaidFormatter, "rails_flow_map/formatters/mermaid_formatter"
  autoload :PlantUMLFormatter, "rails_flow_map/formatters/plantuml_formatter"
  autoload :GraphVizFormatter, "rails_flow_map/formatters/graphviz_formatter"
  autoload :ErdFormatter, "rails_flow_map/formatters/erd_formatter"
  autoload :MetricsFormatter, "rails_flow_map/formatters/metrics_formatter"
  autoload :D3jsFormatter, "rails_flow_map/formatters/d3js_formatter"
  autoload :OpenapiFormatter, "rails_flow_map/formatters/openapi_formatter"
  autoload :SequenceFormatter, "rails_flow_map/formatters/sequence_formatter"
  autoload :GitDiffFormatter, "rails_flow_map/formatters/git_diff_formatter"
  
  module Formatters
    # For backwards compatibility
  end

  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    # Configures RailsFlowMap
    #
    # @yield [Configuration] The configuration object
    # @example
    #   RailsFlowMap.configure do |config|
    #     config.include_models = true
    #     config.include_controllers = true
    #     config.output_dir = 'doc/flow_maps'
    #   end
    def configure
      yield(configuration)
    end
    
    # Analyzes the Rails application and builds a flow graph
    #
    # @param options [Hash] Analysis options
    # @option options [Boolean] :models Include model analysis (default: true)
    # @option options [Boolean] :controllers Include controller analysis (default: true)
    # @option options [Boolean] :routes Include route analysis (default: true)
    # @option options [Boolean] :services Include service analysis (default: true)
    # @return [FlowGraph] The analyzed application graph
    # @raise [GraphParseError] If analysis fails
    def analyze(options = {})
      ErrorHandler.with_error_handling("analyze", context: { options: options }) do
        Logging.time_operation("graph_analysis", { analyzers: options.keys }) do
          graph = FlowGraph.new
          
          analyzers_run = []
          
          if options[:models] != false
            analyzers_run << "models"
            ModelAnalyzer.new(graph).analyze
          end
          
          if options[:controllers] != false
            analyzers_run << "controllers"
            ControllerAnalyzer.new(graph).analyze
          end
          
          Logging.log_graph_analysis("completed", {
            nodes: graph.nodes.size,
            edges: graph.edges.size,
            analyzers: analyzers_run.join(", ")
          })
          
          graph
        end
      end
    end

    # Exports a flow graph to various visualization formats
    #
    # @param graph [FlowGraph] The graph to export
    # @param format [Symbol] The output format (:mermaid, :plantuml, :graphviz, :erd, :metrics, :d3js, :openapi, :sequence)
    # @param output [String, nil] The output file path (returns string if nil)
    # @param options [Hash] Format-specific options
    # @return [String] The formatted output
    # @raise [FormatterError] If formatting fails
    # @raise [FileOperationError] If file writing fails
    # @raise [InvalidInputError] If input parameters are invalid
    # @raise [SecurityError] If security validation fails
    # @example Export to Mermaid
    #   RailsFlowMap.export(graph, format: :mermaid, output: 'flow.md')
    # @example Export to interactive HTML
    #   RailsFlowMap.export(graph, format: :d3js, output: 'interactive.html')
    def export(graph, format: :mermaid, output: nil, **options)
      ErrorHandler.with_error_handling("export", context: { format: format, output: output }) do
        # Input validation
        ErrorHandler.validate_input!({
          graph: -> { graph.is_a?(FlowGraph) || graph.nil? },
          format: -> { format.is_a?(Symbol) },
          output: -> { output.nil? || output.is_a?(String) }
        }, context: { operation: "export" })

        # Security validation for output path
        if output
          validate_output_path!(output)
        end

        Logging.time_operation("export", { format: format, nodes: graph&.nodes&.size || 0 }) do
          formatter = create_formatter(format, graph, options)
          
          Logging.with_context(formatter: formatter.class.name) do
            result = formatter.format(graph)
            
            if output
              write_output_file(output, result)
              Logging.logger.info("Successfully exported to #{output}")
            end
            
            result
          end
        end
      end
    end
    
    # Compares two graphs and generates a diff visualization
    #
    # @param before_graph [FlowGraph] The "before" state graph
    # @param after_graph [FlowGraph] The "after" state graph
    # @param format [Symbol] The output format (:mermaid, :html, :text)
    # @param options [Hash] Additional options for the formatter
    # @return [String] The formatted diff
    # @example
    #   before = RailsFlowMap.analyze_at('main')
    #   after = RailsFlowMap.analyze
    #   diff = RailsFlowMap.diff(before, after, format: :mermaid)
    def diff(before_graph, after_graph, format: :mermaid, **options)
      formatter = GitDiffFormatter.new(before_graph, after_graph, options.merge(format: format))
      formatter.format
    end
    
    # Analyzes the application at a specific Git reference
    #
    # @param ref [String] The Git reference (branch, tag, or commit SHA)
    # @return [FlowGraph] The analyzed graph at the specified reference
    # @note This is currently a placeholder implementation that returns the current state.
    #       A full implementation would require Git integration to checkout the ref,
    #       analyze, and return to the original state.
    # @example
    #   graph = RailsFlowMap.analyze_at('v1.0.0')
    #   graph = RailsFlowMap.analyze_at('main')
    #   graph = RailsFlowMap.analyze_at('abc123f')
    def analyze_at(ref)
      # Note: This is a placeholder implementation
      # In a real implementation, you would:
      # 1. Save current changes
      # 2. Checkout the specified ref
      # 3. Run analysis
      # 4. Return to original state
      # 
      # For now, returns current state
      analyze
    end

    private

    # Creates the appropriate formatter instance
    #
    # @param format [Symbol] The format to create
    # @param graph [FlowGraph] The graph to format
    # @param options [Hash] Format-specific options
    # @return [Object] The formatter instance
    # @raise [InvalidInputError] If the format is unsupported
    def create_formatter(format, graph, options)
      case format
      when :mermaid
        MermaidFormatter.new
      when :plantuml
        PlantUMLFormatter.new
      when :graphviz, :dot
        GraphVizFormatter.new
      when :erd
        ErdFormatter.new(graph)
      when :metrics
        MetricsFormatter.new(graph)
      when :d3js
        D3jsFormatter.new(graph, options)
      when :openapi
        OpenapiFormatter.new(graph, options)
      when :sequence
        SequenceFormatter.new(graph, options)
      when :git_diff
        raise InvalidInputError.new(
          "Git diff requires two graphs. Use RailsFlowMap.diff instead",
          context: { format: format }
        )
      else
        raise InvalidInputError.new(
          "Unsupported format: #{format}",
          context: { format: format, supported_formats: [:mermaid, :plantuml, :graphviz, :erd, :metrics, :d3js, :openapi, :sequence] }
        )
      end
    rescue => e
      raise FormatterError.new(
        "Failed to create formatter for format #{format}: #{e.message}",
        context: { format: format, original_error: e.class.name }
      )
    end

    # Validates that the output path is safe to write to
    #
    # @param output_path [String] The path to validate
    # @raise [SecurityError] If the path is unsafe
    # @raise [FileOperationError] If the path is invalid
    def validate_output_path!(output_path)
      # Check for path traversal attempts
      if output_path.include?('..') && File.absolute_path(output_path).include?('..')
        Logging.log_security("Path traversal attempt blocked", details: { path: output_path })
        raise SecurityError.new(
          "Path traversal detected in output path",
          context: { path: output_path }
        )
      end

      # Check for dangerous file paths
      dangerous_paths = ['/etc/', '/bin/', '/usr/bin/', '/sbin/', '/usr/sbin/', '/var/', '/boot/', '/proc/', '/sys/', '/dev/']
      absolute_path = File.absolute_path(output_path)
      
      if dangerous_paths.any? { |dangerous| absolute_path.start_with?(dangerous) }
        Logging.log_security("Dangerous output path blocked", details: { path: output_path })
        raise SecurityError.new(
          "Output path points to a system directory",
          context: { path: output_path, absolute_path: absolute_path }
        )
      end

      # Check parent directory exists and is writable
      parent_dir = File.dirname(output_path)
      unless File.directory?(parent_dir)
        raise FileOperationError.new(
          "Parent directory does not exist: #{parent_dir}",
          context: { path: output_path, parent_dir: parent_dir }
        )
      end

      unless File.writable?(parent_dir)
        raise FileOperationError.new(
          "Parent directory is not writable: #{parent_dir}",
          context: { path: output_path, parent_dir: parent_dir }
        )
      end
    end

    # Safely writes content to the output file
    #
    # @param output_path [String] The path to write to
    # @param content [String] The content to write
    # @raise [FileOperationError] If writing fails
    def write_output_file(output_path, content)
      begin
        File.write(output_path, content)
      rescue Errno::ENOSPC
        raise FileOperationError.new(
          "No space left on device when writing to #{output_path}",
          context: { path: output_path, content_size: content.bytesize }
        )
      rescue Errno::EACCES
        raise FileOperationError.new(
          "Permission denied when writing to #{output_path}",
          context: { path: output_path }
        )
      rescue => e
        raise FileOperationError.new(
          "Failed to write to #{output_path}: #{e.message}",
          context: { path: output_path, original_error: e.class.name }
        )
      end
    end
  end
end