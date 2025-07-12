# Rails Flow Map 🚀

[![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)](https://github.com/railsflowmap/rails-flow-map)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Ruby](https://img.shields.io/badge/ruby-%3E%3D%202.7.0-red.svg)](https://www.ruby-lang.org/)
[![Rails](https://img.shields.io/badge/rails-%3E%3D%206.0-red.svg)](https://rubyonrails.org/)

> 🎯 **Comprehensive Rails Application Architecture Visualization Tool**

Rails Flow Map is a powerful gem that analyzes your Rails application structure and generates beautiful, interactive visualizations to help understand architecture, dependencies, and data flow patterns.

**[日本語](README_ja.md) | [中文](README_zh.md)**

---

## ✨ Features

### 🎨 Multiple Visualization Formats
- **🌊 Mermaid Diagrams** - GitHub-friendly markdown diagrams
- **🏗️ PlantUML** - Detailed UML class diagrams  
- **🔗 GraphViz** - Network-style relationship graphs
- **⚡ Interactive D3.js** - Zoomable, draggable web visualizations
- **📊 Metrics Reports** - Code quality and complexity analysis
- **🔄 Sequence Diagrams** - API endpoint flow visualization
- **📋 OpenAPI Specs** - Auto-generated API documentation
- **📈 ERD Diagrams** - Database schema visualization
- **🔍 Git Diff Views** - Architecture change comparisons

### 🛡️ Enterprise-Grade Security
- **Path Traversal Protection** - Prevents malicious file access
- **XSS Prevention** - Sanitizes all HTML outputs
- **Input Validation** - Comprehensive parameter checking
- **Security Event Logging** - Tracks potential threats

### ⚡ Performance & Reliability
- **Structured Logging** - Performance metrics and debugging info
- **Error Handling** - Robust exception management with context
- **Retry Logic** - Automatic recovery from transient failures
- **Memory Optimization** - Efficient processing for large applications

### 🔧 Developer Experience
- **Zero Configuration** - Works out of the box
- **Flexible Integration** - Rake tasks, Ruby API, CI/CD support
- **Comprehensive Documentation** - Examples and best practices
- **VS Code Integration** - Built-in task definitions

---

## 🚀 Quick Start

### Installation

Add to your Gemfile:

```ruby
gem 'rails-flow-map'
```

```bash
bundle install
rails generate rails_flow_map:install
```

### Basic Usage

```ruby
# Generate architecture overview
graph = RailsFlowMap.analyze
RailsFlowMap.export(graph, format: :mermaid, output: 'docs/architecture.md')

# Create interactive visualization
RailsFlowMap.export(graph, format: :d3js, output: 'public/architecture.html')

# Generate API documentation
RailsFlowMap.export(graph, format: :openapi, output: 'docs/api.yaml')
```

### Using Rake Tasks

```bash
# Generate all visualizations
rake flow_map:generate

# Specific format
rake flow_map:generate FORMAT=mermaid OUTPUT=docs/flow.md

# Analyze API endpoint
rake flow_map:endpoint ENDPOINT=/api/v1/users FORMAT=sequence
```

---

## 📊 Visualization Examples

### 🌊 Mermaid Architecture Diagram

```mermaid
graph TD
    User[User] --> Post[Post]
    User --> Comment[Comment]
    Post --> Comment
    UsersController --> User
    PostsController --> Post
    API[/api/v1/users] --> UsersController
```

### ⚡ Interactive D3.js Visualization

*Features: Zoom, drag, filter by component type, search functionality*

### 📋 OpenAPI Documentation

```yaml
openapi: 3.0.0
info:
  title: Rails API Documentation
  version: 1.0.0
paths:
  /api/v1/users:
    get:
      summary: List all users
      responses:
        200:
          description: Successful response
```

---

## 🎯 Use Cases

### 👥 For Development Teams

- **📚 Documentation** - Auto-generate always up-to-date architecture docs
- **🔍 Code Reviews** - Visualize architectural changes in PRs
- **🎓 Onboarding** - Help new team members understand the codebase
- **🏗️ Refactoring** - Identify dependencies before making changes

### 🚀 For DevOps & CI/CD

- **📊 Monitoring** - Track architecture complexity over time
- **🔄 Automation** - Generate docs automatically on deployment
- **📈 Metrics** - Collect code quality and dependency metrics
- **🚨 Alerts** - Detect breaking architectural changes

### 📋 For API Teams

- **📖 API Docs** - Auto-generate OpenAPI specifications
- **🔄 Flow Diagrams** - Visualize request/response flows
- **🧪 Testing** - Understand endpoint dependencies
- **📚 Client SDKs** - Provide clear API structure documentation

---

## 🔧 Configuration

### Basic Configuration

```ruby
# config/initializers/rails_flow_map.rb
RailsFlowMap.configure do |config|
  config.output_directory = 'doc/flow_maps'
  config.exclude_paths = ['vendor/', 'tmp/']
  config.default_format = :mermaid
end
```

### Advanced Configuration

```ruby
RailsFlowMap.configure do |config|
  # Analysis options
  config.include_models = true
  config.include_controllers = true
  config.include_routes = true
  
  # Performance options
  config.streaming_mode = true
  config.memory_limit = 512.megabytes
  
  # Security options
  config.sanitize_output = true
  config.allow_system_paths = false
end
```

---

## 📚 Documentation

### Quick References
- 📖 [**Usage Examples**](USAGE_EXAMPLES.md) - Comprehensive usage guide
- ⚡ [**Quick Reference**](QUICK_REFERENCE.md) - Common commands and patterns
- 🔧 [**API Documentation**](https://rubydoc.info/github/railsflowmap/rails-flow-map) - YARD documentation

### Integration Guides
- 🔄 [**CI/CD Integration**](docs/ci_cd_integration.md) - GitHub Actions, GitLab CI
- 💻 [**VS Code Integration**](doc/vscode_integration.md) - Editor setup and tasks
- 🐳 [**Docker Integration**](docs/docker_integration.md) - Containerized workflows

### Examples
- 🚀 [**Basic Examples**](examples/basic_usage.rb) - Getting started code samples
- 🔬 [**Advanced Patterns**](examples/advanced_patterns.rb) - Complex use cases

---

## 🛠️ Supported Formats

| Format | Description | Best For | Output |
|--------|-------------|----------|---------|
| `mermaid` | GitHub-friendly diagrams | Documentation, README | `.md` |
| `plantuml` | Detailed UML diagrams | Technical documentation | `.puml` |
| `d3js` | Interactive visualizations | Exploration, presentations | `.html` |
| `openapi` | API specifications | API documentation | `.yaml` |
| `sequence` | Request flow diagrams | API analysis | `.md` |
| `erd` | Database schemas | Data modeling | `.md` |
| `metrics` | Code quality reports | Code reviews, monitoring | `.md` |
| `graphviz` | Network diagrams | Complex relationships | `.dot` |

---

## 🔗 Integrations

### GitHub Actions

```yaml
name: Generate Architecture Docs
on: [push]
jobs:
  docs:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: ruby/setup-ruby@v1
      - run: bundle exec rake flow_map:generate_all
```

### VS Code Tasks

```json
{
  "label": "Generate Architecture Docs",
  "type": "shell",
  "command": "bundle exec rake flow_map:generate_all"
}
```

### Pre-commit Hooks

```bash
#!/bin/bash
bundle exec rake flow_map:diff > ARCHITECTURE_CHANGES.md
git add ARCHITECTURE_CHANGES.md
```

---

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

### Development Setup

```bash
git clone https://github.com/railsflowmap/rails-flow-map.git
cd rails-flow-map
bundle install
rake spec
```

### Running Tests

```bash
# Run all tests
bundle exec rspec

# Run specific test
bundle exec rspec spec/rails_flow_map/formatters/mermaid_formatter_spec.rb

# Run with coverage
COVERAGE=true bundle exec rspec
```

---

## 📄 License

Rails Flow Map is released under the [MIT License](LICENSE).

---

## 🙏 Acknowledgments

- Thanks to all [contributors](https://github.com/railsflowmap/rails-flow-map/contributors)
- Inspired by the Rails community's need for better architecture visualization
- Built with ❤️ for the Rails ecosystem

---

## 🔗 Links

- 📖 [Documentation](https://docs.railsflowmap.org)
- 🐛 [Bug Reports](https://github.com/railsflowmap/rails-flow-map/issues)
- 💬 [Discussions](https://github.com/railsflowmap/rails-flow-map/discussions)
- 🐦 [Twitter](https://twitter.com/railsflowmap)

---

<div align="center">

**⭐ Star us on GitHub if Rails Flow Map helps your team! ⭐**

[⬆ Back to top](#rails-flow-map-)

</div>