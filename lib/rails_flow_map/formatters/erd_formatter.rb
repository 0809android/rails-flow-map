module RailsFlowMap
  module Formatters
    class ErdFormatter
      def initialize(graph)
        @graph = graph
      end

      def format(graph = @graph)
        output = []
        output << "# Entity Relationship Diagram\n"
        output << "```"
        
        # モデルのみを抽出
        models = graph.nodes_by_type(:model)
        
        models.each do |model|
          output << format_model_box(model)
          output << ""
        end
        
        # 関係性を表示
        output << "## Relationships\n"
        graph.edges_by_type(:belongs_to).each do |edge|
          from_model = graph.find_node(edge.from)
          to_model = graph.find_node(edge.to)
          output << "#{from_model.name} belongs_to #{to_model.name}"
        end
        
        graph.edges_by_type(:has_many).each do |edge|
          from_model = graph.find_node(edge.from)
          to_model = graph.find_node(edge.to)
          output << "#{from_model.name} has_many #{to_model.name}"
        end
        
        output << "```"
        output.join("\n")
      end

      private

      def format_model_box(model)
        lines = []
        lines << "┌─────────────────────┐"
        lines << "│ #{model.name.center(19)} │"
        lines << "├─────────────────────┤"
        
        # 仮のカラム情報（実際の実装では、モデルから取得）
        lines << "│ id         :integer │"
        lines << "│ created_at :datetime│"
        lines << "│ updated_at :datetime│"
        
        if model.attributes[:associations]
          model.attributes[:associations].each do |assoc|
            if assoc.include?("belongs_to")
              foreign_key = assoc.split(" ").last.downcase + "_id"
              lines << "│ #{foreign_key.ljust(10)} :integer │"
            end
          end
        end
        
        lines << "└─────────────────────┘"
        lines.join("\n")
      end
    end
  end
end