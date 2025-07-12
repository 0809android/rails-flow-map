require 'spec_helper'

# Integration test to verify basic functionality
RSpec.describe 'RailsFlowMap Integration' do
  describe 'basic graph creation' do
    it 'creates a graph with nodes and edges' do
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
      
      expect(graph.node_count).to eq(2)
      expect(graph.edge_count).to eq(1)
      expect(graph.find_node('model_user')).to eq(user_node)
    end
  end

  describe 'formatting' do
    let(:graph) do
      graph = RailsFlowMap::FlowGraph.new
      
      user_node = RailsFlowMap::FlowNode.new(
        id: 'model_user',
        name: 'User',
        type: :model
      )
      
      route_node = RailsFlowMap::FlowNode.new(
        id: 'route_get_users',
        name: 'GET /users',
        type: :route,
        attributes: { path: '/users', verb: 'GET' }
      )
      
      graph.add_node(user_node)
      graph.add_node(route_node)
      graph
    end

    it 'exports to mermaid format' do
      result = RailsFlowMap.export(graph, format: :mermaid)
      expect(result).to include('graph TD')
      expect(result).to include('model_user[User]')
    end

    it 'exports to sequence format' do
      result = RailsFlowMap.export(graph, format: :sequence)
      expect(result).to include('sequenceDiagram')
    end
  end

  describe 'endpoint matching' do
    let(:graph) do
      graph = RailsFlowMap::FlowGraph.new
      
      route_node = RailsFlowMap::FlowNode.new(
        id: 'route_get_users',
        name: 'GET /users',
        type: :route,
        attributes: { path: '/users', verb: 'GET' }
      )
      
      param_route_node = RailsFlowMap::FlowNode.new(
        id: 'route_get_user',
        name: 'GET /users/:id',
        type: :route,
        attributes: { path: '/users/:id', verb: 'GET' }
      )
      
      graph.add_node(route_node)
      graph.add_node(param_route_node)
      graph
    end

    it 'finds exact path matches' do
      filtered = RailsFlowMap.send(:filter_graph_for_endpoint, graph, '/users')
      expect(filtered.find_node('route_get_users')).not_to be_nil
    end

    it 'finds parameterized path matches' do
      filtered = RailsFlowMap.send(:filter_graph_for_endpoint, graph, '/users/123')
      expect(filtered.find_node('route_get_user')).not_to be_nil
    end
  end
end