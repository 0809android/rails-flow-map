#!/usr/bin/env ruby
# frozen_string_literal: true

# Advanced Patterns and Use Cases for Rails Flow Map
#
# This file demonstrates advanced usage patterns including:
# - Performance optimization
# - Custom analysis workflows
# - Integration patterns
# - Complex filtering and configuration

require_relative '../lib/rails_flow_map'
require 'benchmark'

class AdvancedPatternsExamples
  def self.run_all
    puts "🔬 Rails Flow Map - Advanced Patterns"
    puts "=" * 50
    
    example_1_performance_optimization
    example_2_custom_workflows
    example_3_batch_processing
    example_4_filtering_and_focus
    example_5_integration_patterns
    example_6_custom_formatters
    example_7_monitoring_and_logging
    
    puts "\n🎯 Advanced examples completed!"
  end

  # Example 1: Performance optimization for large applications
  def self.example_1_performance_optimization
    puts "\n⚡ Example 1: Performance Optimization"
    puts "-" * 40
    
    # Create a large sample graph
    large_graph = create_large_sample_graph(1000)
    
    # Benchmark different export strategies
    results = Benchmark.measure do
      # Use streaming for large graphs
      RailsFlowMap.export(large_graph, 
        format: :mermaid,
        max_depth: 3,  # Limit complexity
        streaming: true
      )
    end
    
    puts "✓ Large graph (1000 nodes) processed in #{results.real.round(3)}s"
    
    # Memory-efficient batch processing
    batch_export_example(large_graph)
  end

  # Example 2: Custom analysis workflows
  def self.example_2_custom_workflows
    puts "\n🔄 Example 2: Custom Workflows"
    puts "-" * 40
    
    # Multi-step analysis workflow
    workflow_results = perform_custom_workflow
    
    puts "✓ Custom workflow completed:"
    workflow_results.each do |step, result|
      puts "  - #{step}: #{result[:status]} (#{result[:duration].round(3)}s)"
    end
  end

  # Example 3: Batch processing multiple graphs
  def self.example_3_batch_processing
    puts "\n📦 Example 3: Batch Processing"
    puts "-" * 40
    
    # Process multiple graph configurations
    configurations = [
      { name: 'models_only', models: true, controllers: false },
      { name: 'controllers_only', models: false, controllers: true },
      { name: 'full_graph', models: true, controllers: true }
    ]
    
    batch_results = process_batch_configurations(configurations)
    
    puts "✓ Batch processing completed:"
    batch_results.each do |config, metrics|
      puts "  - #{config}: #{metrics[:nodes]} nodes, #{metrics[:edges]} edges"
    end
  end

  # Example 4: Advanced filtering and focus areas
  def self.example_4_filtering_and_focus
    puts "\n🎯 Example 4: Filtering and Focus"
    puts "-" * 40
    
    graph = create_sample_graph
    
    # Focus on specific components
    filtered_outputs = apply_advanced_filtering(graph)
    
    puts "✓ Applied advanced filtering:"
    filtered_outputs.each do |filter_name, output_size|
      puts "  - #{filter_name}: #{output_size} characters"
    end
  end

  # Example 5: Integration patterns
  def self.example_5_integration_patterns
    puts "\n🔗 Example 5: Integration Patterns"
    puts "-" * 40
    
    # CI/CD integration pattern
    ci_integration_example
    
    # Documentation pipeline pattern
    docs_pipeline_example
    
    # Monitoring integration pattern
    monitoring_integration_example
  end

  # Example 6: Custom formatters and extensions
  def self.example_6_custom_formatters
    puts "\n🎨 Example 6: Custom Formatter Patterns"
    puts "-" * 40
    
    graph = create_sample_graph
    
    # Custom format configurations
    custom_formats = {
      detailed_mermaid: {
        format: :mermaid,
        show_attributes: true,
        include_methods: true,
        theme: 'dark'
      },
      api_focused: {
        format: :openapi,
        api_version: '2.0.0',
        include_examples: true,
        security_schemes: ['Bearer', 'API Key']
      },
      interactive_explorer: {
        format: :d3js,
        width: 1400,
        height: 900,
        enable_physics: true,
        color_scheme: 'category20b'
      }
    }
    
    custom_formats.each do |name, config|
      format = config.delete(:format)
      output = RailsFlowMap.export(graph, format: format, **config)
      puts "✓ #{name}: #{output.length} characters"
    end
  end

  # Example 7: Monitoring and logging integration
  def self.example_7_monitoring_and_logging
    puts "\n📊 Example 7: Monitoring and Logging"
    puts "-" * 40
    
    # Setup structured logging
    setup_monitoring_example
    
    # Performance tracking
    track_performance_metrics
    
    # Health checking
    health_check_example
  end

  private

  def self.create_large_sample_graph(size)
    graph = RailsFlowMap::FlowGraph.new
    
    # Create nodes in batches for memory efficiency
    (1..size).each do |i|
      node = RailsFlowMap::FlowNode.new(
        id: "node_#{i}",
        name: "Component#{i}",
        type: [:model, :controller, :service].sample,
        attributes: { index: i }
      )
      graph.add_node(node)
      
      # Add some edges
      if i > 1
        edge = RailsFlowMap::FlowEdge.new(
          from: "node_#{i-1}",
          to: "node_#{i}",
          type: :uses
        )
        graph.add_edge(edge)
      end
    end
    
    graph
  end

  def self.batch_export_example(graph)
    formats = [:mermaid, :erd, :metrics]
    
    # Process formats in parallel (simulated)
    results = formats.map do |format|
      start_time = Time.now
      output = RailsFlowMap.export(graph, format: format)
      duration = Time.now - start_time
      
      { format: format, size: output.length, duration: duration }
    end
    
    puts "✓ Batch export results:"
    results.each do |result|
      puts "  - #{result[:format]}: #{result[:size]} chars in #{result[:duration].round(3)}s"
    end
  end

  def self.perform_custom_workflow
    workflow_steps = {}
    
    # Step 1: Initial analysis
    start_time = Time.now
    graph = create_sample_graph
    workflow_steps['initial_analysis'] = {
      status: 'completed',
      duration: Time.now - start_time
    }
    
    # Step 2: Validation
    start_time = Time.now
    validation_result = validate_graph_quality(graph)
    workflow_steps['validation'] = {
      status: validation_result ? 'passed' : 'failed',
      duration: Time.now - start_time
    }
    
    # Step 3: Multi-format export
    start_time = Time.now
    export_multiple_formats(graph)
    workflow_steps['export'] = {
      status: 'completed',
      duration: Time.now - start_time
    }
    
    # Step 4: Post-processing
    start_time = Time.now
    post_process_outputs
    workflow_steps['post_processing'] = {
      status: 'completed',
      duration: Time.now - start_time
    }
    
    workflow_steps
  end

  def self.process_batch_configurations(configurations)
    results = {}
    
    configurations.each do |config|
      # Simulate analysis with configuration
      graph = create_sample_graph  # In real usage, would use config options
      
      results[config[:name]] = {
        nodes: graph.nodes.size,
        edges: graph.edges.size,
        config: config
      }
    end
    
    results
  end

  def self.apply_advanced_filtering(graph)
    filters = {}
    
    # Filter 1: Focus on models only
    models_only = RailsFlowMap.export(graph, 
      format: :mermaid,
      node_types: [:model],
      max_depth: 2
    )
    filters['models_only'] = models_only.length
    
    # Filter 2: API-focused view
    api_focused = RailsFlowMap.export(graph, 
      format: :openapi,
      include_only: ['users', 'posts'],
      version: '1.0.0'
    )
    filters['api_focused'] = api_focused.length
    
    # Filter 3: High-level overview
    overview = RailsFlowMap.export(graph, 
      format: :mermaid,
      abstraction_level: 'high',
      group_related: true
    )
    filters['overview'] = overview.length
    
    filters
  end

  def self.ci_integration_example
    puts "  🔄 CI/CD Integration:"
    
    # Simulate CI workflow
    steps = [
      "Generate architecture docs",
      "Validate no breaking changes",
      "Update documentation artifacts",
      "Notify team of changes"
    ]
    
    steps.each { |step| puts "    ✓ #{step}" }
  end

  def self.docs_pipeline_example
    puts "  📚 Documentation Pipeline:"
    
    pipeline_steps = [
      "Extract API documentation",
      "Generate interactive diagrams", 
      "Update README architecture section",
      "Deploy to documentation site"
    ]
    
    pipeline_steps.each { |step| puts "    ✓ #{step}" }
  end

  def self.monitoring_integration_example
    puts "  📈 Monitoring Integration:"
    
    monitoring_points = [
      "Track architecture complexity metrics",
      "Monitor documentation freshness",
      "Alert on significant changes",
      "Report usage statistics"
    ]
    
    monitoring_points.each { |point| puts "    ✓ #{point}" }
  end

  def self.setup_monitoring_example
    # Configure logging for performance monitoring
    RailsFlowMap::Logging.configure_for_environment(:production)
    
    puts "✓ Structured logging configured"
    puts "✓ Performance tracking enabled"
    puts "✓ Security monitoring active"
  end

  def self.track_performance_metrics
    # Simulate performance tracking
    metrics = {
      analysis_time: 0.245,
      memory_usage: '45.2MB',
      nodes_processed: 150,
      edges_processed: 89
    }
    
    puts "✓ Performance metrics:"
    metrics.each do |metric, value|
      puts "  - #{metric}: #{value}"
    end
  end

  def self.health_check_example
    # Simulate health checks
    health_checks = {
      'Graph integrity' => 'OK',
      'Output generation' => 'OK', 
      'File permissions' => 'OK',
      'Memory usage' => 'OK'
    }
    
    puts "✓ Health check results:"
    health_checks.each do |check, status|
      puts "  - #{check}: #{status}"
    end
  end

  def self.validate_graph_quality(graph)
    # Basic quality validation
    graph.nodes.size > 0 && graph.edges.size > 0
  end

  def self.export_multiple_formats(graph)
    [:mermaid, :erd, :metrics].each do |format|
      RailsFlowMap.export(graph, format: format)
    end
  end

  def self.post_process_outputs
    # Simulate post-processing steps
    ['Optimize file sizes', 'Generate thumbnails', 'Update indexes'].each do |step|
      # Processing simulation
    end
  end

  def self.create_sample_graph
    graph = RailsFlowMap::FlowGraph.new
    
    # Create a representative sample graph
    nodes = [
      { id: 'user', name: 'User', type: :model },
      { id: 'post', name: 'Post', type: :model },
      { id: 'comment', name: 'Comment', type: :model },
      { id: 'users_controller', name: 'UsersController', type: :controller },
      { id: 'posts_controller', name: 'PostsController', type: :controller }
    ]
    
    nodes.each do |node_data|
      node = RailsFlowMap::FlowNode.new(
        id: node_data[:id],
        name: node_data[:name],
        type: node_data[:type],
        attributes: { sample: true }
      )
      graph.add_node(node)
    end
    
    # Add relationships
    edges = [
      ['post', 'user', :belongs_to],
      ['comment', 'user', :belongs_to],
      ['comment', 'post', :belongs_to],
      ['users_controller', 'user', :uses_model],
      ['posts_controller', 'post', :uses_model]
    ]
    
    edges.each do |from, to, type|
      edge = RailsFlowMap::FlowEdge.new(from: from, to: to, type: type)
      graph.add_edge(edge)
    end
    
    graph
  end
end

# Run examples if this file is executed directly
if __FILE__ == $0
  AdvancedPatternsExamples.run_all
end