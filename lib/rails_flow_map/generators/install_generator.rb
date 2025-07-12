require 'rails/generators/base'

module RailsFlowMap
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path('templates', __dir__)
      
      desc "Creates a RailsFlowMap initializer"
      
      def create_initializer_file
        template "rails_flow_map.rb", "config/initializers/rails_flow_map.rb"
      end
      
      def create_output_directory
        empty_directory "doc/flow_maps"
        create_file "doc/flow_maps/.gitkeep"
      end
      
      def display_post_install_message
        say "\nRailsFlowMap has been successfully installed!", :green
        say "\nAvailable rake tasks:"
        say "  rake rails_flow_map:generate       # Generate complete flow map"
        say "  rake rails_flow_map:models         # Generate model relationships"
        say "  rake rails_flow_map:controllers    # Generate controller/action flow"
        say "  rake rails_flow_map:formats        # List available formats"
        say "\nExample usage:"
        say "  rake rails_flow_map:generate[mermaid,doc/flow_maps/app_flow.md]"
        say "\nFlow maps will be saved in doc/flow_maps/ by default."
      end
    end
  end
end