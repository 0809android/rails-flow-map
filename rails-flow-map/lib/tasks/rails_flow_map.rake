namespace :rails_flow_map do
  desc "Generate a flow map of your Rails application"
  task :generate, [:format, :output] => :environment do |t, args|
    format = (args[:format] || 'mermaid').to_sym
    output = args[:output]
    
    puts "Analyzing Rails application..."
    graph = RailsFlowMap.analyze
    
    puts "Found #{graph.nodes.size} nodes and #{graph.edges.size} relationships"
    
    result = RailsFlowMap.export(graph, format: format, output: output)
    
    if output
      puts "Flow map saved to: #{output}"
    else
      puts "\n#{result}"
    end
  end

  desc "Generate flow map for models only"
  task :models, [:format, :output] => :environment do |t, args|
    format = (args[:format] || 'mermaid').to_sym
    output = args[:output]
    
    puts "Analyzing Rails models..."
    graph = RailsFlowMap.analyze(controllers: false, routes: false, request_flow: false)
    
    puts "Found #{graph.nodes.size} models and #{graph.edges.size} relationships"
    
    result = RailsFlowMap.export(graph, format: format, output: output)
    
    if output
      puts "Model flow map saved to: #{output}"
    else
      puts "\n#{result}"
    end
  end

  desc "Generate flow map for controllers only"
  task :controllers, [:format, :output] => :environment do |t, args|
    format = (args[:format] || 'mermaid').to_sym
    output = args[:output]
    
    puts "Analyzing Rails controllers..."
    graph = RailsFlowMap.analyze(models: false, routes: false, request_flow: false)
    
    puts "Found #{graph.nodes.size} controllers/actions"
    
    result = RailsFlowMap.export(graph, format: format, output: output)
    
    if output
      puts "Controller flow map saved to: #{output}"
    else
      puts "\n#{result}"
    end
  end

  desc "Generate request flow for a specific endpoint"
  task :endpoint, [:endpoint, :format, :output] => :environment do |t, args|
    endpoint = args[:endpoint]
    format = (args[:format] || 'sequence').to_sym
    output = args[:output]
    
    unless endpoint
      puts "Error: Please specify an endpoint"
      puts "Usage: rake rails_flow_map:endpoint['/api/users',sequence,endpoint_flow.md]"
      exit 1
    end
    
    puts "Analyzing request flow for endpoint: #{endpoint}"
    graph = RailsFlowMap.analyze_endpoint(endpoint)
    
    puts "Found #{graph.nodes.size} nodes and #{graph.edges.size} relationships"
    
    result = RailsFlowMap.export(graph, format: format, output: output, endpoint: endpoint)
    
    if output
      puts "Endpoint flow saved to: #{output}"
    else
      puts "\n#{result}"
    end
  end

  desc "Generate sequence diagram for all endpoints"
  task :sequence, [:output] => :environment do |t, args|
    output = args[:output]
    
    puts "Generating sequence diagrams for all endpoints..."
    graph = RailsFlowMap.analyze
    
    result = RailsFlowMap.export(graph, format: :sequence, output: output)
    
    if output
      puts "Sequence diagram saved to: #{output}"
    else
      puts "\n#{result}"
    end
  end

  desc "Generate complete request flow diagram"
  task :request_flow, [:output] => :environment do |t, args|
    output = args[:output]
    
    puts "Generating complete request flow diagram..."
    graph = RailsFlowMap.analyze
    
    result = RailsFlowMap.export(graph, format: :request_flow, output: output)
    
    if output
      puts "Request flow diagram saved to: #{output}"
    else
      puts "\n#{result}"
    end
  end

  desc "Generate API documentation with flow diagrams"
  task :api_docs, [:output] => :environment do |t, args|
    output = args[:output] || 'doc/flow_maps/api_documentation.md'
    
    puts "Generating API documentation with flow diagrams..."
    graph = RailsFlowMap.analyze
    
    result = RailsFlowMap.export(graph, format: :api_docs, output: output)
    
    puts "API documentation saved to: #{output}"
  end

  desc "List all available formats"
  task :formats do
    puts "Available output formats:"
    puts "  - mermaid      : Mermaid diagram format (default)"
    puts "  - plantuml     : PlantUML diagram format"
    puts "  - graphviz     : GraphViz DOT format"
    puts "  - sequence     : Mermaid sequence diagram"
    puts "  - request_flow : Complete request flow diagram"
    puts "  - api_docs     : Complete API documentation with flow diagrams"
    puts "\nExample usage:"
    puts "  rake rails_flow_map:generate[mermaid,flow.md]"
    puts "  rake rails_flow_map:endpoint['/api/users',sequence,user_flow.md]"
    puts "  rake rails_flow_map:sequence[all_sequences.md]"
    puts "  rake rails_flow_map:request_flow[request_flow.md]"
    puts "  rake rails_flow_map:api_docs[doc/api_docs.md]"
  end
end