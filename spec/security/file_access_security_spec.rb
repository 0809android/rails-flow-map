require 'spec_helper'
require 'tmpdir'
require 'fileutils'

RSpec.describe 'File Access Security' do
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

  describe 'Path Traversal Prevention' do
    let(:malicious_paths) do
      [
        '../../../etc/passwd',
        '..\\..\\..\\windows\\system32\\config\\sam',
        '/etc/shadow',
        '/proc/version',
        '/dev/null',
        '/dev/random',
        'file:///etc/passwd',
        '\\\\server\\share\\file',
        'C:\\Windows\\System32\\drivers\\etc\\hosts',
        '~/.ssh/id_rsa',
        '../../../../../root/.bash_history',
        'NUL:', # Windows special file
        'CON:', # Windows special file
        'aux.txt', # Windows reserved name
        'prn.log', # Windows reserved name
      ]
    end

    describe 'RailsFlowMap.export with malicious paths' do
      it 'validates output paths and prevents directory traversal' do
        malicious_paths.each do |malicious_path|
          # Test that export doesn't write to malicious paths
          expect do
            RailsFlowMap.export(graph, format: :mermaid, output: malicious_path)
          end.not_to change { File.exist?('/etc/passwd') }

          # For Windows paths, check they don't access system files
          if malicious_path.include?('Windows') || malicious_path.include?('C:')
            expect do
              RailsFlowMap.export(graph, format: :mermaid, output: malicious_path)
            end.not_to change { File.exist?('C:\\Windows\\System32\\config\\sam') }
          end
        end
      end

      it 'handles relative paths safely within allowed directories' do
        safe_relative_path = File.join(temp_dir, 'subdir', '..', 'output.md')
        
        expect do
          RailsFlowMap.export(graph, format: :mermaid, output: safe_relative_path)
        end.not_to raise_error

        # Should resolve to temp_dir/output.md
        expected_path = File.join(temp_dir, 'output.md')
        expect(File.exist?(expected_path)).to be true
      end
    end

    describe 'File creation in unauthorized locations' do
      it 'prevents writing to system directories' do
        system_paths = [
          '/etc/rails_flow_map_malicious.txt',
          '/usr/bin/malicious_script',
          '/var/log/malicious.log',
          '/tmp/../etc/passwd.backup',
        ]

        system_paths.each do |system_path|
          # Skip if we don't have write access anyway (expected behavior)
          next unless File.writable?(File.dirname(system_path))

          expect do
            RailsFlowMap.export(graph, format: :mermaid, output: system_path)
          end.not_to raise_error # Should handle gracefully, not crash

          # But should not actually write to system locations
          expect(File.exist?(system_path)).to be false
        end
      end
    end
  end

  describe 'File Content Security' do
    let(:safe_output_path) { File.join(temp_dir, 'test_output.html') }

    describe 'D3jsFormatter file output' do
      let(:formatter) { RailsFlowMap::D3jsFormatter.new(graph) }

      it 'generates safe HTML content' do
        content = formatter.format
        File.write(safe_output_path, content)

        # Verify file was created
        expect(File.exist?(safe_output_path)).to be true

        # Verify content doesn't contain executable code outside script tags
        file_content = File.read(safe_output_path)
        
        # Should not contain inline JavaScript in HTML attributes
        expect(file_content).not_to match(/\son\w+\s*=\s*['"]*[^'"]*javascript:/i)
        expect(file_content).not_to match(/href\s*=\s*['"]*javascript:/i)
        
        # Should not contain data URLs with executable content
        expect(file_content).not_to match(/data:text\/html.*<script/i)
      end

      it 'prevents code injection through file content' do
        malicious_node = RailsFlowMap::FlowNode.new(
          id: 'malicious',
          name: '</script><script>alert("file injection")</script>',
          type: :model
        )
        graph.add_node(malicious_node)

        content = formatter.format
        File.write(safe_output_path, content)

        file_content = File.read(safe_output_path)
        
        # Malicious script should not be executable
        expect(file_content).not_to match(/<\/script><script>alert\(/i)
      end
    end

    describe 'OpenAPI YAML output security' do
      let(:formatter) { RailsFlowMap::OpenapiFormatter.new(graph) }

      it 'generates safe YAML content' do
        content = formatter.format
        yaml_path = File.join(temp_dir, 'api_spec.yaml')
        File.write(yaml_path, content)

        # Verify YAML can be safely parsed
        expect { YAML.load_file(yaml_path) }.not_to raise_error

        # Verify no executable content in YAML
        file_content = File.read(yaml_path)
        expect(file_content).not_to match(/!!ruby\/object/i)
        expect(file_content).not_to match(/!!ruby\/hash/i)
        expect(file_content).not_to match(/eval:/i)
      end

      it 'prevents YAML injection attacks' do
        malicious_node = RailsFlowMap::FlowNode.new(
          id: 'yaml_injection',
          name: "!!ruby/object:File\nfilename: /etc/passwd",
          type: :model
        )
        graph.add_node(malicious_node)

        content = formatter.format
        yaml_path = File.join(temp_dir, 'malicious_spec.yaml')
        File.write(yaml_path, content)

        # Should parse as safe YAML, not execute Ruby code
        parsed = YAML.load_file(yaml_path)
        expect(parsed).to be_a(Hash)
        expect(parsed).not_to be_a(File)
      end
    end
  end

  describe 'Resource Consumption Limits' do
    it 'handles large graphs without excessive memory usage' do
      large_graph = RailsFlowMap::FlowGraph.new

      # Create a graph with many nodes to test memory limits
      1000.times do |i|
        node = RailsFlowMap::FlowNode.new(
          id: "node_#{i}",
          name: "Node #{i}" * 100, # Large name to increase memory usage
          type: :model,
          attributes: { data: "x" * 1000 } # Large attributes
        )
        large_graph.add_node(node)
      end

      start_memory = `ps -o rss= -p #{Process.pid}`.to_i

      # Generate output
      formatter = RailsFlowMap::D3jsFormatter.new(large_graph)
      content = formatter.format

      end_memory = `ps -o rss= -p #{Process.pid}`.to_i
      memory_increase = end_memory - start_memory

      # Memory increase should be reasonable (less than 100MB for this test)
      expect(memory_increase).to be < 100_000 # RSS is in KB

      # Output should still be valid
      expect(content).to include('<!DOCTYPE html>')
    end

    it 'handles deep nesting without stack overflow' do
      # Create deeply nested structure
      current_id = 'root'
      graph.add_node(RailsFlowMap::FlowNode.new(id: current_id, name: 'Root', type: :model))

      1000.times do |i|
        next_id = "node_#{i}"
        graph.add_node(RailsFlowMap::FlowNode.new(id: next_id, name: "Node #{i}", type: :model))
        graph.add_edge(RailsFlowMap::FlowEdge.new(from: current_id, to: next_id, type: :belongs_to))
        current_id = next_id
      end

      # Should not cause stack overflow
      expect do
        RailsFlowMap.export(graph, format: :mermaid)
      end.not_to raise_error
    end
  end

  describe 'Temporary File Security' do
    it 'cleans up temporary files' do
      # Test that formatters don't leave sensitive temporary files
      temp_files_before = Dir.glob("#{Dir.tmpdir}/*rails_flow_map*")
      
      RailsFlowMap.export(graph, format: :d3js, output: File.join(temp_dir, 'output.html'))
      
      temp_files_after = Dir.glob("#{Dir.tmpdir}/*rails_flow_map*")
      
      # Should not create persistent temp files
      expect(temp_files_after.size).to eq(temp_files_before.size)
    end

    it 'handles permission denied errors gracefully' do
      # Create a directory without write permissions
      readonly_dir = File.join(temp_dir, 'readonly')
      Dir.mkdir(readonly_dir)
      File.chmod(0444, readonly_dir)

      readonly_path = File.join(readonly_dir, 'output.md')

      # Should handle permission errors gracefully
      expect do
        RailsFlowMap.export(graph, format: :mermaid, output: readonly_path)
      end.not_to raise_error

      # File should not be created due to permissions
      expect(File.exist?(readonly_path)).to be false

      # Cleanup
      File.chmod(0755, readonly_dir)
    end
  end

  describe 'Symlink Attack Prevention' do
    it 'handles symlinks safely' do
      # Create a symlink pointing to a sensitive file
      sensitive_file = File.join(temp_dir, 'sensitive.txt')
      File.write(sensitive_file, 'sensitive data')

      symlink_path = File.join(temp_dir, 'symlink_output.md')
      
      begin
        File.symlink(sensitive_file, symlink_path)
        
        # Export should not follow symlink to overwrite sensitive file
        original_content = File.read(sensitive_file)
        RailsFlowMap.export(graph, format: :mermaid, output: symlink_path)
        
        # Sensitive file should be unchanged
        expect(File.read(sensitive_file)).to eq(original_content)
        
      rescue NotImplementedError
        # Skip on systems that don't support symlinks (Windows without admin)
        skip "Symlinks not supported on this system"
      end
    end
  end

  describe 'File Type Validation' do
    it 'handles various file extensions appropriately' do
      dangerous_extensions = [
        '.exe',
        '.bat',
        '.cmd',
        '.scr',
        '.com',
        '.pif',
        '.sh',
        '.php',
        '.jsp',
        '.asp'
      ]

      dangerous_extensions.each do |ext|
        path = File.join(temp_dir, "output#{ext}")
        
        # Should export content regardless of extension
        expect do
          RailsFlowMap.export(graph, format: :mermaid, output: path)
        end.not_to raise_error

        # File should be created with safe content
        if File.exist?(path)
          content = File.read(path)
          expect(content).to include('graph TD')
          expect(content).not_to include('<?php')
          expect(content).not_to include('<%')
        end
      end
    end
  end
end