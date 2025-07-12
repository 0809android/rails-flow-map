require 'spec_helper'

RSpec.describe RailsFlowMap::FlowGraph do
  let(:graph) { described_class.new }
  let(:user_node) { RailsFlowMap::FlowNode.new(id: "model_user", name: "User", type: :model) }
  let(:post_node) { RailsFlowMap::FlowNode.new(id: "model_post", name: "Post", type: :model) }
  let(:edge) { RailsFlowMap::FlowEdge.new(from: "model_user", to: "model_post", type: :has_many) }

  describe "#initialize" do
    it "creates empty nodes and edges collections" do
      expect(graph.nodes).to eq({})
      expect(graph.edges).to eq([])
    end
  end

  describe "#add_node" do
    it "adds a node to the graph" do
      graph.add_node(user_node)
      expect(graph.nodes["model_user"]).to eq(user_node)
    end
  end

  describe "#add_edge" do
    it "adds an edge to the graph" do
      graph.add_edge(edge)
      expect(graph.edges).to include(edge)
    end
  end

  describe "#find_node" do
    before { graph.add_node(user_node) }

    it "returns the node with the given id" do
      expect(graph.find_node("model_user")).to eq(user_node)
    end

    it "returns nil for non-existent id" do
      expect(graph.find_node("non_existent")).to be_nil
    end
  end

  describe "#nodes_by_type" do
    before do
      graph.add_node(user_node)
      graph.add_node(post_node)
      controller_node = RailsFlowMap::FlowNode.new(id: "c1", name: "UsersController", type: :controller)
      graph.add_node(controller_node)
    end

    it "returns nodes of the specified type" do
      models = graph.nodes_by_type(:model)
      expect(models).to contain_exactly(user_node, post_node)
    end

    it "returns empty array for non-existent type" do
      expect(graph.nodes_by_type(:invalid)).to eq([])
    end
  end

  describe "#edges_by_type" do
    before do
      graph.add_edge(edge)
      belongs_to_edge = RailsFlowMap::FlowEdge.new(from: "model_post", to: "model_user", type: :belongs_to)
      graph.add_edge(belongs_to_edge)
    end

    it "returns edges of the specified type" do
      has_many_edges = graph.edges_by_type(:has_many)
      expect(has_many_edges).to contain_exactly(edge)
    end
  end

  describe "#connected_nodes" do
    let(:comment_node) { RailsFlowMap::FlowNode.new(id: "model_comment", name: "Comment", type: :model) }

    before do
      graph.add_node(user_node)
      graph.add_node(post_node)
      graph.add_node(comment_node)
      
      graph.add_edge(edge) # user -> post
      graph.add_edge(RailsFlowMap::FlowEdge.new(from: "model_post", to: "model_comment", type: :has_many))
      graph.add_edge(RailsFlowMap::FlowEdge.new(from: "model_comment", to: "model_user", type: :belongs_to))
    end

    context "with direction :outgoing" do
      it "returns nodes connected from the given node" do
        connected = graph.connected_nodes("model_user", direction: :outgoing)
        expect(connected).to contain_exactly(post_node)
      end
    end

    context "with direction :incoming" do
      it "returns nodes connected to the given node" do
        connected = graph.connected_nodes("model_user", direction: :incoming)
        expect(connected).to contain_exactly(comment_node)
      end
    end

    context "with direction :both" do
      it "returns all connected nodes" do
        connected = graph.connected_nodes("model_post", direction: :both)
        expect(connected).to contain_exactly(user_node, comment_node)
      end
    end
  end

  describe "#to_h" do
    before do
      graph.add_node(user_node)
      graph.add_edge(edge)
    end

    it "returns a hash representation of the graph" do
      result = graph.to_h
      expect(result[:nodes]).to have_key("model_user")
      expect(result[:nodes]["model_user"]).to eq(user_node.to_h)
      expect(result[:edges]).to contain_exactly(edge.to_h)
    end
  end
end