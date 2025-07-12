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
      lines << "classDef route fill:#FFE4E1,stroke:#FF6B6B,stroke-width:2px;"
      lines << "classDef service fill:#FFF3E0,stroke:#FF9800,stroke-width:2px;"
      lines << "classDef response fill:#F1F8E9,stroke:#8BC34A,stroke-width:2px;"
      
      # Apply styles to nodes
      apply_node_styles(graph, lines)
      
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
              when :route
                "#{node.id}[fa:fa-globe #{label}]"
              when :service
                "#{node.id}{#{label}}"
              when :response
                "#{node.id}[fa:fa-reply #{label}]"
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
              when :has_action, :routes_to
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
      
      "    #{edge.from} #{arrow}#{label} #{edge.to}"
    end
    
    def apply_node_styles(graph, lines)
      node_groups = {
        model: [],
        controller: [],
        action: [],
        route: [],
        service: [],
        response: []
      }
      
      graph.nodes.each do |id, node|
        group = node_groups[node.type]
        group << node.id if group
      end
      
      node_groups.each do |type, nodes|
        next if nodes.empty?
        lines << "class #{nodes.join(',')} #{type};"
      end
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