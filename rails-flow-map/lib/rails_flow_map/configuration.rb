module RailsFlowMap
  class Configuration
    attr_accessor :exclude_paths, :model_pattern, :controller_pattern,
                  :default_format, :output_directory, :include_sti,
                  :include_polymorphic, :node_colors, :max_depth,
                  :enable_request_flow_analysis, :enable_route_analysis

    def initialize
      @exclude_paths = []
      @model_pattern = 'app/models/**/*.rb'
      @controller_pattern = 'app/controllers/**/*.rb'
      @default_format = :mermaid
      @output_directory = 'doc/flow_maps'
      @include_sti = true
      @include_polymorphic = true
      @max_depth = 5
      @enable_request_flow_analysis = true
      @enable_route_analysis = true
      @node_colors = {
        model: '#f9f',
        controller: '#bbf',
        action: '#bfb',
        route: '#FFE4E1',
        service: '#FFF3E0',
        response: '#F1F8E9'
      }
    end

    def validate!
      raise ArgumentError, "max_depth must be positive" if max_depth <= 0
      raise ArgumentError, "output_directory cannot be empty" if output_directory.empty?
      raise ArgumentError, "unsupported default_format" unless valid_format?(default_format)
    end

    private

    def valid_format?(format)
      [:mermaid, :plantuml, :graphviz, :sequence, :request_flow, :api_docs].include?(format)
    end
  end
end