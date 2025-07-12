module RailsFlowMap
  class FlowGraph
    attr_reader :nodes, :edges

    def initialize
      @nodes = {}
      @edges = []
    end

    def add_node(node)
      return false unless node.is_a?(FlowNode)
      @nodes[node.id] = node
      true
    end

    def add_edge(edge)
      return false unless edge.is_a?(FlowEdge)
      # Avoid duplicate edges
      return false if @edges.include?(edge)
      @edges << edge
      true
    end

    def find_node(id)
      @nodes[id]
    end

    def nodes_by_type(type)
      @nodes.values.select { |node| node.type == type }
    end

    def edges_by_type(type)
      @edges.select { |edge| edge.type == type }
    end

    def connected_nodes(node_id, direction: :both)
      case direction
      when :outgoing
        @edges.select { |e| e.from == node_id }.map { |e| @nodes[e.to] }.compact
      when :incoming
        @edges.select { |e| e.to == node_id }.map { |e| @nodes[e.from] }.compact
      when :both
        outgoing = @edges.select { |e| e.from == node_id }.map { |e| @nodes[e.to] }
        incoming = @edges.select { |e| e.to == node_id }.map { |e| @nodes[e.from] }
        (outgoing + incoming).compact.uniq
      end
    end

    def node_count
      @nodes.size
    end

    def edge_count
      @edges.size
    end

    def empty?
      @nodes.empty? && @edges.empty?
    end

    def merge(other_graph)
      return false unless other_graph.is_a?(FlowGraph)
      
      other_graph.nodes.each { |id, node| add_node(node) }
      other_graph.edges.each { |edge| add_edge(edge) }
      true
    end

    def to_h
      {
        nodes: @nodes.transform_values(&:to_h),
        edges: @edges.map(&:to_h)
      }
    end

    def to_json(*args)
      to_h.to_json(*args)
    end

    def clear
      @nodes.clear
      @edges.clear
    end
  end
end