module RailsFlowMap
  class MermaidFormatter
    def format(graph)
      lines = ["graph TD"]
      
      # Add nodes
      graph.nodes.each do |id, node|
        lines << format_node(node)
      end
      
      lines << ""
      
      # Add edges
      graph.edges.each do |edge|
        lines << format_edge(edge, graph)
      end
      
      # Add styling
      lines << ""
      lines << "%% Styling"
      lines << "classDef model fill:#f9f,stroke:#333,stroke-width:2px;"
      lines << "classDef controller fill:#bbf,stroke:#333,stroke-width:2px;"
      lines << "classDef action fill:#bfb,stroke:#333,stroke-width:2px;"
      
      # Apply styles to nodes
      model_nodes = graph.nodes_by_type(:model).map(&:id).join(",")
      controller_nodes = graph.nodes_by_type(:controller).map(&:id).join(",")
      action_nodes = graph.nodes_by_type(:action).map(&:id).join(",")
      
      lines << "class #{model_nodes} model;" unless model_nodes.empty?
      lines << "class #{controller_nodes} controller;" unless controller_nodes.empty?
      lines << "class #{action_nodes} action;" unless action_nodes.empty?
      
      lines.join("\n")
    end
    
    private
    
    def format_node(node)
      label = escape_mermaid(node.name)
      shape = case node.type
              when :model
                "#{node.id}[#{label}]"
              when :controller
                "#{node.id}[[#{label}]]"
              when :action
                "#{node.id}(#{label})"
              else
                "#{node.id}[#{label}]"
              end
      "    #{shape}"
    end
    
    def format_edge(edge, graph)
      from_node = graph.find_node(edge.from)
      to_node = graph.find_node(edge.to)
      
      return nil unless from_node && to_node
      
      arrow = case edge.type
              when :belongs_to
                "-->"
              when :has_one
                "-->"
              when :has_many
                "==>"
              when :has_and_belongs_to_many
                "<==>"
              when :has_action
                "-.->"
              else
                "-->"
              end
      
      label = edge.label ? "|#{escape_mermaid(edge.label.to_s)}|" : ""
      
      "    #{edge.from} #{arrow}#{label} #{edge.to}"
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