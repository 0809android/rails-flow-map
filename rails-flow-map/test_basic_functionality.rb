#!/usr/bin/env ruby

$LOAD_PATH.unshift(File.expand_path('lib', __dir__))
require 'rails_flow_map'

puts "Testing RailsFlowMap basic functionality..."

begin
  # Test 1: Create basic graph
  puts "\n1. Testing basic graph creation..."
  graph = RailsFlowMap::FlowGraph.new
  
  user_node = RailsFlowMap::FlowNode.new(
    id: 'model_user',
    name: 'User', 
    type: :model
  )
  
  post_node = RailsFlowMap::FlowNode.new(
    id: 'model_post',
    name: 'Post',
    type: :model
  )
  
  edge = RailsFlowMap::FlowEdge.new(
    from: 'model_user',
    to: 'model_post', 
    type: :has_many,
    label: 'posts'
  )
  
  graph.add_node(user_node)
  graph.add_node(post_node)
  graph.add_edge(edge)
  
  puts "✓ Graph created with #{graph.node_count} nodes and #{graph.edge_count} edges"
  
  # Test 2: Test Mermaid formatting
  puts "\n2. Testing Mermaid formatting..."
  result = RailsFlowMap.export(graph, format: :mermaid)
  puts "✓ Mermaid format generated (#{result.split("\n").length} lines)"
  
  # Test 3: Test route node
  puts "\n3. Testing route functionality..."
  route_node = RailsFlowMap::FlowNode.new(
    id: 'route_get_users',
    name: 'GET /users',
    type: :route,
    attributes: { path: '/users', verb: 'GET' }
  )
  
  graph.add_node(route_node)
  puts "✓ Route node added successfully"
  
  # Test 4: Test endpoint filtering
  puts "\n4. Testing endpoint filtering..."
  routes = graph.nodes_by_type(:route)
  puts "✓ Found #{routes.length} route nodes"
  
  # Test 5: Test sequence formatting
  puts "\n5. Testing sequence formatting..."
  seq_result = RailsFlowMap.export(graph, format: :sequence)
  puts "✓ Sequence format generated (#{seq_result.split("\n").length} lines)"
  
  puts "\n✅ All basic functionality tests passed!"
  
rescue => e
  puts "\n❌ Error occurred: #{e.message}"
  puts "Backtrace:"
  puts e.backtrace.first(5)
end