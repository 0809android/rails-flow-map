require 'cgi'

module RailsFlowMap
  class D3jsFormatter
      def initialize(graph, options = {})
        @graph = graph
        @options = options
      end

      def format(graph = @graph)
        html_content = <<~HTML
<!DOCTYPE html>
<html lang="ja">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rails Flow Map - Interactive Visualization</title>
    <script src="https://d3js.org/d3.v7.min.js"></script>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            overflow: hidden;
        }
        
        #container {
            width: 100vw;
            height: 100vh;
            position: relative;
        }
        
        #controls {
            position: absolute;
            top: 10px;
            left: 10px;
            background: white;
            padding: 15px;
            border-radius: 5px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            z-index: 1000;
        }
        
        #search {
            padding: 5px 10px;
            border: 1px solid #ddd;
            border-radius: 3px;
            width: 200px;
            margin-bottom: 10px;
        }
        
        .filter-group {
            margin-bottom: 10px;
        }
        
        .filter-group label {
            display: block;
            margin: 5px 0;
            cursor: pointer;
        }
        
        .node {
            cursor: pointer;
        }
        
        .node circle {
            stroke-width: 2px;
        }
        
        .node text {
            font: 12px sans-serif;
            pointer-events: none;
        }
        
        .link {
            fill: none;
            stroke: #999;
            stroke-opacity: 0.6;
            stroke-width: 1.5px;
        }
        
        .link-label {
            font: 10px sans-serif;
            fill: #666;
        }
        
        .highlighted {
            opacity: 1 !important;
        }
        
        .dimmed {
            opacity: 0.2;
        }
        
        .tooltip {
            position: absolute;
            padding: 10px;
            background: rgba(0, 0, 0, 0.8);
            color: white;
            border-radius: 5px;
            pointer-events: none;
            opacity: 0;
            transition: opacity 0.3s;
            font-size: 12px;
        }
        
        #info {
            position: absolute;
            bottom: 10px;
            right: 10px;
            background: white;
            padding: 10px;
            border-radius: 5px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            font-size: 12px;
        }
        
        .legend {
            position: absolute;
            top: 10px;
            right: 10px;
            background: white;
            padding: 15px;
            border-radius: 5px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        
        .legend-item {
            margin: 5px 0;
        }
        
        .legend-color {
            display: inline-block;
            width: 20px;
            height: 20px;
            margin-right: 5px;
            vertical-align: middle;
            border-radius: 3px;
        }
    </style>
</head>
<body>
    <div id="container">
        <div id="controls">
            <h3>フィルター</h3>
            <input type="text" id="search" placeholder="検索...">
            
            <div class="filter-group">
                <label><input type="checkbox" class="type-filter" value="model" checked> モデル</label>
                <label><input type="checkbox" class="type-filter" value="controller" checked> コントローラー</label>
                <label><input type="checkbox" class="type-filter" value="action" checked> アクション</label>
                <label><input type="checkbox" class="type-filter" value="service" checked> サービス</label>
                <label><input type="checkbox" class="type-filter" value="route" checked> ルート</label>
            </div>
            
            <button id="reset-zoom">ズームリセット</button>
            <button id="center-graph">中央に配置</button>
        </div>
        
        <div class="legend">
            <h4>凡例</h4>
            <div class="legend-item">
                <span class="legend-color" style="background: #ff9999"></span>モデル
            </div>
            <div class="legend-item">
                <span class="legend-color" style="background: #9999ff"></span>コントローラー
            </div>
            <div class="legend-item">
                <span class="legend-color" style="background: #99ff99"></span>アクション
            </div>
            <div class="legend-item">
                <span class="legend-color" style="background: #ffcc99"></span>サービス
            </div>
            <div class="legend-item">
                <span class="legend-color" style="background: #ffff99"></span>ルート
            </div>
        </div>
        
        <div id="info">
            ノード: <span id="node-count">0</span> | 
            エッジ: <span id="edge-count">0</span> |
            ズーム: <span id="zoom-level">100%</span>
        </div>
        
        <div class="tooltip"></div>
    </div>

    <script>
        // データの準備
        const graphData = #{generate_graph_data.to_json};
        
        // 色の定義
        const colors = {
            model: '#ff9999',
            controller: '#9999ff',
            action: '#99ff99',
            service: '#ffcc99',
            route: '#ffff99'
        };
        
        // SVGの設定
        const width = window.innerWidth;
        const height = window.innerHeight;
        
        const svg = d3.select("#container")
            .append("svg")
            .attr("width", width)
            .attr("height", height);
        
        const g = svg.append("g");
        
        // ズーム機能
        const zoom = d3.zoom()
            .scaleExtent([0.1, 10])
            .on("zoom", (event) => {
                g.attr("transform", event.transform);
                d3.select("#zoom-level").text(Math.round(event.transform.k * 100) + "%");
            });
        
        svg.call(zoom);
        
        // Force simulation
        const simulation = d3.forceSimulation(graphData.nodes)
            .force("link", d3.forceLink(graphData.links).id(d => d.id).distance(100))
            .force("charge", d3.forceManyBody().strength(-300))
            .force("center", d3.forceCenter(width / 2, height / 2))
            .force("collision", d3.forceCollide().radius(50));
        
        // リンクの描画
        const link = g.append("g")
            .attr("class", "links")
            .selectAll("line")
            .data(graphData.links)
            .enter().append("line")
            .attr("class", "link")
            .attr("stroke", d => d.type === 'belongs_to' ? '#ff6666' : '#999')
            .attr("stroke-dasharray", d => d.type === 'has_action' ? '5,5' : 'none');
        
        // ノードグループ
        const node = g.append("g")
            .attr("class", "nodes")
            .selectAll("g")
            .data(graphData.nodes)
            .enter().append("g")
            .attr("class", "node")
            .call(d3.drag()
                .on("start", dragstarted)
                .on("drag", dragged)
                .on("end", dragended));
        
        // ノードの円
        node.append("circle")
            .attr("r", d => d.type === 'model' ? 15 : 10)
            .attr("fill", d => colors[d.type] || '#999')
            .attr("stroke", "#fff");
        
        // ノードのラベル
        node.append("text")
            .attr("dy", ".35em")
            .attr("x", 20)
            .text(d => d.name)
            .style("font-size", "12px");
        
        // ツールチップ
        const tooltip = d3.select(".tooltip");
        
        node.on("mouseover", function(event, d) {
            tooltip.transition()
                .duration(200)
                .style("opacity", .9);
            
            let content = `<strong>${d.name}</strong><br/>
                          タイプ: ${d.type}<br/>`;
            
            if (d.attributes) {
                if (d.attributes.associations) {
                    content += `関連: ${d.attributes.associations.join(', ')}<br/>`;
                }
                if (d.attributes.path) {
                    content += `パス: ${d.attributes.path}<br/>`;
                }
                if (d.attributes.verb) {
                    content += `メソッド: ${d.attributes.verb}<br/>`;
                }
            }
            
            tooltip.html(content)
                .style("left", (event.pageX + 10) + "px")
                .style("top", (event.pageY - 28) + "px");
        })
        .on("mouseout", function(d) {
            tooltip.transition()
                .duration(500)
                .style("opacity", 0);
        });
        
        // ダブルクリックで関連ノードのハイライト
        node.on("dblclick", function(event, d) {
            event.stopPropagation();
            highlightConnected(d);
        });
        
        // シミュレーションの更新
        simulation.on("tick", () => {
            link
                .attr("x1", d => d.source.x)
                .attr("y1", d => d.source.y)
                .attr("x2", d => d.target.x)
                .attr("y2", d => d.target.y);
            
            node
                .attr("transform", d => `translate(${d.x},${d.y})`);
        });
        
        // ドラッグ機能
        function dragstarted(event, d) {
            if (!event.active) simulation.alphaTarget(0.3).restart();
            d.fx = d.x;
            d.fy = d.y;
        }
        
        function dragged(event, d) {
            d.fx = event.x;
            d.fy = event.y;
        }
        
        function dragended(event, d) {
            if (!event.active) simulation.alphaTarget(0);
            d.fx = null;
            d.fy = null;
        }
        
        // 検索機能
        d3.select("#search").on("input", function() {
            const searchTerm = this.value.toLowerCase();
            
            node.classed("dimmed", d => {
                return searchTerm && !d.name.toLowerCase().includes(searchTerm);
            });
            
            link.classed("dimmed", d => {
                return searchTerm && 
                    !d.source.name.toLowerCase().includes(searchTerm) && 
                    !d.target.name.toLowerCase().includes(searchTerm);
            });
        });
        
        // フィルター機能
        d3.selectAll(".type-filter").on("change", function() {
            const visibleTypes = [];
            d3.selectAll(".type-filter:checked").each(function() {
                visibleTypes.push(this.value);
            });
            
            node.style("display", d => visibleTypes.includes(d.type) ? null : "none");
            
            link.style("display", d => {
                return visibleTypes.includes(d.source.type) && 
                       visibleTypes.includes(d.target.type) ? null : "none";
            });
        });
        
        // 関連ノードのハイライト
        function highlightConnected(selectedNode) {
            const connectedNodeIds = new Set([selectedNode.id]);
            
            graphData.links.forEach(link => {
                if (link.source.id === selectedNode.id) {
                    connectedNodeIds.add(link.target.id);
                }
                if (link.target.id === selectedNode.id) {
                    connectedNodeIds.add(link.source.id);
                }
            });
            
            node.classed("dimmed", d => !connectedNodeIds.has(d.id));
            node.classed("highlighted", d => connectedNodeIds.has(d.id));
            
            link.classed("dimmed", d => {
                return !connectedNodeIds.has(d.source.id) || !connectedNodeIds.has(d.target.id);
            });
            link.classed("highlighted", d => {
                return connectedNodeIds.has(d.source.id) && connectedNodeIds.has(d.target.id);
            });
        }
        
        // リセット機能
        svg.on("dblclick", function() {
            node.classed("dimmed", false);
            node.classed("highlighted", false);
            link.classed("dimmed", false);
            link.classed("highlighted", false);
        });
        
        // コントロールボタン
        d3.select("#reset-zoom").on("click", () => {
            svg.transition()
                .duration(750)
                .call(zoom.transform, d3.zoomIdentity);
        });
        
        d3.select("#center-graph").on("click", () => {
            const bounds = g.node().getBBox();
            const fullWidth = width;
            const fullHeight = height;
            const widthScale = fullWidth / bounds.width;
            const heightScale = fullHeight / bounds.height;
            const scale = 0.8 * Math.min(widthScale, heightScale);
            const translate = [
                fullWidth / 2 - scale * (bounds.x + bounds.width / 2),
                fullHeight / 2 - scale * (bounds.y + bounds.height / 2)
            ];
            
            svg.transition()
                .duration(750)
                .call(zoom.transform, d3.zoomIdentity
                    .translate(translate[0], translate[1])
                    .scale(scale));
        });
        
        // 情報更新
        d3.select("#node-count").text(graphData.nodes.length);
        d3.select("#edge-count").text(graphData.links.length);
    </script>
</body>
</html>
        HTML
        
        html_content
      end

      private

      def generate_graph_data
        nodes = @graph.nodes.values.map do |node|
          {
            id: node.id,
            name: node.name,
            type: node.type.to_s,
            attributes: node.attributes
          }
        end
        
        links = @graph.edges.map do |edge|
          {
            source: edge.from,
            target: edge.to,
            type: edge.type.to_s,
            label: edge.label
          }
        end
        
        { nodes: nodes, links: links }
      end
  end
end