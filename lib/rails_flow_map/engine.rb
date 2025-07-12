module RailsFlowMap
  class Engine < ::Rails::Engine
    isolate_namespace RailsFlowMap

    initializer "rails_flow_map.load_tasks" do
      if defined?(Rake)
        rake_file = File.expand_path("../../tasks/rails_flow_map.rake", __dir__)
        load rake_file if File.exist?(rake_file)
      end
    end

    generators do
      require "rails_flow_map/generators/install_generator"
    end
  end
end