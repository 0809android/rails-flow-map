# Rails Flow Map - 使用示例

本文档提供了如何在Rails应用程序中有效使用Rails Flow Map的全面示例。

## 目录

1. [基本用法](#基本用法)
2. [高级分析](#高级分析)
3. [不同的输出格式](#不同的输出格式)
4. [工作流集成](#工作流集成)
5. [配置选项](#配置选项)
6. [性能优化](#性能优化)
7. [故障排除](#故障排除)
8. [最佳实践](#最佳实践)

## 基本用法

### 快速开始

```ruby
# 1. 生成整个应用程序的基本流程图
graph = RailsFlowMap.analyze
result = RailsFlowMap.export(graph, format: :mermaid, output: 'docs/architecture.md')

# 2. 仅分析特定组件
graph = RailsFlowMap.analyze(models: true, controllers: false)
result = RailsFlowMap.export(graph, format: :plantuml, output: 'docs/models.puml')

# 3. 创建交互式可视化
graph = RailsFlowMap.analyze
RailsFlowMap.export(graph, format: :d3js, output: 'public/architecture.html')
```

### 使用Rake任务

```bash
# 生成所有可视化
rake flow_map:generate

# 生成特定格式
rake flow_map:generate FORMAT=mermaid OUTPUT=docs/flow.md

# 分析特定端点
rake flow_map:endpoint ENDPOINT=/api/v1/users FORMAT=sequence
```

## 高级分析

### 端点特定分析

```ruby
# 分析特定API端点的流程
graph = RailsFlowMap.analyze_endpoint('/api/v1/users')

# 生成端点的序列图
sequence = RailsFlowMap.export(graph, 
  format: :sequence, 
  endpoint: '/api/v1/users',
  include_middleware: true,
  include_callbacks: true,
  include_validations: true
)

puts sequence
```

### 比较不同版本

```ruby
# 比较当前版本与之前版本
before_graph = RailsFlowMap.analyze_at('v1.0.0')  # Git标签/分支
after_graph = RailsFlowMap.analyze                # 当前状态

# 生成差异可视化
diff_html = RailsFlowMap.diff(before_graph, after_graph, format: :html)
File.write('docs/architecture_changes.html', diff_html)

# 以Mermaid格式生成差异
diff_md = RailsFlowMap.diff(before_graph, after_graph, format: :mermaid)
File.write('docs/architecture_diff.md', diff_md)
```

### 自定义配置

```ruby
# 为您的项目配置Rails Flow Map
RailsFlowMap.configure do |config|
  config.include_models = true
  config.include_controllers = true
  config.include_routes = true
  config.include_services = true
  config.output_dir = 'doc/flow_maps'
  config.excluded_paths = ['tmp/', 'vendor/', 'spec/']
end

# 使用配置的设置
graph = RailsFlowMap.analyze
```

## 不同的输出格式

### 1. Mermaid图表（GitHub友好）

```ruby
graph = RailsFlowMap.analyze

# 基本Mermaid图表
mermaid = RailsFlowMap.export(graph, format: :mermaid)

# 带自定义样式选项
mermaid = RailsFlowMap.export(graph, 
  format: :mermaid,
  theme: 'dark',
  show_attributes: true,
  max_depth: 3
)

File.write('README_architecture.md', <<~MARKDOWN)
  # 应用程序架构

  ```mermaid
  #{mermaid}
  ```
MARKDOWN
```

### 2. PlantUML图表

```ruby
# 生成用于详细文档的PlantUML
plantuml = RailsFlowMap.export(graph, 
  format: :plantuml,
  include_methods: true,
  show_associations: true
)

File.write('docs/detailed_models.puml', plantuml)

# 与PlantUML服务器或本地安装一起使用
# plantuml -tpng docs/detailed_models.puml
```

### 3. 交互式D3.js可视化

```ruby
# 创建带有过滤和缩放功能的交互式HTML
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

### 4. API文档（OpenAPI）

```ruby
# 从路由生成OpenAPI规范
api_spec = RailsFlowMap.export(graph, 
  format: :openapi,
  api_version: '1.0.0',
  title: 'My API Documentation',
  description: '来自Rails Flow Map的自动生成API文档'
)

File.write('docs/api_spec.yaml', api_spec)

# 与Swagger UI或其他OpenAPI工具一起使用
```

### 5. 端点序列图

```ruby
# 特定端点的详细序列图
sequence = RailsFlowMap.export(graph, 
  format: :sequence,
  endpoint: '/api/v1/posts',
  include_middleware: true,
  include_callbacks: true,
  include_validations: true,
  include_database: true
)

File.write('docs/post_creation_flow.md', <<~MARKDOWN)
  # 帖子创建流程

  #{sequence}
MARKDOWN
```

### 6. 指标和分析

```ruby
# 生成综合指标报告
metrics = RailsFlowMap.export(graph, 
  format: :metrics,
  include_complexity: true,
  include_coupling: true,
  include_recommendations: true
)

File.write('docs/architecture_metrics.md', metrics)
```

## 工作流集成

### GitHub Actions集成

创建`.github/workflows/architecture_docs.yml`：

```yaml
name: 生成架构文档

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
    
    - name: 设置Ruby
      uses: ruby/setup-ruby@v1
      with:
        ruby-version: 3.1
        bundler-cache: true
    
    - name: 生成架构文档
      run: |
        bundle exec rake flow_map:generate_all
        
    - name: 检查更改
      run: |
        if [ -n "$(git status --porcelain docs/)" ]; then
          echo "架构文档有更改"
          echo "::set-output name=changes::true"
        fi
      id: check_changes
    
    - name: 提交更改
      if: steps.check_changes.outputs.changes == 'true'
      run: |
        git config --local user.email "action@github.com"
        git config --local user.name "GitHub Action"
        git add docs/
        git commit -m "📊 更新架构文档 [skip ci]"
        git push
```

### Pre-commit钩子

创建`.git/hooks/pre-commit`：

```bash
#!/bin/bash

# 生成用于审查的架构差异
if [ -f "Gemfile" ] && bundle exec rake flow_map:diff > /dev/null 2>&1; then
    echo "✅ 已生成用于审查的架构差异"
else
    echo "⚠️  无法生成架构差异"
fi
```

### VS Code集成

添加到`.vscode/tasks.json`：

```json
{
    "version": "2.0.0",
    "tasks": [
        {
            "label": "生成架构文档",
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
            "label": "分析端点",
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
            "description": "输入端点路径",
            "default": "/api/v1/users",
            "type": "promptString"
        }
    ]
}
```

## 配置选项

### 全局配置

```ruby
# config/initializers/rails_flow_map.rb
RailsFlowMap.configure do |config|
  # 分析选项
  config.include_models = true
  config.include_controllers = true
  config.include_routes = true
  config.include_services = true
  config.include_jobs = true
  config.include_mailers = true
  
  # 输出选项
  config.output_dir = Rails.root.join('doc', 'flow_maps')
  config.auto_generate = Rails.env.development?
  
  # 排除项
  config.excluded_paths = [
    'tmp/',
    'vendor/',
    'spec/',
    'test/',
    'node_modules/'
  ]
  
  # 性能
  config.max_file_size = 1.megabyte
  config.analysis_timeout = 30.seconds
  
  # 安全性
  config.allow_system_paths = false
  config.sanitize_output = true
end
```

### 环境特定设置

```ruby
# 每个环境的不同设置
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

## 性能优化

### 大型应用程序

```ruby
# 对于大型应用程序，增量分析
def generate_architecture_docs
  # 1. 首先分析核心模型
  models_graph = RailsFlowMap.analyze(
    models: true, 
    controllers: false, 
    routes: false
  )
  RailsFlowMap.export(models_graph, 
    format: :mermaid, 
    output: 'docs/models_overview.md'
  )
  
  # 2. 单独分析API控制器
  api_graph = RailsFlowMap.analyze_controllers(
    pattern: 'app/controllers/api/**/*_controller.rb'
  )
  RailsFlowMap.export(api_graph, 
    format: :openapi, 
    output: 'docs/api_spec.yaml'
  )
  
  # 3. 生成指标报告
  full_graph = RailsFlowMap.analyze
  RailsFlowMap.export(full_graph, 
    format: :metrics, 
    output: 'docs/metrics.md'
  )
end
```

### 缓存结果

```ruby
# 缓存分析结果
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

## 故障排除

### 常见问题和解决方案

#### 1. 大型应用程序的内存使用

```ruby
# 问题：高内存使用
# 解决方案：使用流式或增量分析

RailsFlowMap.configure do |config|
  config.streaming_mode = true
  config.batch_size = 100
  config.memory_limit = 512.megabytes
end

# 或分块分析
%w[models controllers services].each do |component|
  graph = RailsFlowMap.analyze(component.to_sym => true)
  RailsFlowMap.export(graph, 
    format: :mermaid, 
    output: "docs/#{component}.md"
  )
end
```

#### 2. 分析性能缓慢

```ruby
# 问题：分析缓慢
# 解决方案：排除不必要的文件并使用缓存

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

#### 3. 缺少依赖项

```ruby
# 问题：缺少关联或关系
# 解决方案：确保包含所有相关文件

graph = RailsFlowMap.analyze(
  models: true,
  controllers: true,
  routes: true,
  services: true,
  jobs: true,
  mailers: true
)

# 检查缺失的关系
puts "节点数：#{graph.nodes.count}"
puts "边数：#{graph.edges.count}"
```

#### 4. 输出格式问题

```ruby
# 问题：生成的图表过于复杂
# 解决方案：使用过滤和深度限制

RailsFlowMap.export(graph, 
  format: :mermaid,
  max_depth: 2,
  exclude_types: [:job, :mailer],
  focus_on: ['User', 'Post', 'Comment']
)
```

## 最佳实践

### 1. 文档工作流

```ruby
# 创建全面的文档生成脚本
class DocumentationGenerator
  def self.run
    puts "正在生成架构文档..."
    
    # 1. 完整的应用程序概览
    generate_overview
    
    # 2. API文档
    generate_api_docs
    
    # 3. 数据库模式可视化
    generate_schema_docs
    
    # 4. 指标和分析
    generate_metrics
    
    puts "文档生成成功！"
  end
  
  private
  
  def self.generate_overview
    graph = RailsFlowMap.analyze
    
    # 用于GitHub README的Mermaid
    mermaid = RailsFlowMap.export(graph, format: :mermaid)
    update_readme_with_architecture(mermaid)
    
    # 用于详细探索的交互式HTML
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

### 2. 团队协作

```ruby
# 创建团队特定视图
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

### 3. 代码审查集成

```ruby
# 生成用于代码审查的差异
class CodeReviewHelper
  def self.generate_architecture_diff(base_branch = 'main')
    # 保存当前状态
    after_graph = RailsFlowMap.analyze
    
    # 检出基础分支并分析
    system("git stash")
    system("git checkout #{base_branch}")
    before_graph = RailsFlowMap.analyze
    system("git checkout -")
    system("git stash pop")
    
    # 生成差异
    diff = RailsFlowMap.diff(before_graph, after_graph, format: :mermaid)
    
    File.write('ARCHITECTURE_CHANGES.md', <<~MARKDOWN)
      # 架构更改

      本文档显示了此PR中的架构更改。
      
      #{diff}
      
      ## 摘要
      
      - **添加**：#{(after_graph.nodes.keys - before_graph.nodes.keys).count} 个组件
      - **修改**：#{detect_modifications(before_graph, after_graph).count} 个组件
      - **删除**：#{(before_graph.nodes.keys - after_graph.nodes.keys).count} 个组件
    MARKDOWN
  end
end
```

### 4. 持续文档

```ruby
# 添加到部署脚本
namespace :deploy do
  desc "更新架构文档"
  task :update_docs do
    puts "正在更新架构文档..."
    
    graph = RailsFlowMap.analyze
    
    # 更新公共文档
    RailsFlowMap.export(graph, 
      format: :d3js, 
      output: Rails.root.join('public', 'architecture.html')
    )
    
    # 更新API文档
    RailsFlowMap.export(graph, 
      format: :openapi, 
      output: Rails.root.join('public', 'api_docs.yaml')
    )
    
    puts "文档更新成功！"
  end
end

# 添加到Capistrano deploy.rb
after 'deploy:migrate', 'deploy:update_docs'
```

---

本全面指南应该帮助您在开发工作流中充分利用Rails Flow Map。有关更高级的用法和自定义选项，请参阅API文档和源代码。