# 为 Rails Flow Map 做贡献

感谢您有兴趣为 Rails Flow Map 做贡献！我们欢迎社区贡献，帮助我们让这个工具变得更好。

## 目录

- [行为准则](#行为准则)
- [入门指南](#入门指南)
- [如何贡献](#如何贡献)
- [开发设置](#开发设置)
- [测试](#测试)
- [提交更改](#提交更改)
- [风格指南](#风格指南)
- [社区](#社区)

## 行为准则

参与此项目即表示您同意遵守我们的行为准则：

- 保持尊重和包容
- 欢迎新人并帮助他们入门
- 专注于建设性批评
- 优雅地接受反馈
- 优先考虑社区的最佳利益

## 入门指南

1. 在 GitHub 上 Fork 仓库
2. 将您的 Fork 克隆到本地
3. 设置开发环境
4. 为您的更改创建分支
5. 进行更改并测试
6. 提交拉取请求

## 如何贡献

### 报告错误

在创建错误报告之前，请检查现有问题以避免重复。创建错误报告时，请包含：

- 清晰描述性的标题
- 重现行为的步骤
- 预期行为与实际行为
- 相关截图（如适用）
- 您的环境详情（Ruby 版本、Rails 版本、操作系统）

### 提出改进建议

欢迎提出改进建议！请提供：

- 清晰描述性的标题
- 对提议功能的详细描述
- 用例和示例
- 考虑过的替代方案

### 代码贡献

#### 首次贡献者

寻找标记为 `good-first-issue` 或 `help-wanted` 的问题。这些是新贡献者的绝佳起点。

#### 开发流程

1. **Fork 并克隆**
   ```bash
   git clone https://github.com/your-username/rails-flow-map.git
   cd rails-flow-map
   ```

2. **安装依赖**
   ```bash
   bundle install
   ```

3. **创建功能分支**
   ```bash
   git checkout -b feature/your-feature-name
   ```

4. **进行更改**
   - 编写清晰、可读的代码
   - 为新功能添加测试
   - 根据需要更新文档

5. **运行测试**
   ```bash
   bundle exec rspec
   ```

6. **提交更改**
   ```bash
   git add .
   git commit -m "添加描述性的提交信息"
   ```

## 开发设置

### 先决条件

- Ruby 2.7.0 或更高版本
- Bundler
- Git

### 本地开发

1. **安装依赖**
   ```bash
   bundle install
   ```

2. **运行测试**
   ```bash
   bundle exec rspec
   ```

3. **运行代码检查器**
   ```bash
   bundle exec rubocop
   ```

4. **在示例 Rails 应用中测试**
   ```bash
   cd blog_sample
   bundle install
   bundle exec rails flow_map:generate
   ```

## 测试

### 运行测试

```bash
# 运行所有测试
bundle exec rspec

# 运行特定测试文件
bundle exec rspec spec/rails_flow_map/analyzers/model_analyzer_spec.rb

# 带覆盖率运行
COVERAGE=true bundle exec rspec
```

### 编写测试

- 为所有新功能编写测试
- 保持测试覆盖率在 90% 以上
- 遵循 RSpec 最佳实践
- 使用描述性的测试名称

示例：
```ruby
RSpec.describe RailsFlowMap::Analyzers::ModelAnalyzer do
  describe '#analyze' do
    it '检测 has_many 关联' do
      # 测试实现
    end
  end
end
```

## 提交更改

### 拉取请求流程

1. **更新文档**
   - 根据需要更新 README
   - 添加/更新代码注释
   - 更新 CHANGELOG.md

2. **确保质量**
   - 所有测试通过
   - 代码遵循风格指南
   - 无代码检查错误

3. **创建拉取请求**
   - 使用清晰、描述性的标题
   - 引用相关问题
   - 描述做了什么更改以及为什么
   - 包含 UI 更改的截图

### 拉取请求模板

```markdown
## 描述
更改的简要描述

## 更改类型
- [ ] 错误修复
- [ ] 新功能
- [ ] 文档更新
- [ ] 性能改进

## 测试
- [ ] 所有测试通过
- [ ] 添加了新测试
- [ ] 手动测试过

## 检查清单
- [ ] 代码遵循风格指南
- [ ] 自我审查了代码
- [ ] 更新了文档
- [ ] 没有新的警告
```

## 风格指南

### Ruby 风格指南

我们遵循标准的 Ruby 风格指南，并进行了一些修改：

- 使用 2 个空格缩进
- 尽可能限制行长为 80 个字符
- 使用描述性的变量和方法名
- 多行代码块使用 `do...end`

### Git 提交信息

- 使用现在时（"Add feature" 而不是 "Added feature"）
- 使用祈使语气（"Move cursor to..." 而不是 "Moves cursor to..."）
- 第一行限制在 72 个字符内
- 引用问题和拉取请求

示例：
```
添加模型关联分析器

- 实现 has_many 关系检测
- 添加对 through 关联的支持
- 包含多态关联处理

Fixes #123
```

### 文档风格

- 使用清晰、简洁的语言
- 包含代码示例
- 保持 README 部分组织良好
- 为面向用户的更改更新 CHANGELOG.md

## 社区

### 获取帮助

- 查看[文档](README_zh.md)
- 搜索[现有问题](https://github.com/railsflowmap/rails-flow-map/issues)
- 在[讨论区](https://github.com/railsflowmap/rails-flow-map/discussions)提问

### 沟通渠道

- GitHub Issues 用于错误和功能
- GitHub Discussions 用于问题和想法
- Pull Requests 用于代码贡献

## 认可

贡献者将在以下地方得到认可：
- 项目 README
- 发布说明
- 我们的[贡献者页面](https://github.com/railsflowmap/rails-flow-map/contributors)

## 许可证

通过贡献，您同意您的贡献将在 MIT 许可证下获得许可。

---

感谢您为 Rails Flow Map 做出贡献！您的努力使每个人的 Rails 开发变得更好。🚀