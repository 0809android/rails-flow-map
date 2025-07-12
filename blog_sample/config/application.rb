require_relative "boot"

require "rails/all"

Bundler.require(*Rails.groups)

module BlogSample
  class Application < Rails::Application
    config.load_defaults 6.1
    config.api_only = true
    
    # For RailsFlowMap
    config.autoload_paths << Rails.root.join('lib')
  end
end