module RailsFlowMap
  class ApiDocumentationFormatter
    def format(graph, options = {})
      lines = ["# API エンドポイント ドキュメント"]
      lines << ""
      lines << "このドキュメントは自動生成されたAPIエンドポイントの詳細です。"
      lines << ""
      
      # Group routes by controller
      routes_by_controller = group_routes_by_controller(graph)
      
      routes_by_controller.each do |controller_name, routes|
        lines += format_controller_section(graph, controller_name, routes)
        lines << ""
      end
      
      # Add flow diagrams section
      lines += generate_flow_diagrams_section(graph)
      
      lines.join("\n")
    end
    
    private
    
    def group_routes_by_controller(graph)
      routes = graph.nodes_by_type(:route)
      grouped = {}
      
      routes.each do |route|
        controller = route.attributes[:controller]
        next unless controller
        
        grouped[controller] ||= []
        grouped[controller] << route
      end
      
      grouped
    end
    
    def format_controller_section(graph, controller_name, routes)
      lines = ["## #{controller_name.camelize}Controller"]
      lines << ""
      
      routes.each do |route|
        lines += format_route_documentation(graph, route)
        lines << ""
      end
      
      lines
    end
    
    def format_route_documentation(graph, route)
      lines = []
      verb = route.attributes[:verb]
      path = route.attributes[:path]
      action = route.attributes[:action]
      
      lines << "### #{verb} #{path}"
      lines << ""
      lines << "**アクション**: `#{action}`"
      lines << ""
      
      # Find the action node
      action_node = find_action_for_route(graph, route)
      if action_node
        lines += generate_action_details(graph, action_node)
      end
      
      # Generate flow diagram for this endpoint
      lines << "#### フロー図"
      lines << ""
      lines << "```mermaid"
      lines += generate_endpoint_flow(graph, route)
      lines << "```"
      lines << ""
      
      lines
    end
    
    def find_action_for_route(graph, route)
      edges = graph.edges.select { |e| e.from == route.id && e.type == :routes_to }
      return nil if edges.empty?
      
      graph.find_node(edges.first.to)
    end
    
    def generate_action_details(graph, action_node)
      lines = []
      
      # Find models accessed
      model_edges = graph.edges.select { |e| e.from == action_node.id && e.type == :accesses_model }
      if model_edges.any?
        lines << "**アクセスするモデル**:"
        lines << ""
        model_edges.each do |edge|
          model = graph.find_node(edge.to)
          method = edge.label || edge.attributes[:method]
          lines << "- `#{model.name}` (#{method})"
        end
        lines << ""
      end
      
      # Find services called
      service_edges = graph.edges.select { |e| e.from == action_node.id && e.type == :calls_service }
      if service_edges.any?
        lines << "**呼び出すサービス**:"
        lines << ""
        service_edges.each do |edge|
          service = graph.find_node(edge.to)
          method = edge.label || edge.attributes[:method]
          lines << "- `#{service.name}##{method}`"
        end
        lines << ""
      end
      
      # Find response methods
      response_edges = graph.edges.select { |e| e.from == action_node.id && e.type == :responds_with }
      if response_edges.any?
        lines << "**レスポンス形式**:"
        lines << ""
        response_edges.each do |edge|
          response = graph.find_node(edge.to)
          lines << "- `#{response.name}`"
        end
        lines << ""
      end
      
      lines
    end
    
    def generate_endpoint_flow(graph, route)
      lines = ["sequenceDiagram"]
      lines << "    participant Client"
      lines << "    participant Route"
      lines << "    participant Action"
      
      action_node = find_action_for_route(graph, route)
      return lines unless action_node
      
      # Add participants for models and services
      model_edges = graph.edges.select { |e| e.from == action_node.id && e.type == :accesses_model }
      service_edges = graph.edges.select { |e| e.from == action_node.id && e.type == :calls_service }
      
      model_edges.each do |edge|
        model = graph.find_node(edge.to)
        lines << "    participant #{model.name}"
      end
      
      service_edges.each do |edge|
        service = graph.find_node(edge.to)
        lines << "    participant #{service.name}"
      end
      
      lines << "    participant Response"
      lines << ""
      
      # Generate sequence
      verb = route.attributes[:verb]
      path = route.attributes[:path]
      
      lines << "    Client->>+Route: #{verb} #{path}"
      lines << "    Route->>+Action: Execute #{action_node.name}"
      
      service_edges.each do |edge|
        service = graph.find_node(edge.to)
        method = edge.label || "call"
        lines << "    Action->>+#{service.name}: #{method}"
        lines << "    #{service.name}-->>-Action: Return result"
      end
      
      model_edges.each do |edge|
        model = graph.find_node(edge.to)
        method = edge.label || "query"
        lines << "    Action->>+#{model.name}: #{method}"
        lines << "    #{model.name}-->>-Action: Return data"
      end
      
      response_edges = graph.edges.select { |e| e.from == action_node.id && e.type == :responds_with }
      if response_edges.any?
        response_method = response_edges.first.label
        lines << "    Action->>Response: #{response_method}"
      end
      
      lines << "    Action-->>-Route: Processing complete"
      lines << "    Route-->>-Client: HTTP Response"
      
      lines
    end
    
    def generate_flow_diagrams_section(graph)
      lines = ["## 全体フロー図"]
      lines << ""
      lines << "### エンドポイント関係図"
      lines << ""
      lines << "```mermaid"
      lines << "graph TD"
      
      # Add all route nodes
      route_nodes = graph.nodes_by_type(:route)
      route_nodes.each do |route|
        verb = route.attributes[:verb]
        path = route.attributes[:path]
        lines << "    #{route.id}[#{verb} #{path}]"
      end
      
      # Add controller and action nodes
      controller_nodes = graph.nodes_by_type(:controller)
      controller_nodes.each do |controller|
        lines << "    #{controller.id}[[#{controller.name}]]"
      end
      
      action_nodes = graph.nodes_by_type(:action)
      action_nodes.each do |action|
        lines << "    #{action.id}(#{action.name})"
      end
      
      # Add edges
      route_edges = graph.edges.select { |e| e.type == :routes_to }
      route_edges.each do |edge|
        lines << "    #{edge.from} --> #{edge.to}"
      end
      
      action_edges = graph.edges.select { |e| e.type == :has_action }
      action_edges.each do |edge|
        lines << "    #{edge.from} -.-> #{edge.to}"
      end
      
      lines << "```"
      lines << ""
      
      lines
    end
  end
end