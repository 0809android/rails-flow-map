# VS Code 集成

本指南帮助您设置 Visual Studio Code 以便高效使用 Rails Flow Map。

## 快速设置

### 1. 安装推荐的扩展

为获得最佳体验，请安装以下 VS Code 扩展：

- **Ruby** - Ruby 语言支持
- **Ruby Solargraph** - Ruby 的智能代码补全
- **Rails** - Rails 片段和语法
- **GitLens** - 增强的 Git 集成

### 2. 配置任务

创建 `.vscode/tasks.json`：

```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Rails Flow Map: 生成所有",
      "type": "shell",
      "command": "bundle exec rake flow_map:generate_all",
      "group": {
        "kind": "build",
        "isDefault": true
      },
      "presentation": {
        "echo": true,
        "reveal": "always",
        "focus": false,
        "panel": "shared",
        "showReuseMessage": true,
        "clear": false
      }
    },
    {
      "label": "Rails Flow Map: 生成 Mermaid",
      "type": "shell",
      "command": "bundle exec rake flow_map:generate FORMAT=mermaid OUTPUT=docs/architecture.md",
      "group": "build"
    },
    {
      "label": "Rails Flow Map: 生成交互式",
      "type": "shell",
      "command": "bundle exec rake flow_map:generate FORMAT=d3js OUTPUT=public/architecture.html",
      "group": "build"
    },
    {
      "label": "Rails Flow Map: 分析端点",
      "type": "shell",
      "command": "bundle exec rake flow_map:endpoint ENDPOINT=${input:endpoint} FORMAT=sequence",
      "group": "build",
      "problemMatcher": []
    },
    {
      "label": "Rails Flow Map: 生成指标",
      "type": "shell",
      "command": "bundle exec rake flow_map:metrics > docs/metrics.md",
      "group": "build"
    }
  ],
  "inputs": [
    {
      "id": "endpoint",
      "description": "端点路径 (例如 /api/v1/users)",
      "default": "/api/v1/users",
      "type": "promptString"
    }
  ]
}
```

### 3. 配置键盘快捷键

创建或更新 `.vscode/keybindings.json`：

```json
[
  {
    "key": "ctrl+shift+f",
    "command": "workbench.action.tasks.runTask",
    "args": "Rails Flow Map: 生成所有"
  },
  {
    "key": "ctrl+shift+m",
    "command": "workbench.action.tasks.runTask",
    "args": "Rails Flow Map: 生成 Mermaid"
  },
  {
    "key": "ctrl+shift+d",
    "command": "workbench.action.tasks.runTask",
    "args": "Rails Flow Map: 生成交互式"
  }
]
```

### 4. 配置工作区设置

创建 `.vscode/settings.json`：

```json
{
  // Ruby 设置
  "ruby.useBundler": true,
  "ruby.lint": {
    "rubocop": true
  },
  
  // 文件关联
  "files.associations": {
    "*.puml": "plantuml",
    "*.mermaid": "markdown"
  },
  
  // 排除生成的文件不在搜索中显示
  "search.exclude": {
    "**/doc/flow_maps/**": true,
    "**/tmp/**": true
  },
  
  // 自定义文件图标
  "material-icon-theme.files.associations": {
    "architecture.md": "readme",
    "metrics.md": "stats"
  }
}
```

## 高级功能

### 1. 代码片段

创建 `.vscode/rails-flow-map.code-snippets`：

```json
{
  "Generate Flow Map": {
    "prefix": "flow-generate",
    "body": [
      "graph = RailsFlowMap.analyze",
      "RailsFlowMap.export(graph, format: :${1|mermaid,plantuml,d3js,graphviz|}, output: '${2:output.md}')"
    ],
    "description": "生成流程图"
  },
  
  "Analyze Endpoint": {
    "prefix": "flow-endpoint",
    "body": [
      "endpoint_graph = RailsFlowMap.analyze_endpoint('${1:/api/v1/users}')",
      "sequence = RailsFlowMap.export(endpoint_graph, format: :sequence)"
    ],
    "description": "分析端点"
  },
  
  "Generate Metrics": {
    "prefix": "flow-metrics",
    "body": [
      "graph = RailsFlowMap.analyze",
      "metrics = RailsFlowMap.export(graph, format: :metrics, include_complexity: true)"
    ],
    "description": "生成指标"
  }
}
```

### 2. 调试配置

