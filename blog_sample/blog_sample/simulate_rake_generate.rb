#!/usr/bin/env ruby

puts "🚀 rake rails_flow_map:generate をシミュレート中..."
puts "=" * 50

# Load dependencies
require_relative 'lib/mock_rails'
$LOAD_PATH.unshift(File.expand_path('../../../../lib', __dir__))
require 'set'
require 'rails_flow_map'

begin
  # Load configuration
  require_relative 'config/initializers/rails_flow_map'
  
  puts "\n1. 設定読み込み完了 ✓"
  
  # Analyze the application
  puts "\n2. アプリケーション解析中..."
  graph = RailsFlowMap.analyze
  
  puts "   - ノード数: #{graph.node_count}"
  puts "   - エッジ数: #{graph.edge_count}"
  puts "   - モデル: #{graph.nodes_by_type(:model).count}"
  puts "   - コントローラー: #{graph.nodes_by_type(:controller).count}"
  puts "   - アクション: #{graph.nodes_by_type(:action).count}"
  puts "   - ルート: #{graph.nodes_by_type(:route).count}"
  puts "   - サービス: #{graph.nodes_by_type(:service).count}"
  
  # Create output directory
  require 'fileutils'
  FileUtils.mkdir_p('doc/flow_maps')
  
  # Generate all formats
  puts "\n3. 図表生成中..."
  
  formats = [
    { format: :mermaid, file: 'doc/flow_maps/application_flow.md', desc: 'Mermaidフローダイアグラム' },
    { format: :plantuml, file: 'doc/flow_maps/application_models.puml', desc: 'PlantUMLダイアグラム' },
    { format: :graphviz, file: 'doc/flow_maps/application_graph.dot', desc: 'GraphVizダイアグラム' }
  ]
  
  formats.each do |config|
    puts "   - #{config[:desc]}を生成中..."
    result = RailsFlowMap.export(graph, format: config[:format], output: config[:file])
    puts "     ✓ #{config[:file]}に保存 (#{result.length}文字)"
  end
  
  puts "\n4. サンプル出力プレビュー:"
  puts "-" * 40
  
  # Show sample output
  sample = RailsFlowMap.export(graph, format: :mermaid)
  puts sample.split("\n")[0..10].join("\n")
  puts "..."
  
  puts "\n" + "=" * 50
  puts "✅ rake rails_flow_map:generate 完了!"
  
  puts "\n📁 生成されたファイル:"
  Dir.glob('doc/flow_maps/*').each do |file|
    size = File.size(file)
    puts "   - #{file} (#{size} bytes)"
  end
  
rescue => e
  puts "\n❌ エラーが発生しました:"
  puts "   #{e.message}"
  puts "\nBacktrace:"
  puts e.backtrace.first(5).map { |line| "   #{line}" }
end