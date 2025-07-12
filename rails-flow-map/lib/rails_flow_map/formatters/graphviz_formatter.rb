module RailsFlowMap
  class GraphVizFormatter
    def format(graph)
      lines = ["digraph RailsFlowMap {"]
      lines << "  rankdir=TB;"
      lines << "  node [shape=box];"
      lines << ""
      
      # Group nodes by type
      models = graph.nodes_by_type(:model)
      controllers = graph.nodes_by_type(:controller)
      actions = graph.nodes_by_type(:action)
      routes = graph.nodes_by_type(:route)
      services = graph.nodes_by_type(:service)
      responses = graph.nodes_by_type(:response)
      
      # Add models subgraph
      unless models.empty?
        lines << "  subgraph cluster_models {"
        lines << "    label=\"Models\";"
        lines << "    style=filled;"
        lines << "    color=lightgrey;"
        lines << "    node [style=filled,color=pink];"
        models.each do |node|
          lines << "    #{node.id} [label=\"#{escape_label(node.name)}\"];"
        end
        lines << "  }"
        lines << ""
      end
      
      # Add routes subgraph
      unless routes.empty?
        lines << "  subgraph cluster_routes {"
        lines << "    label=\"Routes\";"
        lines << "    style=filled;"
        lines << "    color=lightcoral;"
        lines << "    node [style=filled,color=lightyellow];"
        routes.each do |node|
          lines << "    #{node.id} [label=\"#{escape_label(node.name)}\",shape=ellipse];"
        end
        lines << "  }"
        lines << ""
      end
      
      # Add controllers subgraph
      unless controllers.empty?
        lines << "  subgraph cluster_controllers {"
        lines << "    label=\"Controllers\";"
        lines << "    style=filled;"
        lines << "    color=lightblue;"
        lines << "    node [style=filled,color=lightblue];"
        controllers.each do |node|
          lines << "    #{node.id} [label=\"#{escape_label(node.name)}\",shape=component];"
        end
        lines << "  }"
        lines << ""
      end
      
      # Add actions subgraph
      unless actions.empty?
        lines << "  subgraph cluster_actions {"
        lines << "    label=\"Actions\";"
        lines << "    style=filled;"
        lines << "    color=lightgreen;"
        lines << "    node [style=filled,color=lightgreen,shape=ellipse];"
        actions.each do |node|
          controller_name = node.attributes[:controller] || "Unknown"
          lines << "    #{node.id} [label=\"#{escape_label(controller_name)}##{escape_label(node.name)}\"];"
        end
        lines << "  }"
        lines << ""
      end
      
      # Add services subgraph
      unless services.empty?
        lines << "  subgraph cluster_services {"
        lines << "    label=\"Services\";"
        lines << "    style=filled;"
        lines << "    color=lightyellow;"
        lines << "    node [style=filled,color=orange,shape=diamond];"
        services.each do |node|
          lines << "    #{node.id} [label=\"#{escape_label(node.name)}\"];"
        end
        lines << "  }"
        lines << ""
      end
      
      # Add responses subgraph
      unless responses.empty?
        lines << "  subgraph cluster_responses {"
        lines << "    label=\"Responses\";"
        lines << "    style=filled;"
        lines << "    color=lightgray;"
        lines << "    node [style=filled,color=lightgreen,shape=box];"
        responses.each do |node|
          lines << "    #{node.id} [label=\"#{escape_label(node.name)}\"];"
        end
        lines << "  }"
        lines << ""
      end
      
      # Add edges
      graph.edges.each do |edge|
        from_node = graph.find_node(edge.from)
        to_node = graph.find_node(edge.to)
        
        next unless from_node && to_node
        
        edge_attrs = format_edge_attributes(edge)
        lines << "  #{edge.from} -> #{edge.to} [#{edge_attrs}];"
      end
      
      lines << "}"
      
      lines.join("\n")
    end
    
    private
    
    def escape_label(text)
      text.to_s.gsub('"', '\\"')
    end
    
    def format_edge_attributes(edge)
      attrs = []
      
      # Add label if present
      if edge.label
        attrs << "label=\"#{escape_label(edge.label)}\""
      end
      
      # Add style based on edge type
      case edge.type
      when :belongs_to
        attrs << "style=solid"
        attrs << "arrowhead=normal"
        attrs << "color=blue"
      when :has_one
        attrs << "style=solid"
        attrs << "arrowhead=normal"
        attrs << "color=green"
      when :has_many
        attrs << "style=solid"
        attrs << "arrowhead=crow"
        attrs << "color=red"
      when :has_and_belongs_to_many
        attrs << "style=solid"
        attrs << "arrowhead=crow"
        attrs << "arrowtail=crow"
        attrs << "dir=both"
        attrs << "color=purple"
      when :has_action
        attrs << "style=dashed"
        attrs << "color=gray"
      when :routes_to
        attrs << "style=bold"
        attrs << "color=orange"
        attrs << "arrowhead=normal"
      when :accesses_model
        attrs << "style=solid"
        attrs << "color=darkgreen"
        attrs << "arrowhead=normal"
      when :calls_service
        attrs << "style=dashed"
        attrs << "color=brown"
        attrs << "arrowhead=normal"
      when :responds_with
        attrs << "style=dotted"
        attrs << "color=red"
        attrs << "arrowhead=normal"
      end
      
      attrs.join(", ")
    end
  end
end