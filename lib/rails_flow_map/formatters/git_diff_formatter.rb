module RailsFlowMap
  class GitDiffFormatter
      def initialize(before_graph, after_graph, options = {})
        @before_graph = before_graph
        @after_graph = after_graph
        @options = options
        @format = options[:format] || :mermaid
      end

      def format
        diff_result = analyze_differences
        
        case @format
        when :mermaid
          format_as_mermaid(diff_result)
        when :html
          format_as_html(diff_result)
        else
          format_as_text(diff_result)
        end
      end

      private

      def analyze_differences
        diff = {
          added_nodes: [],
          removed_nodes: [],
          modified_nodes: [],
          added_edges: [],
          removed_edges: [],
          modified_edges: [],
          metrics_change: calculate_metrics_change,
          summary: {}
        }
        
        before_nodes = @before_graph.nodes
        after_nodes = @after_graph.nodes
        
        # ノードの追加を検出
        after_nodes.each do |id, node|
          unless before_nodes[id]
            diff[:added_nodes] << node
          end
        end
        
        # ノードの削除と変更を検出
        before_nodes.each do |id, node|
          if after_nodes[id]
            # ノードが存在する場合、変更をチェック
            if node_changed?(node, after_nodes[id])
              diff[:modified_nodes] << {
                before: node,
                after: after_nodes[id],
                changes: detect_node_changes(node, after_nodes[id])
              }
            end
          else
            diff[:removed_nodes] << node
          end
        end
        
        # エッジの変更を検出
        before_edges = @before_graph.edges
        after_edges = @after_graph.edges
        
        # エッジの追加
        after_edges.each do |edge|
          unless edge_exists?(edge, before_edges)
            diff[:added_edges] << edge
          end
        end
        
        # エッジの削除
        before_edges.each do |edge|
          unless edge_exists?(edge, after_edges)
            diff[:removed_edges] << edge
          end
        end
        
        # サマリーの生成
        diff[:summary] = generate_summary(diff)
        
        diff
      end

      def node_changed?(before_node, after_node)
        before_node.name != after_node.name ||
        before_node.type != after_node.type ||
        before_node.attributes != after_node.attributes
      end

      def detect_node_changes(before_node, after_node)
        changes = []
        
        if before_node.name != after_node.name
          changes << { type: :name, before: before_node.name, after: after_node.name }
        end
        
        if before_node.attributes != after_node.attributes
          # 関連の変更を検出
          before_assoc = before_node.attributes[:associations] || []
          after_assoc = after_node.attributes[:associations] || []
          
          added_assoc = after_assoc - before_assoc
          removed_assoc = before_assoc - after_assoc
          
          if added_assoc.any?
            changes << { type: :associations_added, items: added_assoc }
          end
          
          if removed_assoc.any?
            changes << { type: :associations_removed, items: removed_assoc }
          end
        end
        
        changes
      end

      def edge_exists?(target_edge, edge_list)
        edge_list.any? do |edge|
          edge.from == target_edge.from &&
          edge.to == target_edge.to &&
          edge.type == target_edge.type
        end
      end

      def calculate_metrics_change
        {
          nodes: {
            before: @before_graph.node_count,
            after: @after_graph.node_count,
            change: @after_graph.node_count - @before_graph.node_count
          },
          edges: {
            before: @before_graph.edge_count,
            after: @after_graph.edge_count,
            change: @after_graph.edge_count - @before_graph.edge_count
          },
          complexity: calculate_complexity_change
        }
      end

      def calculate_complexity_change
        before_complexity = calculate_graph_complexity(@before_graph)
        after_complexity = calculate_graph_complexity(@after_graph)
        
        {
          before: before_complexity,
          after: after_complexity,
          change: after_complexity - before_complexity,
          percentage: before_complexity > 0 ? ((after_complexity - before_complexity) * 100.0 / before_complexity).round(2) : 0
        }
      end

      def calculate_graph_complexity(graph)
        # 簡易的な複雑度計算（ノード数 + エッジ数 * 2）
        graph.node_count + (graph.edge_count * 2)
      end

      def generate_summary(diff)
        {
          total_changes: diff[:added_nodes].count + diff[:removed_nodes].count + 
                        diff[:modified_nodes].count + diff[:added_edges].count + 
                        diff[:removed_edges].count,
          breaking_changes: detect_breaking_changes(diff),
          recommendations: generate_recommendations(diff)
        }
      end

      def detect_breaking_changes(diff)
        breaking = []
        
        # 削除されたコントローラーやアクション
        diff[:removed_nodes].each do |node|
          if [:controller, :action, :route].include?(node.type)
            breaking << "#{node.type.to_s.capitalize} '#{node.name}' was removed"
          end
        end
        
        # 削除されたモデルの関連
        diff[:removed_edges].each do |edge|
          if edge.type == :belongs_to
            breaking << "Association removed: #{edge.from} belongs_to #{edge.to}"
          end
        end
        
        breaking
      end

      def generate_recommendations(diff)
        recommendations = []
        
        # 大量の追加があった場合
        if diff[:added_nodes].count > 10
          recommendations << "Consider breaking down the changes into smaller commits"
        end
        
        # 複雑度が大幅に増加した場合
        complexity_change = diff[:metrics_change][:complexity][:percentage]
        if complexity_change > 20
          recommendations << "Complexity increased by #{complexity_change}%. Consider refactoring"
        end
        
        # 循環依存が追加された可能性
        if diff[:added_edges].count > diff[:added_nodes].count * 2
          recommendations << "Many new dependencies added. Check for circular dependencies"
        end
        
        recommendations
      end

      def format_as_mermaid(diff)
        output = []
        output << "```mermaid"
        output << "graph TD"
        output << "    subgraph Legend"
        output << "        Added[Added - Green]:::added"
        output << "        Removed[Removed - Red]:::removed"
        output << "        Modified[Modified - Yellow]:::modified"
        output << "    end"
        output << ""
        
        # 全ノードを表示（状態付き）
        all_nodes = {}
        
        # 既存のノード
        @after_graph.nodes.each do |id, node|
          if diff[:added_nodes].any? { |n| n.id == id }
            all_nodes[id] = { node: node, status: :added }
          elsif diff[:modified_nodes].any? { |m| m[:after].id == id }
            all_nodes[id] = { node: node, status: :modified }
          else
            all_nodes[id] = { node: node, status: :unchanged }
          end
        end
        
        # 削除されたノード
        diff[:removed_nodes].each do |node|
          all_nodes[node.id] = { node: node, status: :removed }
        end
        
        # ノードの描画
        all_nodes.each do |id, data|
          node = data[:node]
          status = data[:status]
          
          node_text = case node.type
                     when :controller
                       "#{node.name}[[#{node.name}]]"
                     when :action
                       "#{node.name}(#{node.name})"
                     else
                       "#{node.name}[#{node.name}]"
                     end
          
          class_suffix = status == :unchanged ? "" : ":::#{status}"
          output << "    #{node_text}#{class_suffix}"
        end
        
        output << ""
        
        # エッジの描画
        all_edges = []
        
        # 既存のエッジ
        @after_graph.edges.each do |edge|
          if diff[:added_edges].any? { |e| edge_equal?(e, edge) }
            all_edges << { edge: edge, status: :added }
          else
            all_edges << { edge: edge, status: :unchanged }
          end
        end
        
        # 削除されたエッジ
        diff[:removed_edges].each do |edge|
          all_edges << { edge: edge, status: :removed }
        end
        
        # エッジの描画
        all_edges.each do |data|
          edge = data[:edge]
          status = data[:status]
          
          style = case status
                 when :added
                   "==>"
                 when :removed
                   "-.->"
                 else
                   "-->"
                 end
          
          label = edge.label ? "|#{edge.label}|" : ""
          class_suffix = status == :unchanged ? "" : ":::#{status}"
          
          from_exists = all_nodes[edge.from]
          to_exists = all_nodes[edge.to]
          
          if from_exists && to_exists
            output << "    #{edge.from} #{style}#{label} #{edge.to}#{class_suffix}"
          end
        end
        
        output << ""
        output << "    classDef added fill:#90EE90,stroke:#006400,stroke-width:3px;"
        output << "    classDef removed fill:#FFB6C1,stroke:#8B0000,stroke-width:3px,stroke-dasharray: 5 5;"
        output << "    classDef modified fill:#FFFFE0,stroke:#FFD700,stroke-width:3px;"
        output << "```"
        
        # 変更サマリー
        output << ""
        output << "## 変更サマリー"
        output << ""
        output << "### 📊 メトリクス変化"
        output << "- ノード数: #{diff[:metrics_change][:nodes][:before]} → #{diff[:metrics_change][:nodes][:after]} (#{format_change(diff[:metrics_change][:nodes][:change])})"
        output << "- エッジ数: #{diff[:metrics_change][:edges][:before]} → #{diff[:metrics_change][:edges][:after]} (#{format_change(diff[:metrics_change][:edges][:change])})"
        output << "- 複雑度: #{diff[:metrics_change][:complexity][:before]} → #{diff[:metrics_change][:complexity][:after]} (#{format_change(diff[:metrics_change][:complexity][:change])} / #{diff[:metrics_change][:complexity][:percentage]}%)"
        
        if diff[:summary][:breaking_changes].any?
          output << ""
          output << "### ⚠️ 破壊的変更"
          diff[:summary][:breaking_changes].each do |change|
            output << "- #{change}"
          end
        end
        
        if diff[:summary][:recommendations].any?
          output << ""
          output << "### 💡 推奨事項"
          diff[:summary][:recommendations].each do |rec|
            output << "- #{rec}"
          end
        end
        
        output.join("\n")
      end

      def format_as_html(diff)
        # HTML形式での差分表示（D3.jsを使用）
        html_content = <<~HTML
