# RailsFlowMap configuration
#
# This initializer allows you to configure RailsFlowMap behavior
# You can customize the analysis and output options here

RailsFlowMap.configure do |config|
  # Directories to exclude from analysis
  # config.exclude_paths = ['app/models/concerns', 'app/controllers/concerns']
  
  # Model files pattern (default: app/models/**/*.rb)
  # config.model_pattern = 'app/models/**/*.rb'
  
  # Controller files pattern (default: app/controllers/**/*.rb)
  # config.controller_pattern = 'app/controllers/**/*.rb'
  
  # Default output format (mermaid, plantuml, graphviz)
  # config.default_format = :mermaid
  
  # Default output directory
  # config.output_directory = 'doc/flow_maps'
  
  # Include STI (Single Table Inheritance) relationships
  # config.include_sti = true
  
  # Include polymorphic relationships
  # config.include_polymorphic = true
  
  # Custom node colors (for Mermaid format)
  # config.node_colors = {
  #   model: '#f9f',
  #   controller: '#bbf',
  #   action: '#bfb'
  # }
end