# CI/CD 集成指南

本指南说明如何将 Rails Flow Map 集成到您的持续集成和部署管道中。

## 目录

- [概述](#概述)
- [GitHub Actions](#github-actions)
- [GitLab CI](#gitlab-ci)
- [CircleCI](#circleci)
- [Jenkins](#jenkins)
- [最佳实践](#最佳实践)
- [故障排除](#故障排除)

## 概述

将 Rails Flow Map 集成到 CI/CD 管道中可以提供：

- **自动文档更新** - 保持架构文档与代码同步
- **PR/MR 审查** - 在拉取请求中可视化架构更改
- **质量门控** - 强制执行架构标准
- **历史跟踪** - 随时间监控架构演变

## GitHub Actions

### 基本设置

创建 `.github/workflows/rails-flow-map.yml`：

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
    
    - name: 设置 Ruby
      uses: ruby/setup-ruby@v1
      with:
        ruby-version: '3.1'
        bundler-cache: true
    
    - name: 生成架构文档
      run: |
        bundle exec rake flow_map:generate_all
        
    - name: 上传构件
      uses: actions/upload-artifact@v3
      with:
        name: architecture-docs
        path: doc/flow_maps/
```

### 带 PR 评论的高级配置

```yaml
name: 架构分析

on:
  pull_request:
    types: [opened, synchronize]

jobs:
  analyze-architecture:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
      with:
        fetch-depth: 0  # 用于比较的完整历史
    
    - name: 检出基础分支
      run: |
        git fetch origin ${{ github.base_ref }}
        
    - name: 设置 Ruby
      uses: ruby/setup-ruby@v1
      with:
        ruby-version: '3.1'
        bundler-cache: true
    
    - name: 生成架构差异
      id: diff
      run: |
        # 分析基础分支
        git checkout ${{ github.base_ref }}
        bundle exec rake flow_map:analyze > base.json
        
        # 分析 PR 分支
        git checkout ${{ github.head_ref }}
        bundle exec rake flow_map:analyze > pr.json
        
        # 生成差异
        bundle exec rake flow_map:diff BASE=base.json CURRENT=pr.json FORMAT=markdown > diff.md
        
        # 设置输出
        echo "diff<<EOF" >> $GITHUB_OUTPUT
        cat diff.md >> $GITHUB_OUTPUT
        echo "EOF" >> $GITHUB_OUTPUT
    
    - name: 评论 PR
      uses: actions/github-script@v6
      with:
        script: |
          const diff = `${{ steps.diff.outputs.diff }}`;
          
          github.rest.issues.createComment({
            issue_number: context.issue.number,
            owner: context.repo.owner,
            repo: context.repo.repo,
            body: `## 架构影响分析\n\n${diff}`
          });
```

### 计划文档更新

```yaml
name: 每周架构报告

on:
  schedule:
    - cron: '0 0 * * 0'  # 每周日午夜
  workflow_dispatch:  # 手动触发

jobs:
  generate-report:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: 设置 Ruby
      uses: ruby/setup-ruby@v1
      with:
        ruby-version: '3.1'
        bundler-cache: true
    
    - name: 生成综合报告
      run: |
        bundle exec rake flow_map:generate_all
        bundle exec rake flow_map:metrics > metrics.md
        
    - name: 创建拉取请求
      uses: peter-evans/create-pull-request@v5
      with:
        commit-message: 'docs: 更新架构文档'
        title: '每周架构文档更新'
        body: |
          ## 自动架构更新
          
          此 PR 根据当前代码库更新架构文档。
          
          ### 生成的文件：
          - 架构图
          - API 文档
          - 指标报告
        branch: docs/architecture-update
```

## GitLab CI

### 基本设置

创建 `.gitlab-ci.yml`：

```yaml
stages:
  - analyze
  - document

variables:
  BUNDLE_PATH: vendor/bundle

before_script:
  - apt-get update -qq && apt-get install -y nodejs
  - bundle config set --local path 'vendor/bundle'
  - bundle install -j $(nproc)

analyze_architecture:
  stage: analyze
  script:
    - bundle exec rake flow_map:analyze
    - bundle exec rake flow_map:metrics
  artifacts:
    reports:
      junit: reports/architecture-analysis.xml
    paths:
      - doc/flow_maps/
    expire_in: 1 week

generate_docs:
  stage: document
  script:
    - bundle exec rake flow_map:generate_all
  artifacts:
    paths:
      - doc/flow_maps/
      - public/architecture.html
    expire_in: 1 month
  only:
    - main
    - develop
```

### 合并请求集成

```yaml
architecture_diff:
  stage: analyze
  script:
    - git fetch origin $CI_MERGE_REQUEST_TARGET_BRANCH_NAME
    - git checkout $CI_MERGE_REQUEST_TARGET_BRANCH_NAME
    - bundle exec rake flow_map:analyze > base.json
    - git checkout $CI_COMMIT_SHA
    - bundle exec rake flow_map:analyze > current.json
    - bundle exec rake flow_map:diff BASE=base.json CURRENT=current.json FORMAT=gitlab > architecture_diff.md
  artifacts:
    reports:
      codequality: architecture_diff.json
    expose_as: '架构更改'
    paths:
      - architecture_diff.md
  only:
    - merge_requests
```

## CircleCI

### 基本设置

创建 `.circleci/config.yml`：

```yaml
version: 2.1

orbs:
  ruby: circleci/ruby@2.0.0

jobs:
  generate_architecture_docs:
    docker:
      - image: cimg/ruby:3.1
    steps:
      - checkout
      - ruby/install-deps
      
      - run:
          name: 生成架构文档
          command: |
            bundle exec rake flow_map:generate_all
            
      - store_artifacts:
          path: doc/flow_maps
          destination: architecture-docs
          
      - run:
          name: 生成指标报告
          command: |
            bundle exec rake flow_map:metrics > metrics_report.md
            
      - store_artifacts:
          path: metrics_report.md

workflows:
  version: 2
  analyze_and_document:
    jobs:
      - generate_architecture_docs:
          filters:
            branches:
              only:
                - main
                - develop
```

### 带比较的高级工作流

```yaml
version: 2.1

jobs:
  architecture_analysis:
    docker:
      - image: cimg/ruby:3.1
    steps:
      - checkout
      - run:
          name: 获取基础分支
          command: |
            git fetch origin main:main
            
      - ruby/install-deps
      
      - run:
          name: 分析架构更改
          command: |
            # 分析 main 分支
            git checkout main
            bundle exec rake flow_map:analyze > main_architecture.json
            
            # 分析当前分支
            git checkout $CIRCLE_BRANCH
            bundle exec rake flow_map:analyze > current_architecture.json
            
            # 生成比较
            bundle exec rake flow_map:diff \
              BASE=main_architecture.json \
              CURRENT=current_architecture.json \
              FORMAT=html > architecture_changes.html
              
      - store_artifacts:
          path: architecture_changes.html
          destination: architecture-changes

workflows:
  version: 2
  pr_analysis:
    jobs:
      - architecture_analysis:
          filters:
            branches:
              ignore: main
```

## Jenkins

### 基本管道

创建 `Jenkinsfile`：

```groovy
pipeline {
    agent any
    
    stages {
        stage('设置') {
            steps {
                script {
                    // 安装 Ruby 依赖
                    sh 'bundle install'
                }
            }
        }
        
        stage('分析架构') {
            steps {
                script {
                    sh 'bundle exec rake flow_map:analyze'
                    sh 'bundle exec rake flow_map:metrics > metrics.txt'
                }
            }
        }
        
        stage('生成文档') {
            steps {
                script {
                    sh 'bundle exec rake flow_map:generate_all'
                }
            }
        }
        
        stage('归档结果') {
            steps {
                archiveArtifacts artifacts: 'doc/flow_maps/**/*', fingerprint: true
                publishHTML([
                    allowMissing: false,
                    alwaysLinkToLastBuild: true,
                    keepAll: true,
                    reportDir: 'doc/flow_maps',
                    reportFiles: 'index.html',
                    reportName: '架构文档'
                ])
            }
        }
    }
    
    post {
        always {
            cleanWs()
        }
    }
}
```

### 带 PR 分析的多分支管道

```groovy
pipeline {
    agent any
    
    environment {
        CHANGE_TARGET = "${env.CHANGE_TARGET ?: 'main'}"
    }
    
    stages {
        stage('检出') {
            steps {
                checkout scm
                script {
                    if (env.CHANGE_ID) {
                        sh "git fetch origin ${env.CHANGE_TARGET}:${env.CHANGE_TARGET}"
                    }
                }
            }
        }
        
        stage('架构差异') {
            when {
                changeRequest()
            }
            steps {
                script {
                    // 分析基础分支
                    sh """
                        git checkout ${env.CHANGE_TARGET}
                        bundle exec rake flow_map:analyze > base_architecture.json
                    """
                    
                    // 分析 PR 分支
                    sh """
                        git checkout ${env.GIT_COMMIT}
                        bundle exec rake flow_map:analyze > pr_architecture.json
                    """
                    
                    // 生成差异
                    sh """
                        bundle exec rake flow_map:diff \
                            BASE=base_architecture.json \
                            CURRENT=pr_architecture.json \
                            FORMAT=html > architecture_diff.html
                    """
                }
            }
        }
        
        stage('发布结果') {
            steps {
                publishHTML([
                    reportDir: '.',
                    reportFiles: 'architecture_diff.html',
                    reportName: '架构更改'
                ])
                
                // 如果使用 GitHub，则在 PR 上评论
                script {
                    if (env.CHANGE_ID && env.GITHUB_TOKEN) {
                        sh """
                            bundle exec rake flow_map:comment_pr \
                                PR_NUMBER=${env.CHANGE_ID} \
                                DIFF_FILE=architecture_diff.html
                        """
                    }
                }
            }
        }
    }
}
```

## 最佳实践

### 1. 缓存依赖

通过缓存 Ruby gems 加快构建速度：

```yaml
# GitHub Actions
- uses: ruby/setup-ruby@v1
  with:
    bundler-cache: true

# GitLab CI
cache:
  paths:
    - vendor/bundle

# CircleCI
- restore_cache:
    keys:
      - gem-cache-{{ checksum "Gemfile.lock" }}
```

### 2. 并行化分析

并行运行不同的分析：

```yaml
# GitHub Actions
jobs:
  analyze-models:
    runs-on: ubuntu-latest
    steps:
      - run: bundle exec rake flow_map:models
      
  analyze-controllers:
    runs-on: ubuntu-latest
    steps:
      - run: bundle exec rake flow_map:controllers
      
  analyze-routes:
    runs-on: ubuntu-latest
    steps:
      - run: bundle exec rake flow_map:routes
```

### 3. 设置资源限制

防止大型代码库的内存问题：

```ruby
# config/initializers/rails_flow_map.rb
RailsFlowMap.configure do |config|
  config.memory_limit = ENV.fetch('CI_MEMORY_LIMIT', '2GB')
  config.analysis_timeout = ENV.fetch('CI_TIMEOUT', '300').to_i.seconds
end
```

### 4. 条件生成

仅在相关文件更改时生成文档：

```yaml
# GitHub Actions
- name: 检查相关更改
  id: changes
  uses: dorny/paths-filter@v2
  with:
    filters: |
      ruby:
        - 'app/**/*.rb'
        - 'lib/**/*.rb'
        - 'config/routes.rb'

- name: 生成文档
  if: steps.changes.outputs.ruby == 'true'
  run: bundle exec rake flow_map:generate_all
```

### 5. 构件管理

存储和比较历史数据：

```yaml
# 存储分析结果
- uses: actions/upload-artifact@v3
  with:
    name: architecture-${{ github.sha }}
    path: architecture.json
    retention-days: 90

# 下载用于比较
- uses: actions/download-artifact@v3
  with:
    name: architecture-${{ github.event.before }}
    path: previous/
```

## 故障排除

### 常见问题

1. **内存不足**
   ```yaml
   # 增加内存限制
   env:
     RAILS_FLOW_MAP_MEMORY_LIMIT: 4GB
   ```

2. **大型仓库超时**
   ```yaml
   # 增加超时时间
   timeout-minutes: 30
   ```

3. **缺少依赖**
   ```yaml
   # 安装系统依赖
   - run: apt-get update && apt-get install -y graphviz
   ```

4. **权限问题**
   ```yaml
   # 确保写入权限
   - run: chmod +x bundle exec rake flow_map:generate
   ```

### 调试模式

启用详细日志记录以进行故障排除：

```yaml
env:
  RAILS_FLOW_MAP_LOG_LEVEL: debug
  RAILS_FLOW_MAP_VERBOSE: true
```

---

有关更多示例和配置，请查看 [examples directory](https://github.com/railsflowmap/rails-flow-map/tree/main/examples/ci_cd)。