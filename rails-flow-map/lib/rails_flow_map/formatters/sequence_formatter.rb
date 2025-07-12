module RailsFlowMap
  class SequenceFormatter
    def format(graph, endpoint: nil)
      if endpoint
        format_endpoint_flow(graph, endpoint)
      else
        format_all_sequences(graph)
      end
    end
    
    private
    
    def format_endpoint_flow(graph, endpoint)
      lines = ["sequenceDiagram"]
      
      # Find the route node for this endpoint
      route_node = find_route_by_endpoint(graph, endpoint)
      return "No route found for endpoint: #{endpoint}" unless route_node
      
      lines << "    participant Client"
      lines << "    participant Route"
      lines << "    participant Controller"
      lines << "    participant Action"
      
      # Add models and services as participants
      models = find_connected_models(graph, route_node)
      services = find_connected_services(graph, route_node)
      
      models.each do |model|
        lines << "    participant #{model.name}"
      end
      
      services.each do |service|
        lines << "    participant #{service.name}"
      end
      
      lines << "    participant Response"
      lines << ""
      
      # Generate sequence steps
      action_node = find_action_for_route(graph, route_node)
      if action_node
        lines += generate_sequence_steps(graph, route_node, action_node, models, services)
      end
      
      lines.join("\n")
    end
    
    def format_all_sequences(graph)
      lines = ["sequenceDiagram"]
      lines << "    Note over Client,Response: All API Endpoints Flow"
      lines << ""
      
      route_nodes = graph.nodes_by_type(:route)
      
      route_nodes.first(5).each_with_index do |route, index|  # Limit to first 5 for readability
        lines << "    Note over Client,Response: #{route.name}"
        action_node = find_action_for_route(graph, route)
        if action_node
          lines << "    Client->>+Action: #{route.name}"
          lines << "    Action-->>-Client: Response"
          lines << ""
        end
      end
      
      lines.join("\n")
    end
    
    def find_route_by_endpoint(graph, endpoint)
      route_nodes = graph.nodes_by_type(:route)
      
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
      Rails.logger&.warn "Failed to find matching route in SequenceFormatter: #{e.message}"
      nil
    end
    
    def find_action_for_route(graph, route_node)
      edges = graph.edges.select { |e| e.from == route_node.id && e.type == :routes_to }
      return nil if edges.empty?
      
      graph.find_node(edges.first.to)
    end
    
    def find_connected_models(graph, route_node)
      action_node = find_action_for_route(graph, route_node)
      return [] unless action_node
      
      model_edges = graph.edges.select { |e| e.from == action_node.id && e.type == :accesses_model }
      model_edges.map { |e| graph.find_node(e.to) }.compact
    end
    
    def find_connected_services(graph, route_node)
      action_node = find_action_for_route(graph, route_node)
      return [] unless action_node
      
      service_edges = graph.edges.select { |e| e.from == action_node.id && e.type == :calls_service }
      service_edges.map { |e| graph.find_node(e.to) }.compact
    end
    
    def generate_sequence_steps(graph, route_node, action_node, models, services)
      lines = []
      
      # 1. Client to Route
      lines << "    Client->>+Route: #{route_node.name}"
      
      # 2. Route to Controller/Action
      lines << "    Route->>+Action: Execute #{action_node.name}"
      
      # 3. Action to Services
      services.each do |service|
        lines << "    Action->>+#{service.name}: Call service"
        lines << "    #{service.name}-->>-Action: Return result"
      end
      
      # 4. Action to Models
      models.each do |model|
        method_edge = graph.edges.find { |e| e.from == action_node.id && e.to == model.id }
        method_name = method_edge&.label || "query"
        lines << "    Action->>+#{model.name}: #{method_name}"
        lines << "    #{model.name}-->>-Action: Return data"
      end
      
      # 5. Response generation
      response_edges = graph.edges.select { |e| e.from == action_node.id && e.type == :responds_with }
      if response_edges.any?
        response_method = response_edges.first.label
        lines << "    Action->>Response: #{response_method}"
      end
      
      # 6. Return to client
      lines << "    Action-->>-Route: Processing complete"
      lines << "    Route-->>-Client: HTTP Response"
      
      lines
    end
  end
end