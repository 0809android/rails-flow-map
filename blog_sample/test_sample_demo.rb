#!/usr/bin/env ruby

puts "🚀 RailsFlowMap Demo with Sample Blog Project"
puts "=" * 60

# Load path
$LOAD_PATH.unshift(File.expand_path('lib', __dir__))

# Load Mock Rails first
require_relative 'blog_sample/lib/mock_rails'

# Load RailsFlowMap
require 'rails_flow_map'

begin
  puts "\n1. Testing basic graph creation..."
  graph = RailsFlowMap::FlowGraph.new
  
  # Manually create sample nodes for demo
  user_model = RailsFlowMap::FlowNode.new(
    id: 'model_user',
    name: 'User',
    type: :model,
    attributes: { associations: ['has_many :posts', 'has_many :comments'] }
  )
  
  post_model = RailsFlowMap::FlowNode.new(
    id: 'model_post', 
    name: 'Post',
    type: :model,
    attributes: { associations: ['belongs_to :user', 'has_many :comments'] }
  )
  
  comment_model = RailsFlowMap::FlowNode.new(
    id: 'model_comment',
    name: 'Comment', 
    type: :model,
    attributes: { associations: ['belongs_to :user', 'belongs_to :post'] }
  )
  
  # Add routes
  users_route = RailsFlowMap::FlowNode.new(
    id: 'route_get_api_v1_users',
    name: 'GET /api/v1/users',
    type: :route,
    attributes: { path: '/api/v1/users', verb: 'GET', controller: 'api/v1/users', action: 'index' }
  )
  
  posts_route = RailsFlowMap::FlowNode.new(
    id: 'route_get_api_v1_posts',
    name: 'GET /api/v1/posts',
    type: :route,
    attributes: { path: '/api/v1/posts', verb: 'GET', controller: 'api/v1/posts', action: 'index' }
  )
  
  # Add controllers and actions
  users_controller = RailsFlowMap::FlowNode.new(
    id: 'controller_api_v1_users',
    name: 'Api::V1::UsersController',
    type: :controller
  )
  
  users_index_action = RailsFlowMap::FlowNode.new(
    id: 'action_api_v1_users_index',
    name: 'index',
    type: :action,
    attributes: { controller: 'Api::V1::UsersController' }
  )
  
  posts_controller = RailsFlowMap::FlowNode.new(
    id: 'controller_api_v1_posts',
    name: 'Api::V1::PostsController',
    type: :controller
  )
  
  posts_index_action = RailsFlowMap::FlowNode.new(
    id: 'action_api_v1_posts_index',
    name: 'index',
    type: :action,
    attributes: { controller: 'Api::V1::PostsController' }
  )
  
  # Add services
  user_service = RailsFlowMap::FlowNode.new(
    id: 'service_user_service',
    name: 'UserService',
    type: :service
  )
  
  post_service = RailsFlowMap::FlowNode.new(
    id: 'service_post_service',
    name: 'PostService',
    type: :service
  )
  
  # Add nodes to graph
  [user_model, post_model, comment_model, users_route, posts_route,
   users_controller, users_index_action, posts_controller, posts_index_action,
   user_service, post_service].each do |node|
    graph.add_node(node)
  end
  
  # Add edges (relationships)
  edges = [
    # Model associations
    RailsFlowMap::FlowEdge.new(from: 'model_user', to: 'model_post', type: :has_many, label: 'posts'),
    RailsFlowMap::FlowEdge.new(from: 'model_user', to: 'model_comment', type: :has_many, label: 'comments'),
    RailsFlowMap::FlowEdge.new(from: 'model_post', to: 'model_user', type: :belongs_to, label: 'user'),
    RailsFlowMap::FlowEdge.new(from: 'model_post', to: 'model_comment', type: :has_many, label: 'comments'),
    RailsFlowMap::FlowEdge.new(from: 'model_comment', to: 'model_user', type: :belongs_to, label: 'user'),
    RailsFlowMap::FlowEdge.new(from: 'model_comment', to: 'model_post', type: :belongs_to, label: 'post'),
    
    # Route to action mappings
    RailsFlowMap::FlowEdge.new(from: 'route_get_api_v1_users', to: 'action_api_v1_users_index', type: :routes_to),
    RailsFlowMap::FlowEdge.new(from: 'route_get_api_v1_posts', to: 'action_api_v1_posts_index', type: :routes_to),
    
    # Controller to action mappings
    RailsFlowMap::FlowEdge.new(from: 'controller_api_v1_users', to: 'action_api_v1_users_index', type: :has_action),
    RailsFlowMap::FlowEdge.new(from: 'controller_api_v1_posts', to: 'action_api_v1_posts_index', type: :has_action),
    
    # Action to service calls
    RailsFlowMap::FlowEdge.new(from: 'action_api_v1_users_index', to: 'service_user_service', type: :calls_service, label: 'fetch_active_users'),
    RailsFlowMap::FlowEdge.new(from: 'action_api_v1_posts_index', to: 'service_post_service', type: :calls_service, label: 'public_posts'),
    
    # Service to model access
    RailsFlowMap::FlowEdge.new(from: 'service_user_service', to: 'model_user', type: :accesses_model, label: 'User.active'),
    RailsFlowMap::FlowEdge.new(from: 'service_post_service', to: 'model_post', type: :accesses_model, label: 'Post.published'),
  ]
  
  edges.each { |edge| graph.add_edge(edge) }
  
  puts "   ✓ Created sample graph with #{graph.node_count} nodes and #{graph.edge_count} edges"
  
  # Create output directory
  require 'fileutils'
  FileUtils.mkdir_p('doc/flow_maps')
  
  puts "\n2. Generating different output formats..."
  
  # Test Mermaid format
  mermaid_output = RailsFlowMap.export(graph, format: :mermaid, output: 'doc/flow_maps/complete_flow.md')
  puts "   ✓ Mermaid diagram saved to doc/flow_maps/complete_flow.md"
  
  # Test PlantUML format  
  plantuml_output = RailsFlowMap.export(graph, format: :plantuml, output: 'doc/flow_maps/models.puml')
  puts "   ✓ PlantUML diagram saved to doc/flow_maps/models.puml"
  
  # Test GraphViz format
  graphviz_output = RailsFlowMap.export(graph, format: :graphviz, output: 'doc/flow_maps/graph.dot')
  puts "   ✓ GraphViz diagram saved to doc/flow_maps/graph.dot"
  
  # Test Sequence format
  sequence_output = RailsFlowMap.export(graph, format: :sequence, output: 'doc/flow_maps/sequences.md')
  puts "   ✓ Sequence diagram saved to doc/flow_maps/sequences.md"
  
  puts "\n3. Sample Mermaid output preview:"
  puts "-" * 50
  puts mermaid_output.split("\n").first(20).join("\n")
  puts "... (see full output in doc/flow_maps/complete_flow.md)"
  
  puts "\n4. Endpoint-specific analysis demo:"
  
  # Filter graph for specific endpoint
  users_endpoint_graph = RailsFlowMap::FlowGraph.new
  
  # Add nodes related to /api/v1/users endpoint
  [users_route, users_controller, users_index_action, user_service, user_model].each do |node|
    users_endpoint_graph.add_node(node)
  end
  
  # Add relevant edges
  endpoint_edges = [
    RailsFlowMap::FlowEdge.new(from: 'route_get_api_v1_users', to: 'action_api_v1_users_index', type: :routes_to),
    RailsFlowMap::FlowEdge.new(from: 'controller_api_v1_users', to: 'action_api_v1_users_index', type: :has_action),
    RailsFlowMap::FlowEdge.new(from: 'action_api_v1_users_index', to: 'service_user_service', type: :calls_service, label: 'fetch_active_users'),
    RailsFlowMap::FlowEdge.new(from: 'service_user_service', to: 'model_user', type: :accesses_model, label: 'User.active')
  ]
  
  endpoint_edges.each { |edge| users_endpoint_graph.add_edge(edge) }
  
  users_sequence = RailsFlowMap.export(users_endpoint_graph, format: :sequence, output: 'doc/flow_maps/users_endpoint_sequence.md', endpoint: '/api/v1/users')
  puts "   ✓ Users endpoint sequence diagram saved"
  
  puts "\n" + "=" * 60
  puts "✅ RailsFlowMap Demo completed successfully!"
  puts "\nGenerated files:"
  Dir.glob('doc/flow_maps/*').each do |file|
    size = File.size(file)
    puts "   - #{file} (#{size} bytes)"
  end
  
  puts "\n📊 Graph Statistics:"
  puts "   - Total nodes: #{graph.node_count}"
  puts "   - Total edges: #{graph.edge_count}"
  puts "   - Models: #{graph.nodes_by_type(:model).count}"
  puts "   - Controllers: #{graph.nodes_by_type(:controller).count}"
  puts "   - Actions: #{graph.nodes_by_type(:action).count}"
  puts "   - Routes: #{graph.nodes_by_type(:route).count}"
  puts "   - Services: #{graph.nodes_by_type(:service).count}"
  
  puts "\n💡 Usage in real Rails project:"
  puts "   1. Add gem 'rails-flow-map' to your Gemfile"
  puts "   2. Run: rails generate rails_flow_map:install"
  puts "   3. Run: rake rails_flow_map:generate"
  puts "   4. Run: rake rails_flow_map:endpoint['/api/users',sequence]"
  puts "   5. Run: rake rails_flow_map:api_docs"
  
rescue => e
  puts "\n❌ Error occurred during demo:"
  puts "   #{e.message}"
  puts "\nBacktrace:"
  puts e.backtrace.first(10).map { |line| "   #{line}" }
end