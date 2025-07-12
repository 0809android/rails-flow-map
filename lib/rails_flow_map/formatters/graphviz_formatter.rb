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
      when :has_one
        attrs << "style=solid"
        attrs << "arrowhead=normal"
      when :has_many
        attrs << "style=solid"
        attrs << "arrowhead=crow"
      when :has_and_belongs_to_many
        attrs << "style=solid"
        attrs << "arrowhead=crow"
        attrs << "arrowtail=crow"
        attrs << "dir=both"
      when :has_action
        attrs << "style=dashed"
        attrs << "color=gray"
      end
      
      attrs.join(", ")
    end
  end
end