module RailsFlowMap
  module Formatters
    class SequenceFormatter
      def initialize(graph, options = {})
        @graph = graph
        @endpoint = options[:endpoint]
      end

      def format(graph = @graph)
        output = []
        output << "```mermaid"
        output << "sequenceDiagram"
        output << "    participant Client"
        output << "    participant Router"
        
        # エンドポイントに関連するノードを取得
        route_nodes = graph.nodes_by_type(:route)
        
        if @endpoint
          route_nodes = route_nodes.select do |node|
            node.attributes[:path] == @endpoint
          end
        end
        
        route_nodes.each do |route|
          output.concat(generate_sequence_for_route(route, graph))
        end
        
        output << "```"
        output.join("\n")
      end

      private

      def generate_sequence_for_route(route, graph)
        lines = []
        
        # ルートから開始
        lines << "    Client->>+Router: #{route.attributes[:verb]} #{route.attributes[:path]}"
        
        # ルートからアクションへ
        route_edges = graph.edges.select { |e| e.from == route.id && e.type == :routes_to }
        
        route_edges.each do |edge|
          action = graph.find_node(edge.to)
          next unless action
          
          controller_name = action.attributes[:controller] || "Controller"
          lines << "    Router->>+#{controller_name}: #{action.name}"
          
          # アクションからサービスへ
          service_edges = graph.edges.select { |e| e.from == action.id && e.type == :calls_service }
          
          service_edges.each do |service_edge|
            service = graph.find_node(service_edge.to)
            next unless service
            
            method_name = service_edge.label || "process"
            lines << "    #{controller_name}->>+#{service.name}: #{method_name}"
            
            # サービスからモデルへ
            model_edges = graph.edges.select { |e| e.from == service.id && e.type == :accesses_model }
            
            model_edges.each do |model_edge|
              model = graph.find_node(model_edge.to)
              next unless model
              
              query = model_edge.label || "query"
              lines << "    #{service.name}->>+#{model.name}: #{query}"
              lines << "    #{model.name}-->>-#{service.name}: [data]"
            end
            
            lines << "    #{service.name}-->>-#{controller_name}: result"
          end
          
          lines << "    #{controller_name}-->>-Client: 200 OK {data}"
        end
        
        lines
      end
    end
  end
end