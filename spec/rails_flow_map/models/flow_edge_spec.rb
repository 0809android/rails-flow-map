require 'spec_helper'

RSpec.describe RailsFlowMap::FlowEdge do
  let(:edge) do
    described_class.new(
      from: "model_user",
      to: "model_post",
      type: :has_many,
      label: "posts",
      attributes: { through: nil }
    )
  end

  describe "#initialize" do
    it "sets all attributes correctly" do
      expect(edge.from).to eq("model_user")
      expect(edge.to).to eq("model_post")
      expect(edge.type).to eq(:has_many)
      expect(edge.label).to eq("posts")
      expect(edge.attributes).to eq({ through: nil })
    end
  end

  describe "#association?" do
    it "returns true for association types" do
      [:belongs_to, :has_one, :has_many, :has_and_belongs_to_many].each do |type|
        edge = described_class.new(from: "a", to: "b", type: type)
        expect(edge.association?).to be true
      end
    end

    it "returns false for non-association types" do
      action_edge = described_class.new(from: "a", to: "b", type: :action_flow)
      expect(action_edge.association?).to be false
    end
  end

  describe "#action_flow?" do
    it "returns true for action_flow type" do
      action_edge = described_class.new(from: "a", to: "b", type: :action_flow)
      expect(action_edge.action_flow?).to be true
    end

    it "returns false for association types" do
      expect(edge.action_flow?).to be false
    end
  end

  describe "#to_h" do
    it "returns a hash representation" do
      expected = {
        from: "model_user",
        to: "model_post",
        type: :has_many,
        label: "posts",
        attributes: { through: nil }
      }
      expect(edge.to_h).to eq(expected)
    end
  end
end