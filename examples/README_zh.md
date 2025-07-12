# Rails Flow Map 示例

此目录包含 Rails Flow Map 的实用示例和使用模式。

## 文件概述

- **`basic_usage.rb`** - 基本使用模式和常见操作
- **`advanced_patterns.rb`** - 复杂工作流、性能优化和集成模式

## 运行示例

### 基本使用示例

```bash
cd rails-flow-map
ruby examples/basic_usage.rb
```

这将演示：
- 基本图形分析和导出
- 多种输出格式
- 文件输出操作
- 配置使用
- 错误处理模式

### 高级模式示例

```bash
ruby examples/advanced_patterns.rb
```

这涵盖：
- 大型应用程序的性能优化
- 自定义分析工作流
- 多个图形的批处理
- 高级过滤和焦点区域
- 集成模式（CI/CD、文档、监控）
- 自定义格式化器配置
- 监控和日志集成

## 示例类别

### 🚀 入门
- 基本分析：`RailsFlowMap.analyze`
- 简单导出：`RailsFlowMap.export(graph, format: :mermaid)`
- 文件操作：保存到特定位置
- 错误处理：捕获和处理不同类型的错误

### 🔧 配置
- 全局配置设置
- 特定环境设置
- 路径排除和包含
- 性能调优选项

### 📊 输出格式
- **Mermaid**：GitHub 友好图表
- **PlantUML**：详细 UML 图
- **D3.js**：交互式可视化
- **OpenAPI**：API 文档
- **Sequence**：端点流程图
- **ERD**：数据库模式可视化
- **Metrics**：代码质量分析

### ⚡ 性能优化
- 大型应用程序处理
- 内存高效处理
- 流式导出
- 批量操作
- 缓存策略

### 🔗 集成模式
- **CI/CD**：自动化文档生成
- **Git 工作流**：预提交钩子和 PR 检查
- **文档**：自动文档站点更新
- **监控**：性能和使用情况跟踪

### 🎯 高级过滤
- 组件特定分析
- 复杂图形的深度限制
- 焦点区域和抽象
- 自定义节点/边过滤

## 真实世界场景

### 文档团队
```ruby
# 生成综合文档套件
def generate_team_docs
  graph = RailsFlowMap.analyze
  
  # 利益相关者概述
  RailsFlowMap.export(graph, format: :mermaid, output: 'docs/overview.md')
  
  # 开发者交互式探索
  RailsFlowMap.export(graph, format: :d3js, output: 'docs/interactive.html')
  
  # 前端团队 API 文档
  RailsFlowMap.export(graph, format: :openapi, output: 'docs/api.yaml')
end
```

### 代码审查流程
```ruby
# 为 PR 生成架构差异
def architecture_diff_for_pr
  before = RailsFlowMap.analyze_at('main')
  after = RailsFlowMap.analyze
  
  diff = RailsFlowMap.diff(before, after, format: :mermaid)
  File.write('ARCHITECTURE_CHANGES.md', diff)
end
```

### 性能监控
```ruby
# 跟踪架构指标随时间的变化
def track_architecture_metrics
  graph = RailsFlowMap.analyze
  metrics = RailsFlowMap.export(graph, format: :metrics)
  
  # 用时间戳存储指标以进行趋势分析
  timestamp = Time.current.strftime('%Y%m%d_%H%M%S')
  File.write("metrics/architecture_#{timestamp}.md", metrics)
end
```

## 自定义工作流

### 多环境分析
```ruby
environments = ['development', 'staging', 'production']
environments.each do |env|
  # 切换环境上下文
  ENV['RAILS_ENV'] = env
  graph = RailsFlowMap.analyze
  
  RailsFlowMap.export(graph, 
    format: :metrics, 
    output: "docs/#{env}_metrics.md"
  )
end
```

### 增量文档
```ruby
# 仅更新已更改的组件
def incremental_update
  last_update = File.mtime('docs/architecture.md')
  changed_files = Dir.glob('app/**/*.rb').select { |f| File.mtime(f) > last_update }
  
  if changed_files.any?
    graph = RailsFlowMap.analyze
    RailsFlowMap.export(graph, format: :mermaid, output: 'docs/architecture.md')
    puts "为 #{changed_files.size} 个更改的文件更新了文档"
  end
end
```

## 提示和最佳实践

### 📈 性能提示
1. 使用 `excluded_paths` 跳过不必要的目录
2. 为重复操作启用缓存
3. 对大型应用程序使用流式模式
4. 为复杂可视化限制深度

### 🔒 安全考虑
1. 验证输出路径以防止路径遍历
2. 在自定义工作流中净化用户输入
3. 对输出文件使用适当的文件权限
4. 在发布前审查生成的内容

### 🚀 CI/CD 集成
1. 在合并时自动生成文档
2. 在 PR 中验证架构更改
3. 自动更新文档站点
4. 监控文档新鲜度

### 📚 文档策略
1. 为不同受众生成多种格式
2. 将文档更新作为开发工作流的一部分
3. 对复杂架构使用交互式格式
4. 维护历史架构快照

## 常见问题故障排除

### 高内存使用
```ruby
# 解决方案：使用流式和批处理
RailsFlowMap.configure do |config|
  config.streaming_mode = true
  config.batch_size = 100
end
```

### 分析缓慢
```ruby
# 解决方案：排除不必要的路径
RailsFlowMap.configure do |config|
  config.excluded_paths += ['vendor/', 'node_modules/', 'tmp/']
end
```

### 复杂图表
```ruby
# 解决方案：使用过滤和深度限制
RailsFlowMap.export(graph, 
  format: :mermaid,
  max_depth: 3,
  focus_on: ['User', 'Post']
)
```

有关更详细的示例和模式，请参见主要的 [USAGE_EXAMPLES_zh.md](../USAGE_EXAMPLES_zh.md) 文件。