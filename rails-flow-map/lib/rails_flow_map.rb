require "rails_flow_map/version"
require "rails_flow_map/configuration" 
require "rails_flow_map/engine" if defined?(Rails)
require "set"

module RailsFlowMap
  class Error < StandardError; end

  autoload :ModelAnalyzer, "rails_flow_map/analyzers/model_analyzer"
  autoload :ControllerAnalyzer, "rails_flow_map/analyzers/controller_analyzer"
  autoload :RouteAnalyzer, "rails_flow_map/analyzers/route_analyzer"
  autoload :RequestFlowAnalyzer, "rails_flow_map/analyzers/request_flow_analyzer"
  autoload :FlowNode, "rails_flow_map/models/flow_node"
  autoload :FlowEdge, "rails_flow_map/models/flow_edge"
  autoload :FlowGraph, "rails_flow_map/models/flow_graph"
  autoload :MermaidFormatter, "rails_flow_map/formatters/mermaid_formatter"
  autoload :PlantUMLFormatter, "rails_flow_map/formatters/plantuml_formatter"
  autoload :GraphVizFormatter, "rails_flow_map/formatters/graphviz_formatter"
  autoload :SequenceFormatter, "rails_flow_map/formatters/sequence_formatter"
  autoload :RequestFlowFormatter, "rails_flow_map/formatters/request_flow_formatter"
  autoload :ApiDocumentationFormatter, "rails_flow_map/formatters/api_documentation_formatter"

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
      
      if options[:routes] != false
        RouteAnalyzer.new(graph).analyze
      end
      
      if options[:request_flow] != false
        RequestFlowAnalyzer.new(graph).analyze
      end
      
      graph
    end

    def analyze_endpoint(endpoint, options = {})
      graph = FlowGraph.new
      
      # Analyze all components for endpoint-specific flow
      RouteAnalyzer.new(graph).analyze
      ControllerAnalyzer.new(graph).analyze
      ModelAnalyzer.new(graph).analyze
      RequestFlowAnalyzer.new(graph).analyze
      
      # Filter for specific endpoint
      filter_graph_for_endpoint(graph, endpoint)
    end

    def export(graph, format: :mermaid, output: nil, endpoint: nil)
      formatter = case format
                  when :mermaid
                    MermaidFormatter.new
                  when :plantuml
                    PlantUMLFormatter.new
                  when :graphviz, :dot
                    GraphVizFormatter.new
                  when :sequence
                    SequenceFormatter.new
                  when :request_flow
                    RequestFlowFormatter.new
                  when :api_docs, :documentation
                    ApiDocumentationFormatter.new
                  else
                    raise Error, "Unsupported format: #{format}"
                  end

      result = if formatter.respond_to?(:format) && 
                  formatter.method(:format).arity > 1
                 formatter.format(graph, endpoint: endpoint)
               else
                 formatter.format(graph)
               end
      
      if output
        File.write(output, result)
      else
        result
      end
    end

    private

    def filter_graph_for_endpoint(graph, endpoint)
      # Find the route for this endpoint with more precise matching
      route_nodes = graph.nodes_by_type(:route)
      target_route = find_matching_route(route_nodes, endpoint)
      
      return graph unless target_route
      
      # Create new filtered graph
      filtered_graph = FlowGraph.new
      
      # Add the route and trace all connected nodes
      visited = Set.new
      trace_connected_nodes(graph, filtered_graph, target_route, visited)
      
      filtered_graph
    end

    def find_matching_route(route_nodes, endpoint)
      # Exact path match first
      exact_match = route_nodes.find do |route|
        route.attributes[:path].to_s == endpoint
      end
      return exact_match if exact_match

      # Path pattern match (for parameterized routes)
      pattern_match = route_nodes.find do |route|
        path_pattern = route.attributes[:path].to_s
        # Convert Rails route pattern to regex for matching
        regex_pattern = path_pattern.gsub(/:\w+/, '[^/]+').gsub('*', '.*')
        endpoint.match?(/\A#{regex_pattern}\z/)
      end
      return pattern_match if pattern_match

      # Fallback to name inclusion for backward compatibility
      route_nodes.find do |route|
        route.name.include?(endpoint)
      end
    rescue => e
      Rails.logger&.warn "Failed to find matching route: #{e.message}"
      nil
    end

    def trace_connected_nodes(source_graph, target_graph, node, visited)
      return if visited.include?(node.id)
      visited.add(node.id)
      
      # Add the node
      target_graph.add_node(node)
      
      # Find all edges connected to this node
      connected_edges = source_graph.edges.select do |edge|
        edge.from == node.id || edge.to == node.id
      end
      
      connected_edges.each do |edge|
        target_graph.add_edge(edge)
        
        # Recursively add connected nodes
        other_node_id = edge.from == node.id ? edge.to : edge.from
        other_node = source_graph.find_node(other_node_id)
        
        if other_node
          trace_connected_nodes(source_graph, target_graph, other_node, visited)
        end
      end
    end
  end
end