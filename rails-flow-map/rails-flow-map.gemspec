# frozen_string_literal: true

require_relative "lib/rails_flow_map/version"

Gem::Specification.new do |spec|
  spec.name = "rails-flow-map"
  spec.version = RailsFlowMap::VERSION
  spec.authors = ["asakura"]
  spec.email = ["0809android@gmail.com"]

  spec.summary = "Rails Data Flow Visualization Tool"
  spec.description = "A Rails gem that visualizes data flow between models and generates documentation in various formats including Mermaid, PlantUML, and GraphViz."
  spec.homepage = "https://github.com/asakura/rails-flow-map"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/asakura/rails-flow-map"
  spec.metadata["changelog_uri"] = "https://github.com/asakura/rails-flow-map/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Rails dependency
  spec.add_dependency "rails", ">= 6.0"
  
  # For parsing and analyzing Rails applications
  spec.add_dependency "parser", "~> 3.0"
  
  # Development dependencies
  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rubocop", "~> 1.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
