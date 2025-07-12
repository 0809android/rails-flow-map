require_relative "lib/rails_flow_map/version"

Gem::Specification.new do |spec|
  spec.name = "rails-flow-map"
  spec.version = RailsFlowMap::VERSION
  spec.authors = ["Rails Flow Map Team"]
  spec.email = ["team@railsflowmap.com"]

  spec.summary = "Visualize data flows in Rails applications"
  spec.description = "A comprehensive tool for analyzing and visualizing data flows, dependencies, and architecture in Rails applications with multiple output formats."
  spec.homepage = "https://github.com/railsflowmap/rails-flow-map"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.7.0"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir["lib/**/*", "README*.md", "LICENSE*", "CHANGELOG*"]
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Dependencies
  spec.add_dependency "parser", "~> 3.0"
  spec.add_dependency "rails", ">= 6.0"

  # Development dependencies
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "yard", "~> 0.9"
  spec.add_development_dependency "simplecov", "~> 0.21"
end