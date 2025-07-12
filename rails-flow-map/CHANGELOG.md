# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2024-07-12

### Added
- Initial release of RailsFlowMap
- Model relationship analysis using AST parsing
- Controller and action structure analysis
- Multiple output formats support:
  - Mermaid diagram format
  - PlantUML diagram format
  - GraphViz DOT format
- Rails engine integration with rake tasks:
  - `rails_flow_map:generate` - Generate complete flow map
  - `rails_flow_map:models` - Generate model relationships only
  - `rails_flow_map:controllers` - Generate controller structure only
  - `rails_flow_map:formats` - List available formats
- Configuration system with initializer support
- Install generator (`rails g rails_flow_map:install`)
- Comprehensive test suite with RSpec
- Support for Rails 6.0+
- Documentation and usage examples

### Features
- Automatic detection of ActiveRecord associations:
  - belongs_to
  - has_one
  - has_many
  - has_and_belongs_to_many
- Controller action mapping
- Configurable exclude paths
- File output support
- Color-coded node types in diagrams
- Error handling for malformed Ruby files

[Unreleased]: https://github.com/asakura/rails-flow-map/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/asakura/rails-flow-map/releases/tag/v0.1.0