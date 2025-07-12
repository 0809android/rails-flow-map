# Rails Flow Map - Quick Reference

Quick reference for the most common Rails Flow Map operations.

## Installation & Setup

```bash
# Add to Gemfile
gem 'rails-flow-map'

# Install
bundle install

# Generate initializer
rails generate rails_flow_map:install
```

## Basic Commands

### Ruby/Rails Console

```ruby
# Basic analysis
graph = RailsFlowMap.analyze
result = RailsFlowMap.export(graph, format: :mermaid)

# Save to file
RailsFlowMap.export(graph, format: :mermaid, output: 'docs/architecture.md')

# Different formats
RailsFlowMap.export(graph, format: :plantuml, output: 'docs/models.puml')
RailsFlowMap.export(graph, format: :d3js, output: 'public/interactive.html')
RailsFlowMap.export(graph, format: :openapi, output: 'docs/api.yaml')
```

### Rake Tasks

```bash
# Generate all formats
rake flow_map:generate

# Specific format
rake flow_map:generate FORMAT=mermaid OUTPUT=docs/flow.md

# Endpoint analysis
rake flow_map:endpoint ENDPOINT=/api/v1/users FORMAT=sequence

# Compare versions
rake flow_map:diff BEFORE=v1.0.0 AFTER=HEAD FORMAT=html
```

## Format Quick Reference

| Format | Use Case | Output |
|--------|----------|---------|
| `:mermaid` | GitHub README, documentation | Markdown with Mermaid diagram |
| `:plantuml` | Detailed UML diagrams | PlantUML code |
| `:d3js` | Interactive exploration | HTML with D3.js visualization |
| `:openapi` | API documentation | YAML OpenAPI specification |
| `:sequence` | Endpoint flow analysis | Mermaid sequence diagram |
| `:erd` | Database schema | Text-based ERD |
| `:metrics` | Code quality analysis | Markdown metrics report |
| `:graphviz` | Network diagrams | DOT file for Graphviz |

## Common Patterns

### GitHub Documentation

```ruby
# For README.md
graph = RailsFlowMap.analyze
mermaid = RailsFlowMap.export(graph, format: :mermaid)

# Add to README.md:
# ```mermaid
# #{mermaid}
# ```
```

### API Documentation

```ruby
# Generate OpenAPI spec
graph = RailsFlowMap.analyze
api_spec = RailsFlowMap.export(graph, 
  format: :openapi,
  api_version: '1.0.0',
  title: 'My API'
)
```

### Endpoint Analysis

```ruby
# Detailed endpoint flow
sequence = RailsFlowMap.export(graph, 
  format: :sequence,
  endpoint: '/api/v1/users',
  include_middleware: true,
  include_callbacks: true
)
```

### Version Comparison

```ruby
# Compare before/after
before = RailsFlowMap.analyze_at('v1.0.0')
after = RailsFlowMap.analyze
diff = RailsFlowMap.diff(before, after, format: :html)
```

## Configuration Quick Setup

```ruby
# config/initializers/rails_flow_map.rb
RailsFlowMap.configure do |config|
  config.output_dir = 'doc/flow_maps'
  config.excluded_paths = ['vendor/', 'tmp/']
  config.include_models = true
  config.include_controllers = true
end
```

## Error Handling

```ruby
begin
  graph = RailsFlowMap.analyze
  result = RailsFlowMap.export(graph, format: :mermaid, output: 'docs/flow.md')
rescue RailsFlowMap::SecurityError => e
  puts "Security error: #{e.message}"
rescue RailsFlowMap::FileOperationError => e
  puts "File error: #{e.message}"
rescue RailsFlowMap::Error => e
  puts "General error: #{e.message}"
end
```

## Performance Tips

```ruby
# For large apps - analyze in parts
models_graph = RailsFlowMap.analyze(models: true, controllers: false)
controllers_graph = RailsFlowMap.analyze(models: false, controllers: true)

# Use caching for repeated operations
RailsFlowMap.configure do |config|
  config.enable_caching = true
  config.cache_ttl = 1.hour
end
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| High memory usage | Use `streaming_mode: true` in config |
| Slow analysis | Add paths to `excluded_paths` |
| Missing relationships | Include all relevant component types |
| Complex diagrams | Use `max_depth` and filtering options |
| Permission errors | Check file/directory permissions |
| Empty output | Verify Rails app structure |

## VS Code Integration

Add to `.vscode/tasks.json`:

```json
{
    "label": "Generate Architecture Docs",
    "type": "shell",
    "command": "bundle exec rake flow_map:generate_all"
}
```

## GitHub Actions

```yaml
- name: Generate docs
  run: bundle exec rake flow_map:generate_all
```

## Useful Snippets

### Generate All Formats

```ruby
def generate_all_docs
  graph = RailsFlowMap.analyze
  
  formats = {
    mermaid: 'docs/architecture.md',
    d3js: 'public/architecture.html',
    openapi: 'docs/api.yaml',
    metrics: 'docs/metrics.md'
  }
  
  formats.each do |format, output|
    RailsFlowMap.export(graph, format: format, output: output)
    puts "Generated #{output}"
  end
end
```

### Team-Specific Views

```ruby
# Backend team
backend_graph = RailsFlowMap.analyze(
  models: true, 
  controllers: true, 
  services: true
)

# Frontend team
api_spec = RailsFlowMap.export(graph, format: :openapi)

# DevOps team
metrics = RailsFlowMap.export(graph, format: :metrics)
```