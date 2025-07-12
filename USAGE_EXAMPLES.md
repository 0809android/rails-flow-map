# Rails Flow Map - Usage Examples

This document provides comprehensive examples of how to use Rails Flow Map effectively in your Rails applications.

## Table of Contents

1. [Basic Usage](#basic-usage)
2. [Advanced Analysis](#advanced-analysis)
3. [Different Output Formats](#different-output-formats)
4. [Workflow Integration](#workflow-integration)
5. [Configuration Options](#configuration-options)
6. [Performance Optimization](#performance-optimization)
7. [Troubleshooting](#troubleshooting)
8. [Best Practices](#best-practices)

## Basic Usage

### Quick Start

```ruby
# 1. Generate a basic flow map of your entire application
graph = RailsFlowMap.analyze
result = RailsFlowMap.export(graph, format: :mermaid, output: 'docs/architecture.md')

# 2. Analyze specific components only
graph = RailsFlowMap.analyze(models: true, controllers: false)
result = RailsFlowMap.export(graph, format: :plantuml, output: 'docs/models.puml')

# 3. Create an interactive visualization
graph = RailsFlowMap.analyze
RailsFlowMap.export(graph, format: :d3js, output: 'public/architecture.html')
```

### Using Rake Tasks

```bash
# Generate all visualizations
rake flow_map:generate

# Generate specific format
rake flow_map:generate FORMAT=mermaid OUTPUT=docs/flow.md

# Analyze specific endpoint
rake flow_map:endpoint ENDPOINT=/api/v1/users FORMAT=sequence
```

## Advanced Analysis

### Endpoint-Specific Analysis

```ruby
# Analyze a specific API endpoint's flow
graph = RailsFlowMap.analyze_endpoint('/api/v1/users')

# Generate sequence diagram for the endpoint
sequence = RailsFlowMap.export(graph, 
  format: :sequence, 
  endpoint: '/api/v1/users',
  include_middleware: true,
  include_callbacks: true,
  include_validations: true
)

puts sequence
```

### Comparing Architecture Changes Between Versions

Visualize how your application's structure has changed between different Git commits, branches, or tags.

**Note**: This is a manual process. You need to run the gem when you want to compare versions.

```ruby
# Example 1: Compare current state with a previous release
before_graph = RailsFlowMap.analyze_at('v1.0.0')  # Analyze structure at v1.0.0 release
after_graph = RailsFlowMap.analyze                # Analyze current code structure

# Generate architecture diff in HTML format (shows additions/deletions/changes with colors)
diff_html = RailsFlowMap.diff(before_graph, after_graph, format: :html)
File.write('docs/architecture_changes.html', diff_html)

# Generate diff in Mermaid format (viewable on GitHub/GitLab)
diff_md = RailsFlowMap.diff(before_graph, after_graph, format: :mermaid)
File.write('docs/architecture_diff.md', diff_md)
```

#### Practical Examples

```ruby
# During PR review: Check how a feature branch affects architecture
before = RailsFlowMap.analyze_at('main')
after = RailsFlowMap.analyze_at('feature/new-api')
diff = RailsFlowMap.diff(before, after, format: :mermaid)

# Before/after refactoring comparison
before = RailsFlowMap.analyze_at('HEAD~1')  # 1 commit ago
after = RailsFlowMap.analyze                # Current state
```

### Custom Configuration

```ruby
# Configure Rails Flow Map for your project
RailsFlowMap.configure do |config|
  config.include_models = true
  config.include_controllers = true
  config.include_routes = true
  config.include_services = true
  config.output_dir = 'doc/flow_maps'
  config.excluded_paths = ['tmp/', 'vendor/', 'spec/']
end

# Use configured settings
graph = RailsFlowMap.analyze
```

## Different Output Formats

### 1. Mermaid Diagrams (GitHub-friendly)

```ruby
graph = RailsFlowMap.analyze

# Basic Mermaid diagram
mermaid = RailsFlowMap.export(graph, format: :mermaid)

# With custom styling options
mermaid = RailsFlowMap.export(graph, 
  format: :mermaid,
  theme: 'dark',
  show_attributes: true,
  max_depth: 3
)

File.write('README_architecture.md', <<~MARKDOWN)
  # Application Architecture

  ```mermaid
  #{mermaid}
  ```
MARKDOWN
```

### 2. PlantUML Diagrams

```ruby
# Generate PlantUML for detailed documentation
plantuml = RailsFlowMap.export(graph, 
  format: :plantuml,
  include_methods: true,
  show_associations: true
)

File.write('docs/detailed_models.puml', plantuml)

# Use with PlantUML server or local installation
# plantuml -tpng docs/detailed_models.puml
```

### 3. Interactive D3.js Visualization

```ruby
# Create interactive HTML with filtering and zoom
html = RailsFlowMap.export(graph, 
  format: :d3js,
  width: 1200,
  height: 800,
  enable_zoom: true,
  enable_drag: true,
  show_legend: true,
  color_scheme: 'category20'
)

File.write('public/architecture_interactive.html', html)
```

### 4. API Documentation (OpenAPI)

```ruby
# Generate OpenAPI specification from your routes
api_spec = RailsFlowMap.export(graph, 
  format: :openapi,
  api_version: '1.0.0',
  title: 'My API Documentation',
  description: 'Auto-generated API documentation from Rails Flow Map'
)

File.write('docs/api_spec.yaml', api_spec)

# Use with Swagger UI or other OpenAPI tools
```

### 5. Sequence Diagrams for Endpoints

```ruby
# Detailed sequence diagram for a specific endpoint
sequence = RailsFlowMap.export(graph, 
  format: :sequence,
  endpoint: '/api/v1/posts',
  include_middleware: true,
  include_callbacks: true,
  include_validations: true,
  include_database: true
)

File.write('docs/post_creation_flow.md', <<~MARKDOWN)
  # Post Creation Flow

  #{sequence}
MARKDOWN
```

### 6. Metrics and Analysis

```ruby
# Generate comprehensive metrics report
metrics = RailsFlowMap.export(graph, 
  format: :metrics,
  include_complexity: true,
  include_coupling: true,
  include_recommendations: true
)

File.write('docs/architecture_metrics.md', metrics)
```

## Workflow Integration

### GitHub Actions Integration

Create `.github/workflows/architecture_docs.yml`:

```yaml
name: Generate Architecture Documentation

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  generate-docs:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Set up Ruby
      uses: ruby/setup-ruby@v1
      with:
        ruby-version: 3.1
        bundler-cache: true
    
    - name: Generate architecture documentation
      run: |
        bundle exec rake flow_map:generate_all
        
    - name: Check for changes
      run: |
        if [ -n "$(git status --porcelain docs/)" ]; then
          echo "Architecture documentation has changes"
          echo "::set-output name=changes::true"
        fi
      id: check_changes
    
    - name: Commit changes
      if: steps.check_changes.outputs.changes == 'true'
      run: |
        git config --local user.email "action@github.com"
        git config --local user.name "GitHub Action"
        git add docs/
        git commit -m "📊 Update architecture documentation [skip ci]"
        git push
```

### Pre-commit Hook

Create `.git/hooks/pre-commit`:

```bash
#!/bin/bash

# Generate architecture diff for review
if [ -f "Gemfile" ] && bundle exec rake flow_map:diff > /dev/null 2>&1; then
    echo "✅ Architecture diff generated for review"
else
    echo "⚠️  Could not generate architecture diff"
fi
```

### VS Code Integration

Add to `.vscode/tasks.json`:

```json
{
    "version": "2.0.0",
    "tasks": [
        {
            "label": "Generate Architecture Docs",
            "type": "shell",
            "command": "bundle exec rake flow_map:generate_all",
            "group": "build",
            "presentation": {
                "echo": true,
                "reveal": "always",
                "focus": false,
                "panel": "shared"
            }
        },
        {
            "label": "Analyze Endpoint",
            "type": "shell",
            "command": "bundle exec rake flow_map:endpoint",
            "args": ["ENDPOINT=${input:endpoint}"],
            "group": "build",
            "presentation": {
                "echo": true,
                "reveal": "always",
                "focus": false,
                "panel": "shared"
            }
        }
    ],
    "inputs": [
        {
            "id": "endpoint",
            "description": "Enter the endpoint path",
            "default": "/api/v1/users",
            "type": "promptString"
        }
    ]
}
```

## Configuration Options

### Global Configuration

```ruby
# config/initializers/rails_flow_map.rb
RailsFlowMap.configure do |config|
  # Analysis options
  config.include_models = true
  config.include_controllers = true
  config.include_routes = true
  config.include_services = true
  config.include_jobs = true
  config.include_mailers = true
  
  # Output options
  config.output_dir = Rails.root.join('doc', 'flow_maps')
  config.auto_generate = Rails.env.development?
  
  # Exclusions
  config.excluded_paths = [
    'tmp/',
    'vendor/',
    'spec/',
    'test/',
    'node_modules/'
  ]
  
  # Performance
  config.max_file_size = 1.megabyte
  config.analysis_timeout = 30.seconds
  
  # Security
  config.allow_system_paths = false
  config.sanitize_output = true
end
```

### Environment-Specific Settings

```ruby
# Different settings per environment
case Rails.env
when 'development'
  RailsFlowMap.configure do |config|
    config.output_dir = 'tmp/flow_maps'
    config.auto_generate = true
    config.log_level = :debug
  end
when 'production'
  RailsFlowMap.configure do |config|
    config.output_dir = 'public/docs'
    config.auto_generate = false
    config.log_level = :warn
  end
end
```

## Performance Optimization

### Large Applications

```ruby
# For large applications, analyze incrementally
def generate_architecture_docs
  # 1. Analyze core models first
  models_graph = RailsFlowMap.analyze(
    models: true, 
    controllers: false, 
    routes: false
  )
  RailsFlowMap.export(models_graph, 
    format: :mermaid, 
    output: 'docs/models_overview.md'
  )
  
  # 2. Analyze API controllers separately
  api_graph = RailsFlowMap.analyze_controllers(
    pattern: 'app/controllers/api/**/*_controller.rb'
  )
  RailsFlowMap.export(api_graph, 
    format: :openapi, 
    output: 'docs/api_spec.yaml'
  )
  
  # 3. Generate metrics report
  full_graph = RailsFlowMap.analyze
  RailsFlowMap.export(full_graph, 
    format: :metrics, 
    output: 'docs/metrics.md'
  )
end
```

### Caching Results

```ruby
# Cache analysis results
class ArchitectureDocGenerator
  def self.generate_with_cache
    cache_key = "architecture_#{last_modified_time}"
    
    Rails.cache.fetch(cache_key, expires_in: 1.hour) do
      graph = RailsFlowMap.analyze
      {
        mermaid: RailsFlowMap.export(graph, format: :mermaid),
        metrics: RailsFlowMap.export(graph, format: :metrics),
        generated_at: Time.current
      }
    end
  end
  
  private
  
  def self.last_modified_time
    Dir.glob('app/**/*.rb').map { |f| File.mtime(f) }.max.to_i
  end
end
```

## Troubleshooting

### Common Issues and Solutions

#### 1. Memory Usage with Large Applications

```ruby
# Problem: High memory usage
# Solution: Use streaming or incremental analysis

RailsFlowMap.configure do |config|
  config.streaming_mode = true
  config.batch_size = 100
  config.memory_limit = 512.megabytes
end

# Or analyze in chunks
%w[models controllers services].each do |component|
  graph = RailsFlowMap.analyze(component.to_sym => true)
  RailsFlowMap.export(graph, 
    format: :mermaid, 
    output: "docs/#{component}.md"
  )
end
```

#### 2. Slow Analysis Performance

```ruby
# Problem: Slow analysis
# Solution: Exclude unnecessary files and use caching

RailsFlowMap.configure do |config|
  config.excluded_paths += [
    'lib/assets/',
    'vendor/assets/',
    'app/assets/',
    'db/migrate/'
  ]
  
  config.enable_caching = true
  config.cache_ttl = 1.hour
end
```

#### 3. Missing Dependencies

```ruby
# Problem: Missing associations or relationships
# Solution: Ensure all relevant files are included

graph = RailsFlowMap.analyze(
  models: true,
  controllers: true,
  routes: true,
  services: true,
  jobs: true,
  mailers: true
)

# Check for missing relationships
puts "Nodes: #{graph.nodes.count}"
puts "Edges: #{graph.edges.count}"
```

#### 4. Output Format Issues

```ruby
# Problem: Generated diagrams are too complex
# Solution: Use filtering and depth limits

RailsFlowMap.export(graph, 
  format: :mermaid,
  max_depth: 2,
  exclude_types: [:job, :mailer],
  focus_on: ['User', 'Post', 'Comment']
)
```

## Best Practices

### 1. Documentation Workflow

```ruby
# Create a comprehensive documentation generation script
class DocumentationGenerator
  def self.run
    puts "Generating architecture documentation..."
    
    # 1. Full application overview
    generate_overview
    
    # 2. API documentation
    generate_api_docs
    
    # 3. Database schema visualization
    generate_schema_docs
    
    # 4. Metrics and analysis
    generate_metrics
    
    puts "Documentation generated successfully!"
  end
  
  private
  
  def self.generate_overview
    graph = RailsFlowMap.analyze
    
    # Mermaid for GitHub README
    mermaid = RailsFlowMap.export(graph, format: :mermaid)
    update_readme_with_architecture(mermaid)
    
    # Interactive HTML for detailed exploration
    html = RailsFlowMap.export(graph, 
      format: :d3js, 
      output: 'docs/architecture_interactive.html'
    )
  end
  
  def self.generate_api_docs
    graph = RailsFlowMap.analyze
    api_spec = RailsFlowMap.export(graph, 
      format: :openapi, 
      output: 'docs/api_specification.yaml'
    )
  end
  
  def self.generate_schema_docs
    graph = RailsFlowMap.analyze(models: true, controllers: false)
    erd = RailsFlowMap.export(graph, 
      format: :erd, 
      output: 'docs/database_schema.md'
    )
  end
  
  def self.generate_metrics
    graph = RailsFlowMap.analyze
    metrics = RailsFlowMap.export(graph, 
      format: :metrics, 
      output: 'docs/architecture_metrics.md'
    )
  end
end
```

### 2. Team Collaboration

```ruby
# Create team-specific views
module TeamDocumentation
  def self.generate_backend_docs
    graph = RailsFlowMap.analyze(
      models: true, 
      controllers: true, 
      services: true
    )
    
    RailsFlowMap.export(graph, 
      format: :sequence, 
      output: 'docs/backend_flows.md',
      include_database: true
    )
  end
  
  def self.generate_frontend_docs
    graph = RailsFlowMap.analyze(controllers: true, routes: true)
    
    RailsFlowMap.export(graph, 
      format: :openapi, 
      output: 'docs/frontend_api.yaml'
    )
  end
  
  def self.generate_devops_docs
    graph = RailsFlowMap.analyze
    
    RailsFlowMap.export(graph, 
      format: :metrics, 
      output: 'docs/deployment_metrics.md',
      include_performance: true
    )
  end
end
```

### 3. Code Review Integration

```ruby
# Generate diffs for code reviews
class CodeReviewHelper
  def self.generate_architecture_diff(base_branch = 'main')
    # Save current state
    after_graph = RailsFlowMap.analyze
    
    # Checkout base branch and analyze
    system("git stash")
    system("git checkout #{base_branch}")
    before_graph = RailsFlowMap.analyze
    system("git checkout -")
    system("git stash pop")
    
    # Generate diff
    diff = RailsFlowMap.diff(before_graph, after_graph, format: :mermaid)
    
    File.write('ARCHITECTURE_CHANGES.md', <<~MARKDOWN)
      # Architecture Changes
      
      This document shows the architectural changes in this PR.
      
      #{diff}
      
      ## Summary
      
      - **Added**: #{(after_graph.nodes.keys - before_graph.nodes.keys).count} components
      - **Modified**: #{detect_modifications(before_graph, after_graph).count} components
      - **Removed**: #{(before_graph.nodes.keys - after_graph.nodes.keys).count} components
    MARKDOWN
  end
end
```

### 4. Continuous Documentation

```ruby
# Add to your deployment script
namespace :deploy do
  desc "Update architecture documentation"
  task :update_docs do
    puts "Updating architecture documentation..."
    
    graph = RailsFlowMap.analyze
    
    # Update public documentation
    RailsFlowMap.export(graph, 
      format: :d3js, 
      output: Rails.root.join('public', 'architecture.html')
    )
    
    # Update API docs
    RailsFlowMap.export(graph, 
      format: :openapi, 
      output: Rails.root.join('public', 'api_docs.yaml')
    )
    
    puts "Documentation updated successfully!"
  end
end

# Add to your Capistrano deploy.rb
after 'deploy:migrate', 'deploy:update_docs'
```

---

This comprehensive guide should help you get the most out of Rails Flow Map in your development workflow. For more advanced usage and customization options, refer to the API documentation and source code.