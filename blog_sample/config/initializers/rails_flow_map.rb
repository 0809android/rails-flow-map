# RailsFlowMap Configuration
RailsFlowMap.configure do |config|
  # Include models in analysis (default: true)
  config.include_models = true
  
  # Include controllers in analysis (default: true)  
  config.include_controllers = true
  
  # Include routes in analysis (default: true)
  config.include_routes = true
  
  # Output directory for generated diagrams
  config.output_dir = 'doc/flow_maps'
  
  # Default export format (:mermaid, :plantuml, :graphviz)
  config.default_format = :mermaid
  
  # Model directories to analyze
  config.model_paths = ['app/models']
  
  # Controller directories to analyze  
  config.controller_paths = ['app/controllers']
end