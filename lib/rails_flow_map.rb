require "set"
require "json"
require "yaml"
require "rails_flow_map/version"
require "rails_flow_map/configuration"
require "rails_flow_map/engine" if defined?(Rails)

module RailsFlowMap
  class Error < StandardError; end

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

    def configure
      yield(configuration)
    end
    def analyze(options = {})
      graph = FlowGraph.new
      
      if options[:models] != false
        ModelAnalyzer.new(graph).analyze
      end
      
      if options[:controllers] != false
        ControllerAnalyzer.new(graph).analyze
      end
      
      graph
    end

    def export(graph, format: :mermaid, output: nil, **options)
      formatter = case format
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
                    raise Error, "Git diff requires two graphs. Use RailsFlowMap.diff instead"
                  else
                    raise Error, "Unsupported format: #{format}"
                  end

      result = formatter.format(graph)
      
      if output
        File.write(output, result)
      end
      
      result
    end
    
    def diff(before_graph, after_graph, format: :mermaid, **options)
      formatter = GitDiffFormatter.new(before_graph, after_graph, options.merge(format: format))
      formatter.format
    end
    
    def analyze_at(ref)
      # Simplified version - would need Git integration
      analyze
    end
  end
end