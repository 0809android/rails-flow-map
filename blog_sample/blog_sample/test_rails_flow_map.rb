#!/usr/bin/env ruby

# Load mock Rails environment
require_relative 'lib/mock_rails'

# Load RailsFlowMap
$LOAD_PATH.unshift(File.expand_path('../../lib', __dir__))
require 'rails_flow_map'

puts "🚀 Testing RailsFlowMap with Blog Sample Project"
puts "=" * 60

begin
  # Initialize configuration
  require_relative 'config/initializers/rails_flow_map'
  
  puts "\n1. Configuration loaded successfully ✓"
  
  # Test basic analysis
  puts "\n2. Running basic analysis..."
  graph = RailsFlowMap.analyze
  
  puts "   - Found #{graph.node_count} nodes"
  puts "   - Found #{graph.edge_count} edges"
  puts "   - Models: #{graph.nodes_by_type(:model).count}"
  puts "   - Controllers: #{graph.nodes_by_type(:controller).count}"
  puts "   - Actions: #{graph.nodes_by_type(:action).count}"
  puts "   - Routes: #{graph.nodes_by_type(:route).count}"
  puts "   - Services: #{graph.nodes_by_type(:service).count}"
  
  # Create output directory
  require 'fileutils'
  FileUtils.mkdir_p('doc/flow_maps')
  
  # Test different formats
  puts "\n3. Testing export formats..."
  
  formats = [
    { format: :mermaid, file: 'doc/flow_maps/complete_flow.md', desc: 'Complete flow diagram' },
    { format: :sequence, file: 'doc/flow_maps/sequences.md', desc: 'Sequence diagrams' },
    { format: :plantuml, file: 'doc/flow_maps/models.puml', desc: 'PlantUML diagram' },
    { format: :graphviz, file: 'doc/flow_maps/graph.dot', desc: 'GraphViz diagram' },
    { format: :api_docs, file: 'doc/flow_maps/api_documentation.md', desc: 'API documentation' }
  ]
  
  formats.each do |format_config|
    puts "   - Generating #{format_config[:desc]}..."
    result = RailsFlowMap.export(graph, format: format_config[:format], output: format_config[:file])
    puts "     ✓ Saved to #{format_config[:file]}"
  end
  
  # Test endpoint-specific analysis
  puts "\n4. Testing endpoint-specific analysis..."
  endpoints = ['/api/v1/users', '/api/v1/posts', '/api/v1/analytics/users']
  
  endpoints.each do |endpoint|
    puts "   - Analyzing endpoint: #{endpoint}"
    endpoint_graph = RailsFlowMap.analyze_endpoint(endpoint)
    
    sequence_output = RailsFlowMap.export(
      endpoint_graph, 
      format: :sequence, 
      endpoint: endpoint,
      output: "doc/flow_maps/endpoint_#{endpoint.gsub('/', '_').gsub(':', '')}_sequence.md"
    )
    
    puts "     ✓ Generated sequence diagram (#{endpoint_graph.node_count} nodes, #{endpoint_graph.edge_count} edges)"
  end
  
  puts "\n5. Sample output preview:"
  puts "-" * 40
  
  # Show a sample of the generated content
  sample_output = RailsFlowMap.export(graph, format: :mermaid)
  puts sample_output.split("\n").first(15).join("\n")
  puts "... (truncated, see full output in doc/flow_maps/)"
  
  puts "\n" + "=" * 60
  puts "✅ RailsFlowMap test completed successfully!"
  puts "\nGenerated files:"
  Dir.glob('doc/flow_maps/*').each do |file|
    size = File.size(file)
    puts "   - #{file} (#{size} bytes)"
  end
  
  puts "\n💡 Next steps:"
  puts "   1. Open the generated files to view the diagrams"
  puts "   2. Copy the Mermaid code to visualize in GitHub/GitLab"
  puts "   3. Use PlantUML files with PlantUML tools"
  puts "   4. Open GraphViz files with Graphviz"
  
rescue => e
  puts "\n❌ Error occurred during testing:"
  puts "   #{e.message}"
  puts "\nBacktrace:"
  puts e.backtrace.first(10).map { |line| "   #{line}" }
end