module RailsFlowMap
  class Engine < ::Rails::Engine
    isolate_namespace RailsFlowMap

    initializer "rails_flow_map.load_tasks" do
      if defined?(Rake)
        load File.expand_path("../../tasks/rails_flow_map.rake", __dir__)
      end
    end

    initializer "rails_flow_map.check_dependencies" do
      begin
        require 'parser/current'
      rescue LoadError
        Rails.logger.warn "Parser gem not found. Some RailsFlowMap features may not work properly."
      end
    end

    generators do
      require "rails_flow_map/generators/install_generator"
    end

    config.before_configuration do
      # Ensure Rails environment is properly loaded
      if Rails.env.development?
        Rails.logger.info "RailsFlowMap engine loaded in development mode"
      end
    end
  end
end