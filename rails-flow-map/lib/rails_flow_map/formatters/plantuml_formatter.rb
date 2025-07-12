module RailsFlowMap
  class PlantUMLFormatter
    def format(graph)
      lines = ["@startuml"]
      lines << "!define MODEL_COLOR #FFCCFF"
      lines << "!define CONTROLLER_COLOR #CCCCFF"
      lines << "!define ACTION_COLOR #CCFFCC"
      lines << "!define ROUTE_COLOR #FFE4E1"
      lines << "!define SERVICE_COLOR #FFF3E0"
      lines << ""
      
      # Group nodes by type
      models = graph.nodes_by_type(:model)
      controllers = graph.nodes_by_type(:controller)
      actions = graph.nodes_by_type(:action)
      routes = graph.nodes_by_type(:route)
      services = graph.nodes_by_type(:service)
      
      # Add models
      unless models.empty?
        lines << "package \"Models\" <<Database>> {"
        models.each do |node|
          lines << "  class #{sanitize_id(node.name)} <<Model>> {"
          lines << "    .."
          lines << "  }"
        end
        lines << "}"
        lines << ""
      end
      
      # Add controllers and their actions
      unless controllers.empty?
        lines << "package \"Controllers\" <<Frame>> {"
        controllers.each do |controller|
          lines << "  class #{sanitize_id(controller.name)} <<Controller>> {"
          
          # Find actions for this controller
          controller_actions = graph.edges
            .select { |e| e.from == controller.id && e.type == :has_action }
            .map { |e| graph.find_node(e.to) }
            .compact
          
          controller_actions.each do |action|
            lines << "    +#{action.name}()"
          end
          
          lines << "  }"
        end
        lines << "}"
        lines << ""
      end
      
      # Add routes
      unless routes.empty?
        lines << "package \"Routes\" <<Cloud>> {"
        routes.each do |route|
          lines << "  class #{sanitize_id(route.name)} <<Route>> {"
          lines << "    #{route.attributes[:verb]} #{route.attributes[:path]}"
          lines << "  }"
        end
        lines << "}"
        lines << ""
      end
      
      # Add services
      unless services.empty?
        lines << "package \"Services\" <<Component>> {"
        services.each do |service|
          lines << "  class #{sanitize_id(service.name)} <<Service>> {"
          lines << "    .."
          lines << "  }"
        end
        lines << "}"
        lines << ""
      end
      
      # Add relationships
      graph.edges.each do |edge|
        next if edge.type == :has_action  # Skip controller-action relationships
        
        from_node = graph.find_node(edge.from)
        to_node = graph.find_node(edge.to)
        
        next unless from_node && to_node
        
        relationship = format_relationship(edge, from_node, to_node)
        lines << relationship if relationship
      end
      
      lines << ""
      lines << "@enduml"
      
      lines.join("\n")
    end
    
    private
    
    def sanitize_id(name)
      name.gsub(/[^a-zA-Z0-9_]/, '_')
    end
    
    def format_relationship(edge, from_node, to_node)
      from_name = sanitize_id(from_node.name)
      to_name = sanitize_id(to_node.name)
      
      case edge.type
      when :belongs_to
        "#{from_name} --> \"1\" #{to_name} : #{edge.label || 'belongs_to'}"
      when :has_one
        "#{from_name} --> \"1\" #{to_name} : #{edge.label || 'has_one'}"
      when :has_many
        "#{from_name} --> \"*\" #{to_name} : #{edge.label || 'has_many'}"
      when :has_and_belongs_to_many
        "#{from_name} \"*\" <--> \"*\" #{to_name} : #{edge.label || 'has_and_belongs_to_many'}"
      when :routes_to
        "#{from_name} --> #{to_name} : routes to"
      when :accesses_model
        "#{from_name} --> #{to_name} : #{edge.label || 'accesses'}"
      when :calls_service
        "#{from_name} --> #{to_name} : #{edge.label || 'calls'}"
      when :responds_with
        "#{from_name} --> #{to_name} : #{edge.label || 'responds'}"
      else
        "#{from_name} --> #{to_name} : #{edge.label || edge.type}"
      end
    end
  end
end