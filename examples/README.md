# Rails Flow Map Examples

This directory contains practical examples and usage patterns for Rails Flow Map.

## Files Overview

- **`basic_usage.rb`** - Essential usage patterns and common operations
- **`advanced_patterns.rb`** - Complex workflows, performance optimization, and integration patterns

## Running Examples

### Basic Usage Examples

```bash
cd rails-flow-map
ruby examples/basic_usage.rb
```

This will demonstrate:
- Basic graph analysis and export
- Multiple output formats
- File output operations
- Configuration usage
- Error handling patterns

### Advanced Patterns Examples

```bash
ruby examples/advanced_patterns.rb
```

This covers:
- Performance optimization for large applications
- Custom analysis workflows
- Batch processing multiple graphs
- Advanced filtering and focus areas
- Integration patterns (CI/CD, documentation, monitoring)
- Custom formatter configurations
- Monitoring and logging integration

## Example Categories

### 🚀 Getting Started
- Basic analysis: `RailsFlowMap.analyze`
- Simple exports: `RailsFlowMap.export(graph, format: :mermaid)`
- File operations: Save to specific locations
- Error handling: Catch and handle different error types

### 🔧 Configuration
- Global configuration setup
- Environment-specific settings
- Path exclusions and inclusions
- Performance tuning options

### 📊 Output Formats
- **Mermaid**: GitHub-friendly diagrams
- **PlantUML**: Detailed UML diagrams
- **D3.js**: Interactive visualizations
- **OpenAPI**: API documentation
- **Sequence**: Endpoint flow diagrams
- **ERD**: Database schema visualization
- **Metrics**: Code quality analysis

### ⚡ Performance Optimization
- Large application handling
- Memory-efficient processing
- Streaming exports
- Batch operations
- Caching strategies

### 🔗 Integration Patterns
- **CI/CD**: Automated documentation generation
- **Git workflows**: Pre-commit hooks and PR checks
- **Documentation**: Automated doc site updates
- **Monitoring**: Performance and usage tracking

### 🎯 Advanced Filtering
- Component-specific analysis
- Depth limiting for complex graphs
- Focus areas and abstractions
- Custom node/edge filtering

## Real-World Scenarios

### Documentation Team
```ruby
# Generate comprehensive documentation suite
def generate_team_docs
  graph = RailsFlowMap.analyze
  
  # Overview for stakeholders
  RailsFlowMap.export(graph, format: :mermaid, output: 'docs/overview.md')
  
  # Interactive exploration for developers
  RailsFlowMap.export(graph, format: :d3js, output: 'docs/interactive.html')
  
  # API docs for frontend team
  RailsFlowMap.export(graph, format: :openapi, output: 'docs/api.yaml')
end
```

### Code Review Process
```ruby
# Generate architecture diff for PRs
def architecture_diff_for_pr
  before = RailsFlowMap.analyze_at('main')
  after = RailsFlowMap.analyze
  
  diff = RailsFlowMap.diff(before, after, format: :mermaid)
  File.write('ARCHITECTURE_CHANGES.md', diff)
end
```

### Performance Monitoring
```ruby
# Track architecture metrics over time
def track_architecture_metrics
  graph = RailsFlowMap.analyze
  metrics = RailsFlowMap.export(graph, format: :metrics)
  
  # Store metrics with timestamp for trend analysis
  timestamp = Time.current.strftime('%Y%m%d_%H%M%S')
  File.write("metrics/architecture_#{timestamp}.md", metrics)
end
```

## Custom Workflows

### Multi-Environment Analysis
```ruby
environments = ['development', 'staging', 'production']
environments.each do |env|
  # Switch environment context
  ENV['RAILS_ENV'] = env
  graph = RailsFlowMap.analyze
  
  RailsFlowMap.export(graph, 
    format: :metrics, 
    output: "docs/#{env}_metrics.md"
  )
end
```

### Incremental Documentation
```ruby
# Update only changed components
def incremental_update
  last_update = File.mtime('docs/architecture.md')
  changed_files = Dir.glob('app/**/*.rb').select { |f| File.mtime(f) > last_update }
  
  if changed_files.any?
    graph = RailsFlowMap.analyze
    RailsFlowMap.export(graph, format: :mermaid, output: 'docs/architecture.md')
    puts "Updated documentation for #{changed_files.size} changed files"
  end
end
```

## Tips and Best Practices

### 📈 Performance Tips
1. Use `excluded_paths` to skip unnecessary directories
2. Enable caching for repeated operations
3. Use streaming mode for large applications
4. Limit depth for complex visualizations

### 🔒 Security Considerations
1. Validate output paths to prevent path traversal
2. Sanitize user input in custom workflows
3. Use proper file permissions for output files
4. Review generated content before publishing

### 🚀 CI/CD Integration
1. Generate docs automatically on merge
2. Validate architecture changes in PRs
3. Update documentation sites automatically
4. Monitor documentation freshness

### 📚 Documentation Strategy
1. Generate multiple formats for different audiences
2. Update documentation as part of development workflow
3. Use interactive formats for complex architectures
4. Maintain historical architecture snapshots

## Troubleshooting Common Issues

### High Memory Usage
```ruby
# Solution: Use streaming and batch processing
RailsFlowMap.configure do |config|
  config.streaming_mode = true
  config.batch_size = 100
end
```

### Slow Analysis
```ruby
# Solution: Exclude unnecessary paths
RailsFlowMap.configure do |config|
  config.excluded_paths += ['vendor/', 'node_modules/', 'tmp/']
end
```

### Complex Diagrams
```ruby
# Solution: Use filtering and depth limits
RailsFlowMap.export(graph, 
  format: :mermaid,
  max_depth: 3,
  focus_on: ['User', 'Post']
)
```

For more detailed examples and patterns, see the main [USAGE_EXAMPLES.md](../USAGE_EXAMPLES.md) file.