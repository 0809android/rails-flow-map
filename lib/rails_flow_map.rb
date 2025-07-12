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
  
  module Formatters
    autoload :MermaidFormatter, "rails_flow_map/formatters/mermaid_formatter"
    autoload :PlantUMLFormatter, "rails_flow_map/formatters/plantuml_formatter"
    autoload :GraphVizFormatter, "rails_flow_map/formatters/graphviz_formatter"
    autoload :ErdFormatter, "rails_flow_map/formatters/erd_formatter"
    autoload :MetricsFormatter, "rails_flow_map/formatters/metrics_formatter"
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

    def export(graph, format: :mermaid, output: nil)
      formatter = case format
                  when :mermaid
                    Formatters::MermaidFormatter.new
                  when :plantuml
                    Formatters::PlantUMLFormatter.new
                  when :graphviz, :dot
                    Formatters::GraphVizFormatter.new
                  when :erd
                    Formatters::ErdFormatter.new(graph)
                  when :metrics
                    Formatters::MetricsFormatter.new(graph)
                  when :sequence
                    # Sequence formatter is already implemented in rails-flow-map subdirectory
                    Formatters::MermaidFormatter.new  # Fallback to mermaid for now
                  else
                    raise Error, "Unsupported format: #{format}"
                  end

      result = formatter.format(graph)
      
      if output
        File.write(output, result)
      end
      
      result
    end
  end
end