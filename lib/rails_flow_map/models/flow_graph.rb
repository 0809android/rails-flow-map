module RailsFlowMap
  class FlowGraph
    attr_reader :nodes, :edges

    def initialize
      @nodes = {}
      @edges = []
    end

    def add_node(node)
      @nodes[node.id] = node
    end

    def add_edge(edge)
      @edges << edge
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

    def to_h
      {
        nodes: @nodes.transform_values(&:to_h),
        edges: @edges.map(&:to_h)
      }
    end
  end
end