在 `.vscode/launch.json` 中添加：

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "调试 Rails Flow Map",
      "type": "Ruby",
      "request": "launch",
      "program": "${workspaceRoot}/bin/rake",
      "args": ["flow_map:generate"],
      "env": {
        "RAILS_FLOW_MAP_DEBUG": "true"
      }
    },
    {
      "name": "使用参数调试",
      "type": "Ruby",
      "request": "launch",
      "program": "${workspaceRoot}/bin/rake",
      "args": [
        "flow_map:generate",
        "FORMAT=${input:format}",
        "OUTPUT=${input:output}"
      ]
    }
  ],
  "inputs": [
    {
      "id": "format",
      "type": "pickString",
      "description": "选择输出格式",
      "options": ["mermaid", "plantuml", "d3js", "graphviz"],
      "default": "mermaid"
    },
    {
      "id": "output",
      "type": "promptString",
      "description": "输出文件路径",
      "default": "docs/architecture.md"
    }
  ]
}
```

### 3. 问题匹配器

为更好的错误检测创建 `.vscode/problem-matchers.json`：

```json
{
  "problemMatcher": [
    {
      "name": "rails-flow-map",
      "owner": "ruby",
      "fileLocation": ["relative", "${workspaceFolder}"],
      "pattern": {
        "regexp": "^(.+):(\\d+):(\\d+): (.+)$",
        "file": 1,
        "line": 2,
        "column": 3,
        "message": 4
      }
    }
  ]
}
```

## 推荐的工作流

### 1. 使用任务运行器

按 `Ctrl+Shift+P` (或 Mac 上的 `Cmd+Shift+P`) 并输入 "Run Task"，然后选择一个 Rails Flow Map 任务。

### 2. 使用终端

VS Code 的集成终端非常适合运行 Rails Flow Map 命令：

```bash
# 在 VS Code 终端中
bundle exec rake flow_map:generate
```

### 3. 监视模式

设置一个监视任务以自动重新生成文档：

```json
{
  "label": "Rails Flow Map: 监视",
  "type": "shell",
  "command": "nodemon --exec 'bundle exec rake flow_map:generate' --watch app/ --ext rb",
  "isBackground": true,
  "problemMatcher": {
    "pattern": {
      "regexp": "^([^\\s].*)$",
      "file": 1
    },
    "background": {
      "activeOnStart": true,
      "beginsPattern": "^\\[nodemon\\] starting",
      "endsPattern": "^\\[nodemon\\] clean exit"
    }
  }
}
```

## 与扩展集成

### 1. Markdown 预览

使用 VS Code 的内置 Markdown 预览查看生成的 Mermaid 图表：

1. 打开生成的 `.md` 文件
2. 按 `Ctrl+Shift+V` 打开预览
3. 安装 "Markdown Preview Mermaid Support" 扩展以渲染图表

### 2. PlantUML 预览

安装 "PlantUML" 扩展以预览 PlantUML 图表：

1. 安装扩展
2. 打开 `.puml` 文件
3. 按 `Alt+D` 查看预览

### 3. GraphViz 预览

安装 "Graphviz Preview" 扩展以查看 `.dot` 文件：

1. 安装扩展
2. 打开 `.dot` 文件
3. 使用命令面板运行 "Graphviz: Open Preview to the Side"

## 故障排除

### 常见问题

1. **任务失败并显示 "bundle: command not found"**
   - 确保您使用正确的 Ruby 版本
   - 运行 `bundle install` 在 VS Code 终端中

2. **找不到 rake 任务**
   - 验证 Rails Flow Map 已正确安装
   - 检查您的 `Gemfile` 中是否有 gem

3. **权限错误**
   - 确保输出目录存在并可写
   - 检查文件权限

### 调试提示

在 VS Code 终端中启用详细日志记录：

```bash
export RAILS_FLOW_MAP_DEBUG=true
bundle exec rake flow_map:generate --trace
```

## 有用的扩展

### 推荐用于 Rails Flow Map

- **Mermaid Preview** - 实时 Mermaid 图表预览
- **PlantUML** - PlantUML 图表支持
- **Graphviz Interactive Preview** - GraphViz 可视化
- **Markdown All in One** - 增强的 Markdown 支持
- **Rails DB Schema** - 数据库模式可视化

### 通用 Rails 开发

- **Rails Run Specs** - 运行 RSpec 测试
- **Rails Go to Spec** - 在代码和规格之间切换
- **Ruby Test Explorer** - 测试资源管理器集成
- **erb** - ERB 模板支持

---

有关更多 VS Code 提示和技巧，请查看[官方 VS Code Ruby 文档](https://code.visualstudio.com/docs/languages/ruby)。