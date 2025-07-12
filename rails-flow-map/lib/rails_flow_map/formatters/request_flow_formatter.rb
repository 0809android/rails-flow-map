module RailsFlowMap
  class RequestFlowFormatter
    def format(graph, endpoint: nil)
      if endpoint
        format_specific_endpoint(graph, endpoint)
      else
        format_all_endpoints(graph)
      end
    end
    
    private
    
    def format_specific_endpoint(graph, endpoint)
      lines = ["graph TD"]
      lines << "    %% Request Flow for #{endpoint}"
      lines << ""
      
      # Find the route node for this endpoint
      route_node = find_route_by_endpoint(graph, endpoint)
      return "No route found for endpoint: #{endpoint}" unless route_node
      
      # Generate flow for this specific endpoint
      visited_nodes = Set.new
      flow_lines = []
      
      generate_flow_from_node(graph, route_node, visited_nodes, flow_lines, 0)
      
      lines += flow_lines
      lines += generate_styling
      
      lines.join("\n")
    end
    
    def format_all_endpoints(graph)
      lines = ["graph TD"]
      lines << "    %% Complete Request Flow Map"
      lines << ""
      
      # Add all nodes
      graph.nodes.each do |id, node|
        lines << format_node(node)
      end
      
      lines << ""
      
      # Add all edges
      graph.edges.each do |edge|
        formatted_edge = format_edge(edge, graph)
        lines << formatted_edge if formatted_edge
      end
      
      lines += generate_styling
      
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

      # Fallback to name or controller inclusion for backward compatibility
      route_nodes.find do |route|
        route.name.include?(endpoint) || 
        route.attributes[:controller].to_s.include?(endpoint)
      end
    rescue => e
      Rails.logger&.warn "Failed to find matching route in RequestFlowFormatter: #{e.message}"
      nil
    end
    
    def generate_flow_from_node(graph, node, visited, lines, depth)
      return if visited.include?(node.id)
      visited.add(node.id)
      
      # Add current node
      lines << "    #{format_node(node)}"
      
      # Find outgoing edges
      outgoing_edges = graph.edges.select { |e| e.from == node.id }
      
      outgoing_edges.each do |edge|
        target_node = graph.find_node(edge.to)
        next unless target_node
        
        # Add edge
        lines << "    #{format_edge(edge, graph)}"
        
        # Recursively process target node (with depth limit)
        if depth < 3
          generate_flow_from_node(graph, target_node, visited, lines, depth + 1)
        end
      end
    end
    
    def format_node(node)
      label = escape_mermaid(node.name)
      shape = case node.type
              when :route
                "#{node.id}[fa:fa-globe #{label}]"
              when :controller
                "#{node.id}[[fa:fa-cogs #{label}]]"
              when :action
                "#{node.id}(fa:fa-play #{label})"
              when :model
                "#{node.id}[(fa:fa-database #{label})]"
              when :service
                "#{node.id}{fa:fa-wrench #{label}}"
              when :response
                "#{node.id}[fa:fa-reply #{label}]"
              else
                "#{node.id}[#{label}]"
              end
      shape
    end
    
    def format_edge(edge, graph)
      from_node = graph.find_node(edge.from)
      to_node = graph.find_node(edge.to)
      
      return nil unless from_node && to_node
      
      arrow = case edge.type
              when :routes_to
                "==>"
              when :has_action
                "-.->"
              when :accesses_model
                "-->"
              when :calls_service
                "==>"
              when :responds_with
                "-->"
              else
                "-->"
              end
      
      label = edge.label ? "|#{escape_mermaid(edge.label.to_s)}|" : ""
      
      "#{edge.from} #{arrow}#{label} #{edge.to}"
    end
    
    def generate_styling
      [
        "",
        "%% Styling",
        "classDef route fill:#FFE4E1,stroke:#FF6B6B,stroke-width:2px;",
        "classDef controller fill:#E1F5FE,stroke:#29B6F6,stroke-width:2px;",
        "classDef action fill:#E8F5E8,stroke:#66BB6A,stroke-width:2px;",
        "classDef model fill:#F3E5F5,stroke:#AB47BC,stroke-width:2px;",
        "classDef service fill:#FFF3E0,stroke:#FF9800,stroke-width:2px;",
        "classDef response fill:#F1F8E9,stroke:#8BC34A,stroke-width:2px;",
        "",
        "class #{collect_nodes_by_type(:route)} route;",
        "class #{collect_nodes_by_type(:controller)} controller;",
        "class #{collect_nodes_by_type(:action)} action;",
        "class #{collect_nodes_by_type(:model)} model;",
        "class #{collect_nodes_by_type(:service)} service;",
        "class #{collect_nodes_by_type(:response)} response;"
      ]
    end
    
    def collect_nodes_by_type(type)
      # This would need access to the graph, so we'll use a placeholder
      "node_#{type}"
    end
    
    def escape_mermaid(text)
      text.gsub(/[<>{}"|]/, {
        '<' => '&lt;',
        '>' => '&gt;',
        '{' => '&#123;',
        '}' => '&#125;',
        '"' => '&quot;',
        '|' => '&#124;'
      })
    end
  end
end