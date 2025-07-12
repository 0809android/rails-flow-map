require 'spec_helper'

RSpec.describe RailsFlowMap::GitDiffFormatter do
  let(:before_graph) { RailsFlowMap::FlowGraph.new }
  let(:after_graph) { RailsFlowMap::FlowGraph.new }
  let(:formatter) { described_class.new(before_graph, after_graph) }

  before do
    # Setup before graph
    user_node = RailsFlowMap::FlowNode.new(
      id: 'user',
      name: 'User',
      type: :model,
      attributes: { associations: ['has_many :posts'] }
    )

    post_node = RailsFlowMap::FlowNode.new(
      id: 'post',
      name: 'Post',
      type: :model,
      attributes: { associations: ['belongs_to :user'] }
    )

    users_controller = RailsFlowMap::FlowNode.new(
      id: 'users_controller',
      name: 'UsersController',
      type: :controller
    )

    before_graph.add_node(user_node)
    before_graph.add_node(post_node)
    before_graph.add_node(users_controller)

    edge1 = RailsFlowMap::FlowEdge.new(from: 'post', to: 'user', type: :belongs_to)
    before_graph.add_edge(edge1)

    # Setup after graph (with changes)
    # Keep existing nodes
    after_graph.add_node(user_node)
    after_graph.add_node(post_node)
    after_graph.add_node(users_controller)

    # Add new node
    comment_node = RailsFlowMap::FlowNode.new(
      id: 'comment',
      name: 'Comment',
      type: :model,
      attributes: { associations: ['belongs_to :user', 'belongs_to :post'] }
    )
    after_graph.add_node(comment_node)

    # Modify existing node
    modified_user = RailsFlowMap::FlowNode.new(
      id: 'user',
      name: 'User',
      type: :model,
      attributes: { associations: ['has_many :posts', 'has_many :comments'] }
    )
    after_graph.nodes['user'] = modified_user

    # Keep existing edge
    after_graph.add_edge(edge1)

    # Add new edges
    edge2 = RailsFlowMap::FlowEdge.new(from: 'comment', to: 'user', type: :belongs_to)
    edge3 = RailsFlowMap::FlowEdge.new(from: 'comment', to: 'post', type: :belongs_to)
    after_graph.add_edge(edge2)
    after_graph.add_edge(edge3)
  end

  describe '#initialize' do
    it 'initializes with two graphs and options' do
      options = { format: :html, include_metrics: true }
      formatter = described_class.new(before_graph, after_graph, options)

      expect(formatter.instance_variable_get(:@before_graph)).to eq(before_graph)
      expect(formatter.instance_variable_get(:@after_graph)).to eq(after_graph)
      expect(formatter.instance_variable_get(:@format)).to eq(:html)
    end

    it 'uses default format when not specified' do
      expect(formatter.instance_variable_get(:@format)).to eq(:mermaid)
    end
  end

  describe '#format' do
    context 'with mermaid format' do
      let(:mermaid_output) { formatter.format }

      it 'generates mermaid diagram' do
        expect(mermaid_output).to include('```mermaid')
        expect(mermaid_output).to include('graph TD')
        expect(mermaid_output).to include('```')
      end

      it 'includes legend' do
        expect(mermaid_output).to include('subgraph Legend')
        expect(mermaid_output).to include('Added[Added - Green]:::added')
        expect(mermaid_output).to include('Removed[Removed - Red]:::removed')
        expect(mermaid_output).to include('Modified[Modified - Yellow]:::modified')
      end

      it 'includes all nodes with proper status' do
        expect(mermaid_output).to include('User[User]')
        expect(mermaid_output).to include('Post[Post]')
        expect(mermaid_output).to include('Comment[Comment]')
        expect(mermaid_output).to include('UsersController[[UsersController]]')
      end

      it 'includes styling classes' do
        expect(mermaid_output).to include('classDef added fill:#90EE90')
        expect(mermaid_output).to include('classDef removed fill:#FFB6C1')
        expect(mermaid_output).to include('classDef modified fill:#FFFFE0')
      end

      it 'includes change summary' do
        expect(mermaid_output).to include('## 変更サマリー')
        expect(mermaid_output).to include('### 📊 メトリクス変化')
        expect(mermaid_output).to include('ノード数:')
        expect(mermaid_output).to include('エッジ数:')
        expect(mermaid_output).to include('複雑度:')
      end
    end

    context 'with html format' do
      let(:html_formatter) { described_class.new(before_graph, after_graph, format: :html) }
      let(:html_output) { html_formatter.format }

      it 'generates valid HTML' do
        expect(html_output).to include('<!DOCTYPE html>')
        expect(html_output).to include('<html>')
        expect(html_output).to include('</html>')
      end

      it 'includes title' do
        expect(html_output).to include('Rails Flow Map - Git Diff Visualization')
      end

      it 'includes D3.js script' do
        expect(html_output).to include('https://d3js.org/d3.v7.min.js')
      end

      it 'includes metrics cards' do
        expect(html_output).to include('metric-card')
        expect(html_output).to include('<h3>ノード</h3>')
        expect(html_output).to include('<h3>エッジ</h3>')
        expect(html_output).to include('<h3>複雑度</h3>')
      end

      it 'includes diff visualization area' do
        expect(html_output).to include('id="diff-graph"')
      end
    end

    context 'with text format' do
      let(:text_formatter) { described_class.new(before_graph, after_graph, format: :text) }
      let(:text_output) { text_formatter.format }

      it 'generates text report' do
        expect(text_output).to include('Rails Flow Map - Architecture Diff Report')
        expect(text_output).to include('=' * 50)
      end

      it 'lists added nodes' do
        expect(text_output).to include('## Added Nodes')
        expect(text_output).to include('+ model: Comment')
      end

      it 'lists modified nodes' do
        expect(text_output).to include('## Modified Nodes')
        expect(text_output).to include('~ model: User')
      end

      it 'includes metrics section' do
        expect(text_output).to include('## Metrics')
        expect(text_output).to include('Nodes:')
        expect(text_output).to include('Edges:')
        expect(text_output).to include('Complexity:')
      end
    end
  end

  describe 'difference analysis' do
    let(:diff_result) { formatter.send(:analyze_differences) }

    it 'detects added nodes' do
      expect(diff_result[:added_nodes]).not_to be_empty
      added_names = diff_result[:added_nodes].map(&:name)
      expect(added_names).to include('Comment')
    end

    it 'detects modified nodes' do
      expect(diff_result[:modified_nodes]).not_to be_empty
      modified = diff_result[:modified_nodes].first
      expect(modified[:before].name).to eq('User')
      expect(modified[:after].name).to eq('User')
      expect(modified[:changes]).not_to be_empty
    end

    it 'detects added edges' do
      expect(diff_result[:added_edges]).not_to be_empty
      expect(diff_result[:added_edges].size).to eq(2)
    end

    it 'calculates metrics changes' do
      metrics = diff_result[:metrics_change]
      
      expect(metrics[:nodes][:before]).to eq(3)
      expect(metrics[:nodes][:after]).to eq(4)
      expect(metrics[:nodes][:change]).to eq(1)
      
      expect(metrics[:edges][:before]).to eq(1)
      expect(metrics[:edges][:after]).to eq(3)
      expect(metrics[:edges][:change]).to eq(2)
    end

    it 'generates summary' do
      summary = diff_result[:summary]
      
      expect(summary[:total_changes]).to be > 0
      expect(summary[:breaking_changes]).to be_an(Array)
      expect(summary[:recommendations]).to be_an(Array)
    end
  end

  describe 'node change detection' do
    let(:original_user) do
      RailsFlowMap::FlowNode.new(
        id: 'user',
        name: 'User',
        type: :model,
        attributes: { associations: ['has_many :posts'] }
      )
    end

    let(:modified_user) do
      RailsFlowMap::FlowNode.new(
        id: 'user',
        name: 'User',
        type: :model,
        attributes: { associations: ['has_many :posts', 'has_many :comments'] }
      )
    end

    it 'detects attribute changes' do
      changed = formatter.send(:node_changed?, original_user, modified_user)
      expect(changed).to be true
    end

    it 'detects specific association changes' do
      changes = formatter.send(:detect_node_changes, original_user, modified_user)
      
      association_change = changes.find { |c| c[:type] == :associations_added }
      expect(association_change).to be_present
      expect(association_change[:items]).to include('has_many :comments')
    end

    it 'returns false for identical nodes' do
      changed = formatter.send(:node_changed?, original_user, original_user)
      expect(changed).to be false
    end
  end

  describe 'breaking change detection' do
    before do
      # Remove a controller to create a breaking change
      after_graph.nodes.delete('users_controller')
    end

    it 'detects breaking changes' do
      diff_result = formatter.send(:analyze_differences)
      breaking_changes = diff_result[:summary][:breaking_changes]
      
      expect(breaking_changes).not_to be_empty
      expect(breaking_changes.first).to include("Controller 'UsersController' was removed")
    end
  end

  describe 'recommendation generation' do
    context 'with many additions' do
      before do
        # Add many nodes to trigger recommendation
        (1..15).each do |i|
          node = RailsFlowMap::FlowNode.new(
            id: "new_node_#{i}",
            name: "NewNode#{i}",
            type: :model
          )
          after_graph.add_node(node)
        end
      end

      it 'recommends breaking down large changes' do
        diff_result = formatter.send(:analyze_differences)
        recommendations = diff_result[:summary][:recommendations]
        
        breaking_down_rec = recommendations.find { |r| r.include?('smaller commits') }
        expect(breaking_down_rec).to be_present
      end
    end
  end

  describe 'HTML escaping' do
    before do
      malicious_node = RailsFlowMap::FlowNode.new(
        id: 'malicious',
        name: '<script>alert("xss")</script>',
        type: :model
      )
      after_graph.add_node(malicious_node)
    end

    context 'with HTML format' do
      let(:html_formatter) { described_class.new(before_graph, after_graph, format: :html) }

      it 'properly escapes HTML in breaking changes' do
        # Add a breaking change with malicious content
        allow(formatter).to receive(:detect_breaking_changes).and_return(['<script>alert("xss")</script>'])
        
        html_output = html_formatter.format
        expect(html_output).to include('&lt;script&gt;alert("xss")&lt;/script&gt;')
        expect(html_output).not_to include('<script>alert("xss")</script>')
      end
    end
  end

  describe 'error handling' do
    context 'with nil graphs' do
      it 'handles nil before_graph gracefully' do
        formatter = described_class.new(nil, after_graph)
        
        expect { formatter.format }.not_to raise_error
      end
    end

    context 'with empty graphs' do
      let(:empty_before) { RailsFlowMap::FlowGraph.new }
      let(:empty_after) { RailsFlowMap::FlowGraph.new }
      let(:formatter) { described_class.new(empty_before, empty_after) }

      it 'handles empty graphs gracefully' do
        output = formatter.format
        
        expect(output).to include('```mermaid')
        expect(output).to include('変更サマリー')
      end
    end

    context 'with invalid format' do
      it 'defaults to mermaid for unknown formats' do
        formatter = described_class.new(before_graph, after_graph, format: :unknown)
        output = formatter.format
        
        expect(output).to include('```mermaid')
      end
    end
  end
end