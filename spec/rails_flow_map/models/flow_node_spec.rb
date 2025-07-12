require 'spec_helper'

RSpec.describe RailsFlowMap::FlowNode do
  let(:node) do
    described_class.new(
      id: "model_user",
      name: "User",
      type: :model,
      attributes: { table_name: "users" },
      file_path: "app/models/user.rb",
      line_number: 1
    )
  end

  describe "#initialize" do
    it "sets all attributes correctly" do
      expect(node.id).to eq("model_user")
      expect(node.name).to eq("User")
      expect(node.type).to eq(:model)
      expect(node.attributes).to eq({ table_name: "users" })
      expect(node.file_path).to eq("app/models/user.rb")
      expect(node.line_number).to eq(1)
    end
  end

  describe "#model?" do
    it "returns true for model type" do
      expect(node.model?).to be true
    end

    it "returns false for other types" do
      controller_node = described_class.new(id: "c1", name: "UsersController", type: :controller)
      expect(controller_node.model?).to be false
    end
  end

  describe "#controller?" do
    it "returns true for controller type" do
      controller_node = described_class.new(id: "c1", name: "UsersController", type: :controller)
      expect(controller_node.controller?).to be true
    end

    it "returns false for model type" do
      expect(node.controller?).to be false
    end
  end

  describe "#action?" do
    it "returns true for action type" do
      action_node = described_class.new(id: "a1", name: "index", type: :action)
      expect(action_node.action?).to be true
    end

    it "returns false for model type" do
      expect(node.action?).to be false
    end
  end

  describe "#to_h" do
    it "returns a hash representation" do
      expected = {
        id: "model_user",
        name: "User",
        type: :model,
        attributes: { table_name: "users" },
        file_path: "app/models/user.rb",
        line_number: 1
      }
      expect(node.to_h).to eq(expected)
    end
  end
end