require 'spec_helper'

RSpec.describe RailsFlowMap::MermaidFormatter do
  let(:formatter) { described_class.new }
  let(:graph) { RailsFlowMap::FlowGraph.new }

  describe "#format" do
    context "with simple model relationships" do
      before do
        user_node = RailsFlowMap::FlowNode.new(id: "model_user", name: "User", type: :model)
        post_node = RailsFlowMap::FlowNode.new(id: "model_post", name: "Post", type: :model)
        
        graph.add_node(user_node)
        graph.add_node(post_node)
        
        edge = RailsFlowMap::FlowEdge.new(
          from: "model_user",
          to: "model_post",
          type: :has_many,
          label: "posts"
        )
        graph.add_edge(edge)
      end

      it "generates correct mermaid syntax" do
        result = formatter.format(graph)
        
        expect(result).to include("graph TD")
        expect(result).to include("model_user[User]")
        expect(result).to include("model_post[Post]")
        expect(result).to include("model_user ==>|posts| model_post")
        expect(result).to include("classDef model")
      end
    end

    context "with controller and actions" do
      before do
        controller_node = RailsFlowMap::FlowNode.new(
          id: "controller_users",
          name: "UsersController",
          type: :controller
        )
        action_node = RailsFlowMap::FlowNode.new(
          id: "action_users_index",
          name: "index",
          type: :action
        )
        
        graph.add_node(controller_node)
        graph.add_node(action_node)
        
        edge = RailsFlowMap::FlowEdge.new(
          from: "controller_users",
          to: "action_users_index",
          type: :has_action
        )
        graph.add_edge(edge)
      end

      it "uses different shapes for different node types" do
        result = formatter.format(graph)
        
        expect(result).to include("controller_users[[UsersController]]")
        expect(result).to include("action_users_index(index)")
        expect(result).to include("controller_users -.-> action_users_index")
      end
    end

    context "with special characters in names" do
      before do
        node = RailsFlowMap::FlowNode.new(
          id: "model_special",
          name: "User<Admin>",
          type: :model
        )
        graph.add_node(node)
      end

      it "escapes special characters" do
        result = formatter.format(graph)
        expect(result).to include("User&lt;Admin&gt;")
      end
    end

    context "with different edge types" do
      before do
        user = RailsFlowMap::FlowNode.new(id: "model_user", name: "User", type: :model)
        profile = RailsFlowMap::FlowNode.new(id: "model_profile", name: "Profile", type: :model)
        
        graph.add_node(user)
        graph.add_node(profile)
      end

      it "uses correct arrow for belongs_to" do
        edge = RailsFlowMap::FlowEdge.new(from: "model_profile", to: "model_user", type: :belongs_to)
        graph.add_edge(edge)
        
        result = formatter.format(graph)
        expect(result).to include("model_profile --> model_user")
      end

      it "uses correct arrow for has_and_belongs_to_many" do
        edge = RailsFlowMap::FlowEdge.new(from: "model_user", to: "model_profile", type: :has_and_belongs_to_many)
        graph.add_edge(edge)
        
        result = formatter.format(graph)
        expect(result).to include("model_user <==> model_profile")
      end
    end
  end
end