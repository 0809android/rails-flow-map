require 'spec_helper'
require 'tempfile'
require 'fileutils'

RSpec.describe 'Error Handling Integration' do
  let(:graph) { RailsFlowMap::FlowGraph.new }
  let(:temp_dir) { Dir.mktmpdir }

  before do
    # Create a simple test graph
    user_node = RailsFlowMap::FlowNode.new(
      id: 'user',
      name: 'User',
      type: :model
    )
    graph.add_node(user_node)
  end

  after do
    FileUtils.remove_entry(temp_dir)
  end

  describe 'RailsFlowMap.export with error handling' do
    context 'with invalid format' do
      it 'raises InvalidInputError with helpful context' do
        expect do
          RailsFlowMap.export(graph, format: :invalid_format)
        end.to raise_error(RailsFlowMap::InvalidInputError) do |error|
          expect(error.message).to include("Unsupported format: invalid_format")
          expect(error.context[:format]).to eq(:invalid_format)
          expect(error.context[:supported_formats]).to be_an(Array)
        end
      end
    end

    context 'with invalid graph parameter' do
      it 'raises InvalidInputError for non-graph object' do
        expect do
          RailsFlowMap.export("not a graph", format: :mermaid)
        end.to raise_error(RailsFlowMap::InvalidInputError) do |error|
          expect(error.message).to include("Invalid input during export")
          expect(error.context[:operation]).to eq("export")
        end
      end
    end

    context 'with invalid output path' do
      it 'raises SecurityError for path traversal attempts' do
        malicious_path = File.join(temp_dir, '..', '..', 'etc', 'passwd')
        
        expect do
          RailsFlowMap.export(graph, format: :mermaid, output: malicious_path)
        end.to raise_error(RailsFlowMap::SecurityError) do |error|
          expect(error.message).to include("Path traversal detected")
          expect(error.context[:path]).to eq(malicious_path)
        end
      end

      it 'raises SecurityError for system directory paths' do
        system_path = '/etc/malicious_file.txt'
        
        expect do
          RailsFlowMap.export(graph, format: :mermaid, output: system_path)
        end.to raise_error(RailsFlowMap::SecurityError) do |error|
          expect(error.message).to include("system directory")
          expect(error.context[:path]).to eq(system_path)
        end
      end

      it 'raises FileOperationError for non-existent parent directory' do
        invalid_path = File.join(temp_dir, 'non_existent_dir', 'output.md')
        
        expect do
          RailsFlowMap.export(graph, format: :mermaid, output: invalid_path)
        end.to raise_error(RailsFlowMap::FileOperationError) do |error|
          expect(error.message).to include("Parent directory does not exist")
          expect(error.context[:path]).to eq(invalid_path)
        end
      end

      it 'raises FileOperationError for read-only parent directory' do
        readonly_dir = File.join(temp_dir, 'readonly')
        Dir.mkdir(readonly_dir)
        File.chmod(0444, readonly_dir)
        
        readonly_path = File.join(readonly_dir, 'output.md')
        
        expect do
          RailsFlowMap.export(graph, format: :mermaid, output: readonly_path)
        end.to raise_error(RailsFlowMap::FileOperationError) do |error|
          expect(error.message).to include("not writable")
          expect(error.context[:path]).to eq(readonly_path)
        end
        
        # Cleanup
        File.chmod(0755, readonly_dir)
      end
    end

    context 'with successful operations' do
      it 'exports successfully with valid parameters' do
        output_path = File.join(temp_dir, 'test_output.md')
        
        expect do
          result = RailsFlowMap.export(graph, format: :mermaid, output: output_path)
          expect(result).to include('graph TD')
          expect(File.exist?(output_path)).to be true
          expect(File.read(output_path)).to include('graph TD')
        end.not_to raise_error
      end

      it 'returns formatted output without file when output is nil' do
        expect do
          result = RailsFlowMap.export(graph, format: :mermaid)
          expect(result).to include('graph TD')
        end.not_to raise_error
      end
    end
  end

  describe 'RailsFlowMap.analyze with error handling' do
    context 'with file system errors' do
      before do
        # Mock ModelAnalyzer to raise file system error
        allow_any_instance_of(RailsFlowMap::ModelAnalyzer).to receive(:analyze) do
          raise Errno::EACCES, "Permission denied"
        end
      end

      it 'converts system errors to RailsFlowMap errors' do
        expect do
          RailsFlowMap.analyze
        end.to raise_error(RailsFlowMap::FileOperationError) do |error|
          expect(error.message).to include("File operation failed during analyze")
          expect(error.context[:operation]).to eq("analyze")
          expect(error.context[:original_error]).to eq("Errno::EACCES")
        end
      end
    end

    context 'with successful analysis' do
      it 'analyzes successfully and logs metrics' do
        log_output = StringIO.new
        RailsFlowMap::Logging.logger = Logger.new(log_output)
        
        result_graph = RailsFlowMap.analyze
        
        expect(result_graph).to be_a(RailsFlowMap::FlowGraph)
        
        log_content = log_output.string
        expect(log_content).to include('Graph Analysis: completed')
        expect(log_content).to include('operation=analyze')
      end
    end
  end

  describe 'Formatter-specific error handling' do
    context 'with D3jsFormatter' do
      it 'handles malicious node data safely' do
        malicious_node = RailsFlowMap::FlowNode.new(
          id: 'malicious',
          name: '<script>alert("xss")</script>',
          type: :model
        )
        graph.add_node(malicious_node)
        
        expect do
          result = RailsFlowMap.export(graph, format: :d3js)
          expect(result).to include('<!DOCTYPE html>')
          # Should not contain executable script tags outside of JSON
          expect(result).not_to match(/<script[^>]*>(?!.*JSON\.parse).*alert\(/i)
        end.not_to raise_error
      end
    end

    context 'with OpenapiFormatter' do
      it 'handles empty graph gracefully' do
        empty_graph = RailsFlowMap::FlowGraph.new
        
        expect do
          result = RailsFlowMap.export(empty_graph, format: :openapi)
          parsed = YAML.load(result)
          expect(parsed['openapi']).to eq('3.0.0')
          expect(parsed['paths']).to be_empty
        end.not_to raise_error
      end
    end
  end

  describe 'Resource limit protection' do
    context 'with large graphs' do
      let(:large_graph) { RailsFlowMap::FlowGraph.new }

      before do
        # Create a moderately large graph
        100.times do |i|
          node = RailsFlowMap::FlowNode.new(
            id: "node_#{i}",
            name: "Node #{i}",
            type: :model
          )
          large_graph.add_node(node)
        end
      end

      it 'handles large graphs without exceeding reasonable limits' do
        start_time = Time.now
        
        expect do
          result = RailsFlowMap.export(large_graph, format: :mermaid)
          expect(result).to include('graph TD')
        end.not_to raise_error
        
        duration = Time.now - start_time
        expect(duration).to be < 5.0 # Should complete within 5 seconds
      end
    end
  end

  describe 'Logging integration' do
    let(:log_output) { StringIO.new }
    let(:logger) { Logger.new(log_output) }

    before do
      RailsFlowMap::Logging.logger = logger
    end

    it 'logs export operations with performance metrics' do
      output_path = File.join(temp_dir, 'logged_output.md')
      
      RailsFlowMap.export(graph, format: :mermaid, output: output_path)
      
      log_content = log_output.string
      expect(log_content).to include('Performance: export completed')
      expect(log_content).to include('operation=export')
      expect(log_content).to include('format=mermaid')
      expect(log_content).to include('Successfully exported to')
    end

    it 'logs errors with full context' do
      expect do
        RailsFlowMap.export(graph, format: :invalid_format)
      end.to raise_error(RailsFlowMap::InvalidInputError)
      
      log_content = log_output.string
      expect(log_content).to include('ERROR')
      expect(log_content).to include('operation=export')
      expect(log_content).to include('InvalidInputError')
    end

    it 'logs security events when dangerous paths are blocked' do
      malicious_path = '/etc/malicious_file.txt'
      
      expect do
        RailsFlowMap.export(graph, format: :mermaid, output: malicious_path)
      end.to raise_error(RailsFlowMap::SecurityError)
      
      log_content = log_output.string
      expect(log_content).to include('SECURITY: Dangerous output path blocked')
      expect(log_content).to include(malicious_path)
    end
  end

  describe 'User-friendly error messages' do
    it 'provides helpful error messages for common issues' do
      # Test invalid format
      begin
        RailsFlowMap.export(graph, format: :invalid)
      rescue => e
        message = RailsFlowMap::ErrorHandler.user_friendly_message(e)
        expect(message).to include("Invalid input provided")
      end

      # Test file permission error
      begin
        RailsFlowMap.export(graph, format: :mermaid, output: '/etc/test.md')
      rescue => e
        message = RailsFlowMap::ErrorHandler.user_friendly_message(e)
        expect(message).to include("Security validation failed")
      end
    end
  end
end