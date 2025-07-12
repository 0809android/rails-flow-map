#!/usr/bin/env ruby

puts "🚀 RailsFlowMap 新フォーマットデモ"
puts "=" * 50

# Load dependencies
require_relative 'blog_sample/blog_sample/lib/mock_rails'
$LOAD_PATH.unshift(File.expand_path('lib', __dir__))
require 'set'
require 'rails_flow_map'
require 'fileutils'

begin
  puts "\n1. サンプルグラフ作成中..."
  
  graph = RailsFlowMap::FlowGraph.new
  
  # Add sample nodes
  user = RailsFlowMap::FlowNode.new(
    id: 'model_user',
    name: 'User',
    type: :model,
    attributes: { associations: ['has_many :posts', 'has_many :comments', 'has_many :likes'] }
  )
  
  post = RailsFlowMap::FlowNode.new(
    id: 'model_post',
    name: 'Post',
    type: :model,
    attributes: { associations: ['belongs_to :user', 'has_many :comments'] }
  )
  
  comment = RailsFlowMap::FlowNode.new(
    id: 'model_comment',
    name: 'Comment',
    type: :model,
    attributes: { associations: ['belongs_to :user', 'belongs_to :post'] }
  )
  
  users_controller = RailsFlowMap::FlowNode.new(
    id: 'controller_users',
    name: 'UsersController',
    type: :controller
  )
  
  # Add multiple actions to show complexity
  actions = ['index', 'show', 'create', 'update', 'destroy', 'follow', 'unfollow', 'analytics']
  action_nodes = actions.map do |action|
    RailsFlowMap::FlowNode.new(
      id: "action_users_#{action}",
      name: action,
      type: :action,
      attributes: { controller: 'UsersController' }
    )
  end
  
  user_service = RailsFlowMap::FlowNode.new(
    id: 'service_user',
    name: 'UserService',
    type: :service
  )
  
  # Add all nodes
  [user, post, comment, users_controller, user_service, *action_nodes].each do |node|
    graph.add_node(node)
  end
  
  # Add edges
  edges = [
    # Model relationships
    RailsFlowMap::FlowEdge.new(from: 'model_user', to: 'model_post', type: :has_many, label: 'posts'),
    RailsFlowMap::FlowEdge.new(from: 'model_user', to: 'model_comment', type: :has_many, label: 'comments'),
    RailsFlowMap::FlowEdge.new(from: 'model_post', to: 'model_user', type: :belongs_to, label: 'user'),
    RailsFlowMap::FlowEdge.new(from: 'model_post', to: 'model_comment', type: :has_many, label: 'comments'),
    RailsFlowMap::FlowEdge.new(from: 'model_comment', to: 'model_user', type: :belongs_to, label: 'user'),
    RailsFlowMap::FlowEdge.new(from: 'model_comment', to: 'model_post', type: :belongs_to, label: 'post'),
    
    # Controller to actions
    *action_nodes.map { |action| 
      RailsFlowMap::FlowEdge.new(from: 'controller_users', to: action.id, type: :has_action)
    },
    
    # Actions to service
    RailsFlowMap::FlowEdge.new(from: 'action_users_index', to: 'service_user', type: :calls_service),
    RailsFlowMap::FlowEdge.new(from: 'action_users_analytics', to: 'service_user', type: :calls_service),
    
    # Service to model
    RailsFlowMap::FlowEdge.new(from: 'service_user', to: 'model_user', type: :accesses_model, label: 'User.active')
  ]
  
  edges.each { |edge| graph.add_edge(edge) }
  
  puts "   ✓ グラフ作成完了: #{graph.node_count}ノード, #{graph.edge_count}エッジ"
  
  FileUtils.mkdir_p('doc/flow_maps')
  
  puts "\n2. ERDフォーマット生成中..."
  erd_output = RailsFlowMap.export(graph, format: :erd, output: 'doc/flow_maps/sample_erd.txt')
  puts "   ✓ ERD saved to doc/flow_maps/sample_erd.txt"
  puts "\nERDプレビュー:"
  puts "-" * 40
  puts erd_output.split("\n")[0..20].join("\n")
  puts "..."
  
  puts "\n3. メトリクスレポート生成中..."
  metrics_output = RailsFlowMap.export(graph, format: :metrics, output: 'doc/flow_maps/metrics_report.md')
  puts "   ✓ Metrics saved to doc/flow_maps/metrics_report.md"
  puts "\nメトリクスプレビュー:"
  puts "-" * 40
  puts metrics_output.split("\n")[0..15].join("\n")
  puts "..."
  
  puts "\n" + "=" * 50
  puts "✅ 新フォーマットのデモ完了!"
  
  puts "\n📁 生成されたファイル:"
  ['doc/flow_maps/sample_erd.txt', 'doc/flow_maps/metrics_report.md'].each do |file|
    if File.exist?(file)
      size = File.size(file)
      puts "   - #{file} (#{size} bytes)"
    end
  end
  
  puts "\n💡 追加された可視化形式:"
  puts "   - **ERD (Entity Relationship Diagram)**: データベーススキーマ風の表示"
  puts "   - **Metrics Report**: 複雑度分析と推奨事項"
  puts "   - 詳細は FUTURE_FORMATS.md を参照"
  
rescue => e
  puts "\n❌ エラーが発生しました:"
  puts "   #{e.message}"
  puts "\nBacktrace:"
  puts e.backtrace.first(5).map { |line| "   #{line}" }
end