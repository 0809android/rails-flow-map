#!/usr/bin/env ruby
# frozen_string_literal: true

# Basic Usage Examples for Rails Flow Map
#
# This file demonstrates the most common usage patterns for Rails Flow Map.
# Run with: ruby examples/basic_usage.rb

require_relative '../lib/rails_flow_map'

class BasicUsageExamples
  def self.run_all
    puts "🚀 Rails Flow Map - Basic Usage Examples"
    puts "=" * 50
    
    # Create a sample graph for demonstration
    graph = create_sample_graph
    
    example_1_basic_export(graph)
    example_2_multiple_formats(graph)
    example_3_file_output(graph)
    example_4_configuration(graph)
    example_5_error_handling(graph)
    
    puts "\n✅ All examples completed successfully!"
  end

  # Example 1: Basic graph analysis and export
  def self.example_1_basic_export(graph)
    puts "\n📋 Example 1: Basic Export"
    puts "-" * 30
    
    # Generate Mermaid diagram
    mermaid_output = RailsFlowMap.export(graph, format: :mermaid)
    
    puts "Generated Mermaid diagram:"
    puts mermaid_output[0..200] + "..." # Show first 200 characters
    puts "✓ Mermaid export successful"
  end

  # Example 2: Multiple output formats
  def self.example_2_multiple_formats(graph)
    puts "\n🎨 Example 2: Multiple Formats"
    puts "-" * 30
    
    formats = [:mermaid, :plantuml, :erd, :metrics]
    
    formats.each do |format|
      begin
        output = RailsFlowMap.export(graph, format: format)
        puts "✓ #{format.to_s.capitalize} format: #{output.length} characters"
      rescue => e
        puts "✗ #{format.to_s.capitalize} format failed: #{e.message}"
      end
    end
  end

  # Example 3: Saving to files
  def self.example_3_file_output(graph)
    puts "\n💾 Example 3: File Output"
    puts "-" * 30
    
    # Create temporary directory for examples
    output_dir = File.join(Dir.pwd, 'tmp', 'flow_map_examples')
    FileUtils.mkdir_p(output_dir)
    
    files = {
      mermaid: File.join(output_dir, 'architecture.md'),
      d3js: File.join(output_dir, 'interactive.html'),
      openapi: File.join(output_dir, 'api_spec.yaml'),
      metrics: File.join(output_dir, 'metrics.md')
    }
    
    files.each do |format, filepath|
      begin
        RailsFlowMap.export(graph, format: format, output: filepath)
        
        if File.exist?(filepath)
          file_size = File.size(filepath)
          puts "✓ #{format}: #{filepath} (#{file_size} bytes)"
        else
          puts "✗ #{format}: File not created"
        end
      rescue => e
        puts "✗ #{format}: Export failed - #{e.message}"
      end
    end
    
    puts "\n📁 Files saved to: #{output_dir}"
  end

  # Example 4: Using configuration
  def self.example_4_configuration(graph)
    puts "\n⚙️  Example 4: Configuration"
    puts "-" * 30
    
    # Configure Rails Flow Map
    RailsFlowMap.configure do |config|
      # These would normally be set based on your Rails app
      config.output_dir = 'tmp/flow_maps'
      config.excluded_paths = ['vendor/', 'tmp/']
    end
    
    # Export with configuration applied
    output = RailsFlowMap.export(graph, format: :mermaid)
    puts "✓ Configuration applied successfully"
    puts "✓ Output directory: #{RailsFlowMap.configuration.output_dir}"
    puts "✓ Excluded paths: #{RailsFlowMap.configuration.excluded_paths.join(', ')}"
  end

  # Example 5: Error handling
  def self.example_5_error_handling(graph)
    puts "\n🛡️  Example 5: Error Handling"
    puts "-" * 30
    
    # Test invalid format
    begin
      RailsFlowMap.export(graph, format: :invalid_format)
    rescue RailsFlowMap::InvalidInputError => e
      puts "✓ Caught expected error: #{e.class.name}"
      puts "  Message: #{e.message}"
      puts "  Error code: #{e.error_code}"
    end
    
    # Test invalid output path
    begin
      RailsFlowMap.export(graph, format: :mermaid, output: '/etc/passwd')
    rescue RailsFlowMap::SecurityError => e
      puts "✓ Caught security error: #{e.class.name}"
      puts "  Message: #{e.message}"
    end
    
    # Test with invalid graph
    begin
      RailsFlowMap.export("not a graph", format: :mermaid)
    rescue RailsFlowMap::InvalidInputError => e
      puts "✓ Caught validation error: #{e.class.name}"
      puts "  Context: #{e.context}"
    end
  end

  private

  # Create a sample graph for demonstration
  def self.create_sample_graph
    graph = RailsFlowMap::FlowGraph.new
    
    # Add sample nodes
    user_model = RailsFlowMap::FlowNode.new(
      id: 'user',
      name: 'User',
      type: :model,
      attributes: { 
        associations: ['has_many :posts', 'has_many :comments'],
        validations: ['validates :email, presence: true']
      }
    )
    
    post_model = RailsFlowMap::FlowNode.new(
      id: 'post',
      name: 'Post',
      type: :model,
      attributes: { 
        associations: ['belongs_to :user', 'has_many :comments']
      }
    )
    
    comment_model = RailsFlowMap::FlowNode.new(
      id: 'comment',
      name: 'Comment',
      type: :model,
      attributes: { 
        associations: ['belongs_to :user', 'belongs_to :post']
      }
    )
    
    users_controller = RailsFlowMap::FlowNode.new(
      id: 'users_controller',
      name: 'UsersController',
      type: :controller,
      attributes: { 
        actions: ['index', 'show', 'create', 'update', 'destroy']
      }
    )
    
    posts_controller = RailsFlowMap::FlowNode.new(
      id: 'posts_controller',
      name: 'PostsController',
      type: :controller,
      attributes: { 
        actions: ['index', 'show', 'create', 'update', 'destroy']
      }
    )
    
    # Add route nodes
    users_route = RailsFlowMap::FlowNode.new(
      id: 'users_route',
      name: 'GET /api/v1/users',
      type: :route,
      attributes: {
        path: '/api/v1/users',
        verb: 'GET',
        controller: 'api/v1/users',
        action: 'index'
      }
    )
    
    # Add nodes to graph
    [user_model, post_model, comment_model, users_controller, posts_controller, users_route].each do |node|
      graph.add_node(node)
    end
    
    # Add edges (relationships)
    edges = [
      RailsFlowMap::FlowEdge.new(from: 'post', to: 'user', type: :belongs_to),
      RailsFlowMap::FlowEdge.new(from: 'comment', to: 'user', type: :belongs_to),
      RailsFlowMap::FlowEdge.new(from: 'comment', to: 'post', type: :belongs_to),
      RailsFlowMap::FlowEdge.new(from: 'users_controller', to: 'user', type: :uses_model),
      RailsFlowMap::FlowEdge.new(from: 'posts_controller', to: 'post', type: :uses_model),
      RailsFlowMap::FlowEdge.new(from: 'users_route', to: 'users_controller', type: :routes_to)
    ]
    
    edges.each { |edge| graph.add_edge(edge) }
    
    graph
  end
end

# Run examples if this file is executed directly
if __FILE__ == $0
  BasicUsageExamples.run_all
end