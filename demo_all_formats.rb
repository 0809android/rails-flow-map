#!/usr/bin/env ruby

$LOAD_PATH.unshift(File.expand_path('../lib', __FILE__))

require 'fileutils'
require 'rails_flow_map'

# Create output directory
output_dir = 'demo_output'
FileUtils.mkdir_p(output_dir)

puts "🚀 Rails Flow Map - All Formats Demo"
puts "="*50

# Create a sample graph for demonstration
graph = RailsFlowMap::FlowGraph.new

# Add nodes
user_model = RailsFlowMap::FlowNode.new(
  id: 'user',
  name: 'User',
  type: :model,
  attributes: {
    associations: ['has_many :posts', 'has_many :comments']
  }
)

post_model = RailsFlowMap::FlowNode.new(
  id: 'post',
  name: 'Post',
  type: :model,
  attributes: {
    associations: ['belongs_to :user', 'has_many :comments']
  }
)

comment_model = RailsFlowMap::FlowNode.new(
  id: 'comment',
  name: 'Comment',
  type: :model,
  attributes: {
    associations: ['belongs_to :user', 'belongs_to :post']
  }
)

users_controller = RailsFlowMap::FlowNode.new(
  id: 'users_controller',
  name: 'UsersController',
  type: :controller
)

posts_controller = RailsFlowMap::FlowNode.new(
  id: 'posts_controller',
  name: 'PostsController',
  type: :controller
)

users_index = RailsFlowMap::FlowNode.new(
  id: 'users_index',
  name: 'index',
  type: :action,
  attributes: { controller: 'UsersController' }
)

posts_create = RailsFlowMap::FlowNode.new(
  id: 'posts_create',
  name: 'create',
  type: :action,
  attributes: { controller: 'PostsController' }
)

user_service = RailsFlowMap::FlowNode.new(
  id: 'user_service',
  name: 'UserService',
  type: :service
)

route_users = RailsFlowMap::FlowNode.new(
  id: 'route_users',
  name: 'GET /api/v1/users',
  type: :route,
  attributes: { 
    path: '/api/v1/users',
    verb: 'GET',
    controller: 'users',
    action: 'index'
  }
)

route_posts = RailsFlowMap::FlowNode.new(
  id: 'route_posts',
  name: 'POST /api/v1/posts',
  type: :route,
  attributes: { 
    path: '/api/v1/posts',
    verb: 'POST',
    controller: 'posts',
    action: 'create'
  }
)

# Add nodes to graph
[user_model, post_model, comment_model, users_controller, posts_controller,
 users_index, posts_create, user_service, route_users, route_posts].each do |node|
  graph.add_node(node)
end

# Add edges
graph.add_edge(RailsFlowMap::FlowEdge.new(from: 'post', to: 'user', type: :belongs_to))
graph.add_edge(RailsFlowMap::FlowEdge.new(from: 'comment', to: 'user', type: :belongs_to))
graph.add_edge(RailsFlowMap::FlowEdge.new(from: 'comment', to: 'post', type: :belongs_to))
graph.add_edge(RailsFlowMap::FlowEdge.new(from: 'users_controller', to: 'users_index', type: :has_action))
graph.add_edge(RailsFlowMap::FlowEdge.new(from: 'posts_controller', to: 'posts_create', type: :has_action))
graph.add_edge(RailsFlowMap::FlowEdge.new(from: 'users_index', to: 'user_service', type: :calls_service, label: 'fetch_active_users'))
graph.add_edge(RailsFlowMap::FlowEdge.new(from: 'user_service', to: 'user', type: :accesses_model, label: 'User.active'))
graph.add_edge(RailsFlowMap::FlowEdge.new(from: 'route_users', to: 'users_index', type: :routes_to))
graph.add_edge(RailsFlowMap::FlowEdge.new(from: 'route_posts', to: 'posts_create', type: :routes_to))

puts "\n📊 Testing all visualization formats:\n\n"

# Test all formats
formats = {
  mermaid: 'flow_mermaid.md',
  plantuml: 'flow_plantuml.puml',
  graphviz: 'flow_graphviz.dot',
  erd: 'schema_erd.txt',
  metrics: 'metrics_report.md',
  d3js: 'interactive.html',
  openapi: 'api_spec.yaml',
  sequence: 'sequence_diagram.md'
}

formats.each do |format, filename|
  output_path = File.join(output_dir, filename)
  
  begin
    print "  ✅ Generating #{format.to_s.upcase} format... "
    
    if format == :sequence
      # Sequence formatter needs endpoint option
      result = RailsFlowMap.export(graph, format: format, output: output_path, endpoint: '/api/v1/users')
    else
      result = RailsFlowMap.export(graph, format: format, output: output_path)
    end
    
    puts "Done! (#{File.size(output_path)} bytes)"
  rescue => e
    puts "❌ Error: #{e.message}"
  end
end

# Test Git Diff functionality
puts "\n🔄 Testing Git Diff visualization:\n"

# Create a modified graph
modified_graph = graph.dup
new_service = RailsFlowMap::FlowNode.new(
  id: 'post_service',
  name: 'PostService',
  type: :service
)
modified_graph.add_node(new_service)
modified_graph.add_edge(RailsFlowMap::FlowEdge.new(from: 'posts_create', to: 'post_service', type: :calls_service))

begin
  print "  ✅ Generating Git Diff visualization... "
  diff_result = RailsFlowMap.diff(graph, modified_graph, format: :mermaid)
  diff_output = File.join(output_dir, 'architecture_diff.md')
  File.write(diff_output, diff_result)
  puts "Done! (#{File.size(diff_output)} bytes)"
rescue => e
  puts "❌ Error: #{e.message}"
end

puts "\n✨ Demo complete! Check the '#{output_dir}' directory for all generated files."
puts "\n📁 Generated files:"
Dir.glob(File.join(output_dir, '*')).sort.each do |file|
  puts "   - #{File.basename(file)}"
end

# Open the interactive visualization if on macOS
if RUBY_PLATFORM =~ /darwin/
  interactive_path = File.join(output_dir, 'interactive.html')
  if File.exist?(interactive_path)
    puts "\n🌐 Opening interactive visualization in browser..."
    system("open #{interactive_path}")
  end
end