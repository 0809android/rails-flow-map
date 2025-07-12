module RailsFlowMap
  class Configuration
    attr_accessor :exclude_paths, :model_pattern, :controller_pattern,
                  :default_format, :output_directory, :include_sti,
                  :include_polymorphic, :node_colors

    def initialize
      @exclude_paths = []
      @model_pattern = 'app/models/**/*.rb'
      @controller_pattern = 'app/controllers/**/*.rb'
      @default_format = :mermaid
      @output_directory = 'doc/flow_maps'
      @include_sti = true
      @include_polymorphic = true
      @node_colors = {
        model: '#f9f',
        controller: '#bbf',
        action: '#bfb'
      }
    end
  end
end