<!DOCTYPE html>
<html>
<head>
    <title>Rails Flow Map - Git Diff Visualization</title>
    <script src="https://d3js.org/d3.v7.min.js"></script>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .summary { background: #f0f0f0; padding: 20px; border-radius: 5px; margin-bottom: 20px; }
        .metrics { display: flex; gap: 20px; margin-bottom: 20px; }
        .metric-card { background: white; padding: 15px; border-radius: 5px; box-shadow: 0 2px 5px rgba(0,0,0,0.1); }
        .added { color: #28a745; }
        .removed { color: #dc3545; }
        .modified { color: #ffc107; }
        .breaking { background: #fff3cd; border: 1px solid #ffeaa7; padding: 10px; border-radius: 5px; margin: 10px 0; }
        #diff-graph { width: 100%; height: 600px; border: 1px solid #ddd; }
    </style>
</head>
<body>
    <h1>Rails Flow Map - Architecture Diff</h1>
    
    <div class="summary">
        <h2>変更サマリー</h2>
        <div class="metrics">
            <div class="metric-card">
                <h3>ノード</h3>
                <p>#{diff[:metrics_change][:nodes][:before]} → #{diff[:metrics_change][:nodes][:after]}</p>
                <p class="#{diff[:metrics_change][:nodes][:change] >= 0 ? 'added' : 'removed'}">
                    #{format_change(diff[:metrics_change][:nodes][:change])}
                </p>
            </div>
            <div class="metric-card">
                <h3>エッジ</h3>
                <p>#{diff[:metrics_change][:edges][:before]} → #{diff[:metrics_change][:edges][:after]}</p>
                <p class="#{diff[:metrics_change][:edges][:change] >= 0 ? 'added' : 'removed'}">
                    #{format_change(diff[:metrics_change][:edges][:change])}
                </p>
            </div>
            <div class="metric-card">
                <h3>複雑度</h3>
                <p>#{diff[:metrics_change][:complexity][:before]} → #{diff[:metrics_change][:complexity][:after]}</p>
                <p class="#{diff[:metrics_change][:complexity][:change] >= 0 ? 'added' : 'removed'}">
                    #{format_change(diff[:metrics_change][:complexity][:change])} (#{diff[:metrics_change][:complexity][:percentage]}%)
                </p>
            </div>
        </div>
        
        #{generate_breaking_changes_html(diff)}
    </div>
    
    <div id="diff-graph"></div>
    
    <script>
        const diffData = #{generate_diff_data_json(diff)};
        // D3.js visualization code here
    </script>
</body>
</html>
        HTML
        
        html_content
      end

      def format_as_text(diff)
        output = []
        output << "Rails Flow Map - Architecture Diff Report"
        output << "=" * 50
        output << ""
        
        # 追加されたノード
        if diff[:added_nodes].any?
          output << "## Added Nodes (#{diff[:added_nodes].count})"
          diff[:added_nodes].each do |node|
            output << "  + #{node.type}: #{node.name}"
          end
          output << ""
        end
        
        # 削除されたノード
        if diff[:removed_nodes].any?
          output << "## Removed Nodes (#{diff[:removed_nodes].count})"
          diff[:removed_nodes].each do |node|
            output << "  - #{node.type}: #{node.name}"
          end
          output << ""
        end
        
        # 変更されたノード
        if diff[:modified_nodes].any?
          output << "## Modified Nodes (#{diff[:modified_nodes].count})"
          diff[:modified_nodes].each do |mod|
            output << "  ~ #{mod[:before].type}: #{mod[:before].name}"
            mod[:changes].each do |change|
              output << "    - #{format_change_description(change)}"
            end
          end
          output << ""
        end
        
        # メトリクス
        output << "## Metrics"
        output << "  Nodes: #{diff[:metrics_change][:nodes][:before]} → #{diff[:metrics_change][:nodes][:after]} (#{format_change(diff[:metrics_change][:nodes][:change])})"
        output << "  Edges: #{diff[:metrics_change][:edges][:before]} → #{diff[:metrics_change][:edges][:after]} (#{format_change(diff[:metrics_change][:edges][:change])})"
        output << "  Complexity: #{diff[:metrics_change][:complexity][:before]} → #{diff[:metrics_change][:complexity][:after]} (#{format_change(diff[:metrics_change][:complexity][:change])})"
        
        output.join("\n")
      end

      def edge_equal?(edge1, edge2)
        edge1.from == edge2.from && edge1.to == edge2.to && edge1.type == edge2.type
      end

      def format_change(num)
        num >= 0 ? "+#{num}" : num.to_s
      end

      def format_change_description(change)
        case change[:type]
        when :name
          "Name changed: #{change[:before]} → #{change[:after]}"
        when :associations_added
          "Associations added: #{change[:items].join(', ')}"
        when :associations_removed
          "Associations removed: #{change[:items].join(', ')}"
        else
          "Changed: #{change[:type]}"
        end
      end

      def generate_breaking_changes_html(diff)
        return "" unless diff[:summary][:breaking_changes].any?
        
        html = '<div class="breaking">'
        html += '<h3>⚠️ 破壊的変更</h3>'
        html += '<ul>'
        diff[:summary][:breaking_changes].each do |change|
          html += "<li>#{change}</li>"
        end
        html += '</ul>'
        html += '</div>'
        
        html
      end

      def generate_diff_data_json(diff)
        {
          nodes: generate_diff_nodes(diff),
          edges: generate_diff_edges(diff)
        }.to_json
      end

      def generate_diff_nodes(diff)
        nodes = []
        
        # 全ノードを収集
        @after_graph.nodes.each do |id, node|
          status = if diff[:added_nodes].any? { |n| n.id == id }
                    'added'
                  elsif diff[:modified_nodes].any? { |m| m[:after].id == id }
                    'modified'
                  else
                    'unchanged'
                  end
          
          nodes << {
            id: id,
            name: node.name,
            type: node.type,
            status: status
          }
        end
        
        # 削除されたノード
        diff[:removed_nodes].each do |node|
          nodes << {
            id: node.id,
            name: node.name,
            type: node.type,
            status: 'removed'
          }
        end
        
        nodes
      end

      def generate_diff_edges(diff)
        edges = []
        
        # 全エッジを収集
        @after_graph.edges.each do |edge|
          status = diff[:added_edges].any? { |e| edge_equal?(e, edge) } ? 'added' : 'unchanged'
          
          edges << {
            source: edge.from,
            target: edge.to,
            type: edge.type,
            label: edge.label,
            status: status
          }
        end
        
        # 削除されたエッジ
        diff[:removed_edges].each do |edge|
          edges << {
            source: edge.from,
            target: edge.to,
            type: edge.type,
            label: edge.label,
            status: 'removed'
          }
        end
        
        edges
      end
  end
end