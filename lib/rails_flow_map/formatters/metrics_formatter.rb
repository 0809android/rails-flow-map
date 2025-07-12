module RailsFlowMap
  module Formatters
    class MetricsFormatter
      def initialize(graph)
        @graph = graph
      end

      def format(graph = @graph)
        output = []
        output << "# 📊 Rails Application Metrics Report"
        output << "Generated at: #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"
        output << "\n" + "=" * 60 + "\n"
        
        # 概要統計
        output << "## 📈 Overview Statistics"
        output << "- Total Nodes: #{graph.node_count}"
        output << "- Total Edges: #{graph.edge_count}"
        output << "- Models: #{graph.nodes_by_type(:model).count}"
        output << "- Controllers: #{graph.nodes_by_type(:controller).count}"
        output << "- Actions: #{graph.nodes_by_type(:action).count}"
        output << "- Services: #{graph.nodes_by_type(:service).count}"
        output << "- Routes: #{graph.nodes_by_type(:route).count}"
        
        # 複雑度分析
        output << "\n## 🏆 Complexity Analysis"
        output << "\n### Most Connected Models (by relationships)"
        model_complexity = calculate_node_complexity(graph, :model)
        model_complexity.first(5).each_with_index do |(node, score), index|
          output << "#{index + 1}. #{node.name} (connections: #{score})"
        end
        
        output << "\n### Most Complex Controllers (by actions)"
        controller_actions = {}
        graph.nodes_by_type(:controller).each do |controller|
          action_count = graph.edges.count { |e| e.from == controller.id && e.type == :has_action }
          controller_actions[controller] = action_count
        end
        controller_actions.sort_by { |_, count| -count }.first(5).each_with_index do |(controller, count), index|
          output << "#{index + 1}. #{controller.name} (actions: #{count})"
        end
        
        # 依存関係分析
        output << "\n## 🔗 Dependency Analysis"
        output << "\n### Models with Most Dependencies"
        model_dependencies = calculate_dependencies(graph, :model)
        model_dependencies.first(5).each_with_index do |(node, deps), index|
          output << "#{index + 1}. #{node.name}"
          output << "   - Outgoing: #{deps[:outgoing]} (#{deps[:outgoing_types].join(', ')})"
          output << "   - Incoming: #{deps[:incoming]} (#{deps[:incoming_types].join(', ')})"
        end
        
        # サービス層分析
        output << "\n## 🛠️ Service Layer Analysis"
        services = graph.nodes_by_type(:service)
        if services.any?
          output << "- Total Services: #{services.count}"
          output << "- Services per Controller: #{(services.count.to_f / graph.nodes_by_type(:controller).count).round(2)}"
          
          output << "\n### Most Used Services"
          service_usage = calculate_service_usage(graph)
          service_usage.first(5).each_with_index do |(service, count), index|
            output << "#{index + 1}. #{service.name} (used by #{count} actions)"
          end
        else
          output << "- No service layer detected"
        end
        
        # 潜在的な問題
        output << "\n## ⚠️ Potential Issues"
        
        # 循環依存のチェック
        circular = detect_circular_dependencies(graph)
        if circular.any?
          output << "\n### Circular Dependencies Detected: #{circular.count}"
          circular.each do |cycle|
            output << "- #{cycle.join(' → ')}"
          end
        else
          output << "\n### ✅ No circular dependencies detected"
        end
        
        # God オブジェクトの検出
        output << "\n### Potential God Objects (high connectivity)"
        god_objects = model_complexity.select { |_, score| score > 10 }
        if god_objects.any?
          god_objects.each do |(node, score)|
            output << "- ⚠️ #{node.name} has #{score} connections"
          end
        else
          output << "- ✅ No god objects detected"
        end
        
        # 推奨事項
        output << "\n## 💡 Recommendations"
        
        if model_complexity.first[1] > 15
          output << "- Consider breaking down #{model_complexity.first[0].name} - it has too many relationships"
        end
        
        if services.empty? && graph.nodes_by_type(:controller).count > 5
          output << "- Consider implementing a service layer to separate business logic"
        end
        
        fat_controllers = controller_actions.select { |_, count| count > 7 }
        if fat_controllers.any?
          output << "- These controllers have too many actions: #{fat_controllers.keys.map(&:name).join(', ')}"
          output << "  Consider splitting into multiple controllers or using namespaces"
        end
        
        output.join("\n")
      end

      private

      def calculate_node_complexity(graph, type)
        complexity = {}
        graph.nodes_by_type(type).each do |node|
          incoming = graph.edges.count { |e| e.to == node.id }
          outgoing = graph.edges.count { |e| e.from == node.id }
          complexity[node] = incoming + outgoing
        end
        complexity.sort_by { |_, score| -score }
      end

      def calculate_dependencies(graph, type)
        dependencies = {}
        graph.nodes_by_type(type).each do |node|
          outgoing_edges = graph.edges.select { |e| e.from == node.id }
          incoming_edges = graph.edges.select { |e| e.to == node.id }
          
          dependencies[node] = {
            outgoing: outgoing_edges.count,
            outgoing_types: outgoing_edges.map(&:type).uniq,
            incoming: incoming_edges.count,
            incoming_types: incoming_edges.map(&:type).uniq
          }
        end
        dependencies.sort_by { |_, deps| -(deps[:outgoing] + deps[:incoming]) }
      end

      def calculate_service_usage(graph)
        usage = {}
        graph.nodes_by_type(:service).each do |service|
          calling_edges = graph.edges.select { |e| e.to == service.id && e.type == :calls_service }
          usage[service] = calling_edges.count
        end
        usage.sort_by { |_, count| -count }
      end

      def detect_circular_dependencies(graph)
        cycles = []
        visited = Set.new
        rec_stack = Set.new
        
        graph.nodes.each do |id, node|
          if !visited.include?(id)
            path = []
            if has_cycle?(graph, id, visited, rec_stack, path, cycles)
              # cycle found and added to cycles
            end
          end
        end
        
        cycles
      end

      def has_cycle?(graph, node_id, visited, rec_stack, path, cycles)
        visited.add(node_id)
        rec_stack.add(node_id)
        path.push(node_id)
        
        edges = graph.edges.select { |e| e.from == node_id }
        edges.each do |edge|
          if !visited.include?(edge.to)
            if has_cycle?(graph, edge.to, visited, rec_stack, path, cycles)
              return true
            end
          elsif rec_stack.include?(edge.to)
            # Found cycle
            cycle_start = path.index(edge.to)
            if cycle_start
              cycle = path[cycle_start..-1].map { |id| 
                node = graph.find_node(id)
                node ? node.name : id
              }
              cycles << cycle if cycle.any?
            end
            return true
          end
        end
        
        path.pop
        rec_stack.delete(node_id)
        false
      end
    end
  end
end