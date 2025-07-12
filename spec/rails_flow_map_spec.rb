require 'spec_helper'

RSpec.describe RailsFlowMap do
  it "has a version number" do
    expect(RailsFlowMap::VERSION).not_to be nil
  end

  describe ".configuration" do
    it "returns a configuration instance" do
      expect(RailsFlowMap.configuration).to be_a(RailsFlowMap::Configuration)
    end

    it "allows configuration via block" do
      RailsFlowMap.configure do |config|
        config.default_format = :plantuml
      end

      expect(RailsFlowMap.configuration.default_format).to eq(:plantuml)
    end
  end

  describe ".export" do
    let(:graph) { RailsFlowMap::FlowGraph.new }
    
    before do
      node = RailsFlowMap::FlowNode.new(id: "model_user", name: "User", type: :model)
      graph.add_node(node)
    end

    context "with mermaid format" do
      it "returns mermaid formatted output" do
        result = RailsFlowMap.export(graph, format: :mermaid)
        expect(result).to include("graph TD")
        expect(result).to include("model_user[User]")
      end
    end

    context "with unsupported format" do
      it "raises an error" do
        expect {
          RailsFlowMap.export(graph, format: :invalid)
        }.to raise_error(RailsFlowMap::Error, "Unsupported format: invalid")
      end
    end

    context "with output file" do
      let(:output_file) { "tmp/test_output.md" }
      
      after { File.delete(output_file) if File.exist?(output_file) }

      it "writes to the specified file" do
        RailsFlowMap.export(graph, format: :mermaid, output: output_file)
        expect(File.exist?(output_file)).to be true
      end
    end
  end
end