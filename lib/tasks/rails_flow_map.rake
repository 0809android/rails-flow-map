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
    graph = RailsFlowMap.analyze(controllers: false)
    
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
    graph = RailsFlowMap.analyze(models: false)
    
    puts "Found #{graph.nodes.size} controllers/actions"
    
    result = RailsFlowMap.export(graph, format: format, output: output)
    
    if output
      puts "Controller flow map saved to: #{output}"
    else
      puts "\n#{result}"
    end
  end

  desc "List all available formats"
  task :formats do
    puts "Available output formats:"
    puts "  - mermaid    : Mermaid diagram format (default)"
    puts "  - plantuml   : PlantUML diagram format"
    puts "  - graphviz   : GraphViz DOT format"
    puts "\nExample usage:"
    puts "  rake rails_flow_map:generate[mermaid,flow.md]"
    puts "  rake rails_flow_map:models[plantuml,models.puml]"
    puts "  rake rails_flow_map:controllers[graphviz,controllers.dot]"
  end
end