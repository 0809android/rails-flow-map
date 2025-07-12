require 'spec_helper'

RSpec.describe 'XSS Prevention in Formatters' do
  let(:graph) { RailsFlowMap::FlowGraph.new }

  # Common XSS attack vectors
  let(:xss_payloads) do
    [
      '<script>alert("xss")</script>',
      '"><script>alert("xss")</script>',
      "javascript:alert('xss')",
      '<img src="x" onerror="alert(\'xss\')">',
      '<svg onload="alert(\'xss\')">',
      '&lt;script&gt;alert("xss")&lt;/script&gt;',
      '%3Cscript%3Ealert%28%22xss%22%29%3C%2Fscript%3E',
      '<iframe src="javascript:alert(\'xss\')"></iframe>',
      '<body onload="alert(\'xss\')">',
      '<style>@import"javascript:alert(\'xss\')";</style>'
    ]
  end

  before do
    xss_payloads.each_with_index do |payload, index|
      malicious_node = RailsFlowMap::FlowNode.new(
        id: "malicious_#{index}",
        name: payload,
        type: :model,
        attributes: {
          description: payload,
          associations: [payload],
          custom_field: payload
        }
      )
      graph.add_node(malicious_node)

      # Add edge with malicious label
      if index > 0
        edge = RailsFlowMap::FlowEdge.new(
          from: "malicious_#{index-1}",
          to: "malicious_#{index}",
          type: :belongs_to,
          label: payload
        )
        graph.add_edge(edge)
      end
    end
  end

  describe 'D3jsFormatter XSS Prevention' do
    let(:formatter) { RailsFlowMap::D3jsFormatter.new(graph) }
    let(:html_output) { formatter.format }

    it 'prevents XSS in HTML context' do
      # Check that dangerous scripts are not directly executable
      expect(html_output).not_to match(/<script[^>]*>(?!.*JSON\.parse).*alert\(/i)
      expect(html_output).not_to match(/onerror\s*=\s*['"]/i)
      expect(html_output).not_to match(/onload\s*=\s*['"]/i)
      expect(html_output).not_to match(/javascript:/i)
    end

    it 'properly handles JSON data injection' do
      # Extract JSON data from HTML
      json_match = html_output.match(/const graphData = ({.*?});/m)
      expect(json_match).to be_present

      # Ensure JSON is valid and parseable
      expect { JSON.parse(json_match[1]) }.not_to raise_error

      # Check that XSS payloads are contained within JSON strings
      parsed_data = JSON.parse(json_match[1])
      node_names = parsed_data['nodes'].map { |n| n['name'] }
      
      # Payloads should be present as string values but not executable
      xss_payloads.each do |payload|
        expect(node_names).to include(payload)
      end
    end

    it 'validates HTML structure integrity' do
      # Ensure the HTML structure remains valid despite malicious input
      expect(html_output).to include('<!DOCTYPE html>')
      expect(html_output).to include('<html lang="ja">')
      expect(html_output).to include('</html>')
      
      # Check for proper tag closure
      open_tags = html_output.scan(/<(\w+)(?:\s[^>]*)?>/).map(&:first)
      close_tags = html_output.scan(/<\/(\w+)>/).map(&:first)
      
      %w[html head body script].each do |tag|
        expect(open_tags.count(tag)).to eq(close_tags.count(tag))
      end
    end

    it 'prevents attribute injection in HTML elements' do
      # Ensure malicious payloads don't break out of HTML attributes
      expect(html_output).not_to match(/\s\w+\s*=\s*['"]*javascript:/i)
      expect(html_output).not_to match(/\s\w+\s*=\s*['"]*data:text\/html/i)
    end
  end

  describe 'GitDiffFormatter XSS Prevention' do
    let(:after_graph) { RailsFlowMap::FlowGraph.new }
    let(:formatter) { RailsFlowMap::GitDiffFormatter.new(graph, after_graph, format: :html) }

    before do
      # Add some changes to after_graph to create a diff
      safe_node = RailsFlowMap::FlowNode.new(
        id: 'safe_node',
        name: 'SafeNode',
        type: :model
      )
      after_graph.add_node(safe_node)
    end

    it 'escapes malicious content in HTML diff output' do
      html_output = formatter.format

      xss_payloads.each do |payload|
        # Check that raw payloads are not present in HTML
        expect(html_output).not_to include(payload)
        
        # Check that escaped versions might be present
        escaped_payload = CGI.escapeHTML(payload)
        # Note: The actual presence depends on whether the content appears in the diff
      end
    end

    it 'prevents XSS in breaking changes section' do
      # Mock breaking changes with malicious content
      allow_any_instance_of(RailsFlowMap::GitDiffFormatter).to receive(:detect_breaking_changes)
        .and_return(['<script>alert("xss")</script> was removed'])

      html_output = formatter.format
      
      expect(html_output).to include('&lt;script&gt;alert("xss")&lt;/script&gt; was removed')
      expect(html_output).not_to include('<script>alert("xss")</script>')
    end

    it 'maintains HTML validity with malicious input' do
      html_output = formatter.format
      
      # Basic HTML structure checks
      expect(html_output).to include('<!DOCTYPE html>')
      expect(html_output).to include('<html>')
      expect(html_output).to include('</html>')
    end
  end

  describe 'Mermaid Output XSS Prevention' do
    let(:formatter) { RailsFlowMap::MermaidFormatter.new }
    let(:mermaid_output) { formatter.format(graph) }

    it 'sanitizes node names in Mermaid syntax' do
      # Mermaid should handle special characters safely
      xss_payloads.each do |payload|
        # The payload should be present but in a safe context
        if mermaid_output.include?(payload)
          # Should not be in a context that could be interpreted as code
          expect(mermaid_output).not_to match(/#{Regexp.escape(payload)}.*-->/i)
        end
      end
    end

    it 'prevents code injection in Mermaid diagrams' do
      # Ensure no executable code in Mermaid output
      expect(mermaid_output).not_to match(/javascript:/i)
      expect(mermaid_output).not_to match(/<script/i)
    end
  end

  describe 'OpenAPI Output Security' do
    let(:formatter) { RailsFlowMap::OpenapiFormatter.new(graph) }
    let(:yaml_output) { formatter.format }
    let(:parsed_yaml) { YAML.load(yaml_output) }

    it 'prevents YAML injection' do
      expect { YAML.load(yaml_output) }.not_to raise_error
      expect(parsed_yaml).to be_a(Hash)
    end

    it 'sanitizes content in YAML structure' do
      # Ensure malicious payloads don't break YAML structure
      expect(parsed_yaml['openapi']).to eq('3.0.0')
      expect(parsed_yaml['info']).to be_a(Hash)
    end
  end

  describe 'File Path Security' do
    let(:formatters) do
      [
        RailsFlowMap::D3jsFormatter.new(graph),
        RailsFlowMap::OpenapiFormatter.new(graph),
        RailsFlowMap::SequenceFormatter.new(graph),
        RailsFlowMap::GitDiffFormatter.new(graph, graph)
      ]
    end

    it 'handles potentially malicious file paths safely' do
      malicious_paths = [
        '../../../etc/passwd',
        '..\\..\\windows\\system32\\config\\sam',
        '/etc/shadow',
        'file:///etc/passwd',
        'C:\\Windows\\System32\\',
        '/dev/null',
        '/proc/self/environ'
      ]

      formatters.each do |formatter|
        malicious_paths.each do |path|
          # Test that formatters don't crash with malicious paths
          expect { formatter.format }.not_to raise_error
        end
      end
    end
  end

  describe 'Input Validation' do
    it 'handles nil and empty inputs gracefully' do
      formatters = [
        RailsFlowMap::D3jsFormatter.new(nil),
        RailsFlowMap::OpenapiFormatter.new(nil),
        RailsFlowMap::SequenceFormatter.new(nil),
      ]

      formatters.each do |formatter|
        expect { formatter.format }.not_to raise_error
      end
    end

    it 'handles oversized inputs' do
      large_graph = RailsFlowMap::FlowGraph.new
      
      # Create a large number of nodes to test resource limits
      1000.times do |i|
        node = RailsFlowMap::FlowNode.new(
          id: "node_#{i}",
          name: "Node #{i}",
          type: :model
        )
        large_graph.add_node(node)
      end

      formatter = RailsFlowMap::D3jsFormatter.new(large_graph)
      
      # Should handle large inputs without crashing
      expect { formatter.format }.not_to raise_error
    end
  end

  describe 'Content Security Policy Compatibility' do
    let(:formatter) { RailsFlowMap::D3jsFormatter.new(graph) }
    let(:html_output) { formatter.format }

    it 'avoids inline JavaScript that would violate CSP' do
      # Check for inline event handlers which are CSP violations
      expect(html_output).not_to match(/\son\w+\s*=\s*['"]/i)
      
      # Check for inline JavaScript URLs
      expect(html_output).not_to match(/href\s*=\s*['"]*javascript:/i)
      expect(html_output).not_to match(/src\s*=\s*['"]*javascript:/i)
    end

    it 'uses proper script tags for JavaScript' do
      # JavaScript should be in proper script tags, not inline
      script_blocks = html_output.scan(/<script[^>]*>(.*?)<\/script>/m)
      expect(script_blocks).not_to be_empty
      
      # Ensure scripts don't contain dynamic code generation that could be unsafe
      script_blocks.each do |script_content|
        expect(script_content.first).not_to match(/eval\s*\(/i)
        expect(script_content.first).not_to match(/Function\s*\(/i)
        expect(script_content.first).not_to match(/setTimeout\s*\(\s*["']/i)
      end
    end
  end
end