require 'ostruct'
require 'pathname'

# Mock Rails environment for testing RailsFlowMap without full Rails setup
module Rails
  def self.root
    Pathname.new(File.expand_path('..', __dir__))
  end
  
  def self.application
    @application ||= MockApplication.new
  end
  
  def self.logger
    @logger ||= MockLogger.new
  end
  
  def self.env
    OpenStruct.new(development?: true)
  end
  
  class MockApplication
    def routes
      @routes ||= MockRoutes.new
    end
  end
  
  class MockRoutes
    def routes
      [
        MockRoute.new('GET', '/api/v1/users', 'api/v1/users', 'index'),
        MockRoute.new('POST', '/api/v1/users', 'api/v1/users', 'create'),
        MockRoute.new('GET', '/api/v1/users/:id', 'api/v1/users', 'show'),
        MockRoute.new('PUT', '/api/v1/users/:id', 'api/v1/users', 'update'),
        MockRoute.new('DELETE', '/api/v1/users/:id', 'api/v1/users', 'destroy'),
        MockRoute.new('POST', '/api/v1/users/:id/follow', 'api/v1/users', 'follow'),
        MockRoute.new('DELETE', '/api/v1/users/:id/unfollow', 'api/v1/users', 'unfollow'),
        MockRoute.new('GET', '/api/v1/posts', 'api/v1/posts', 'index'),
        MockRoute.new('POST', '/api/v1/posts', 'api/v1/posts', 'create'),
        MockRoute.new('GET', '/api/v1/posts/:id', 'api/v1/posts', 'show'),
        MockRoute.new('PUT', '/api/v1/posts/:id', 'api/v1/posts', 'update'),
        MockRoute.new('DELETE', '/api/v1/posts/:id', 'api/v1/posts', 'destroy'),
        MockRoute.new('GET', '/api/v1/posts/:post_id/comments', 'api/v1/comments', 'index'),
        MockRoute.new('POST', '/api/v1/posts/:post_id/comments', 'api/v1/comments', 'create'),
        MockRoute.new('GET', '/api/v1/analytics/users', 'api/v1/analytics', 'users'),
        MockRoute.new('GET', '/api/v1/analytics/posts', 'api/v1/analytics', 'posts'),
        MockRoute.new('GET', '/health', 'application', 'health')
      ]
    end
  end
  
  class MockRoute
    attr_reader :verb, :path, :controller, :action
    
    def initialize(verb, path, controller, action)
      @verb = verb
      @path = OpenStruct.new(spec: OpenStruct.new(to_s: path))
      @controller = controller
      @action = action
    end
    
    def defaults
      {
        controller: @controller,
        action: @action
      }
    end
    
    def requirements
      {}
    end
  end
  
  class MockLogger
    def info(message)
      puts "[INFO] #{message}"
    end
    
    def warn(message)
      puts "[WARN] #{message}"
    end
    
    def error(message)
      puts "[ERROR] #{message}"
    end
  end
end

# Load Rails-like classes
class ActiveRecord
  class Base
    def self.abstract_class=(val)
      # Mock implementation
    end
  end
end

class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
end

class ActionController
  class API
  end
end

# Mock Rails::Engine
module Rails
  class Engine
    def self.isolate_namespace(namespace)
      # Mock implementation
    end
    
    def self.initializer(name, &block)
      # Mock implementation - execute immediately for testing
      block.call if block_given?
    end
    
    def self.generators(&block)
      # Mock implementation
    end
    
    def self.config
      @config ||= OpenStruct.new(
        before_configuration: ->(block) { block.call if block_given? }
      )
    end
  end
end

module Rake
  # Mock Rake for testing
end