# CI/CD統合ガイド

このガイドでは、Rails Flow Mapを継続的インテグレーションとデプロイメントパイプラインに統合する方法を説明します。

## 目次

- [概要](#概要)
- [GitHub Actions](#github-actions)
- [GitLab CI](#gitlab-ci)
- [CircleCI](#circleci)
- [Jenkins](#jenkins)
- [ベストプラクティス](#ベストプラクティス)
- [トラブルシューティング](#トラブルシューティング)

## 概要

Rails Flow MapをCI/CDパイプラインに統合することで以下が実現できます：

- **自動ドキュメント更新** - アーキテクチャドキュメントをコードと同期
- **PR/MRレビュー** - プルリクエストでアーキテクチャの変更を可視化
- **品質ゲート** - アーキテクチャ標準の強制
- **履歴追跡** - 時間経過によるアーキテクチャの進化を監視

## GitHub Actions

### 基本設定

`.github/workflows/rails-flow-map.yml`を作成：

```yaml
name: アーキテクチャドキュメント生成

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
    
    - name: Rubyのセットアップ
      uses: ruby/setup-ruby@v1
      with:
        ruby-version: '3.1'
        bundler-cache: true
    
    - name: アーキテクチャドキュメントを生成
      run: |
        bundle exec rake flow_map:generate_all
        
    - name: アーティファクトをアップロード
      uses: actions/upload-artifact@v3
      with:
        name: architecture-docs
        path: doc/flow_maps/
```

### PRコメント付き高度な設定

```yaml
name: アーキテクチャ分析

on:
  pull_request:
    types: [opened, synchronize]

jobs:
  analyze-architecture:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
      with:
        fetch-depth: 0  # 比較のための完全な履歴
    
    - name: ベースブランチをチェックアウト
      run: |
        git fetch origin ${{ github.base_ref }}
        
    - name: Rubyのセットアップ
      uses: ruby/setup-ruby@v1
      with:
        ruby-version: '3.1'
        bundler-cache: true
    
    - name: アーキテクチャ差分を生成
      id: diff
      run: |
        # ベースブランチを分析
        git checkout ${{ github.base_ref }}
        bundle exec rake flow_map:analyze > base.json
        
        # PRブランチを分析
        git checkout ${{ github.head_ref }}
        bundle exec rake flow_map:analyze > pr.json
        
        # 差分を生成
        bundle exec rake flow_map:diff BASE=base.json CURRENT=pr.json FORMAT=markdown > diff.md
        
        # 出力を設定
        echo "diff<<EOF" >> $GITHUB_OUTPUT
        cat diff.md >> $GITHUB_OUTPUT
        echo "EOF" >> $GITHUB_OUTPUT
    
    - name: PRにコメント
      uses: actions/github-script@v6
      with:
        script: |
          const diff = `${{ steps.diff.outputs.diff }}`;
          
          github.rest.issues.createComment({
            issue_number: context.issue.number,
            owner: context.repo.owner,
            repo: context.repo.repo,
            body: `## アーキテクチャへの影響分析\n\n${diff}`
          });
```

### スケジュールされたドキュメント更新

```yaml
name: 週次アーキテクチャレポート

on:
  schedule:
    - cron: '0 0 * * 0'  # 毎週日曜日の深夜0時
  workflow_dispatch:  # 手動トリガー

jobs:
  generate-report:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Rubyのセットアップ
      uses: ruby/setup-ruby@v1
      with:
        ruby-version: '3.1'
        bundler-cache: true
    
    - name: 包括的なレポートを生成
      run: |
        bundle exec rake flow_map:generate_all
        bundle exec rake flow_map:metrics > metrics.md
        
    - name: プルリクエストを作成
      uses: peter-evans/create-pull-request@v5
      with:
        commit-message: 'docs: アーキテクチャドキュメントを更新'
        title: '週次アーキテクチャドキュメント更新'
        body: |
          ## 自動アーキテクチャ更新
          
          このPRは現在のコードベースに基づいてアーキテクチャドキュメントを更新します。
          
          ### 生成されたファイル：
          - アーキテクチャ図
          - APIドキュメント
          - メトリクスレポート
        branch: docs/architecture-update
```

## GitLab CI

### 基本設定

`.gitlab-ci.yml`を作成：

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

### マージリクエスト統合

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
    expose_as: 'アーキテクチャ変更'
    paths:
      - architecture_diff.md
  only:
    - merge_requests
```

## CircleCI

### 基本設定

`.circleci/config.yml`を作成：

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
          name: アーキテクチャドキュメントを生成
          command: |
            bundle exec rake flow_map:generate_all
            
      - store_artifacts:
          path: doc/flow_maps
          destination: architecture-docs
          
      - run:
          name: メトリクスレポートを生成
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

### 比較を含む高度なワークフロー

```yaml
version: 2.1

jobs:
  architecture_analysis:
    docker:
      - image: cimg/ruby:3.1
    steps:
      - checkout
      - run:
          name: ベースブランチを取得
          command: |
            git fetch origin main:main
            
      - ruby/install-deps
      
      - run:
          name: アーキテクチャの変更を分析
          command: |
            # mainブランチを分析
            git checkout main
            bundle exec rake flow_map:analyze > main_architecture.json
            
            # 現在のブランチを分析
            git checkout $CIRCLE_BRANCH
            bundle exec rake flow_map:analyze > current_architecture.json
            
            # 比較を生成
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

### 基本パイプライン

`Jenkinsfile`を作成：

```groovy
pipeline {
    agent any
    
    stages {
        stage('セットアップ') {
            steps {
                script {
                    // Ruby依存関係をインストール
                    sh 'bundle install'
                }
            }
        }
        
        stage('アーキテクチャを分析') {
            steps {
                script {
                    sh 'bundle exec rake flow_map:analyze'
                    sh 'bundle exec rake flow_map:metrics > metrics.txt'
                }
            }
        }
        
        stage('ドキュメントを生成') {
            steps {
                script {
                    sh 'bundle exec rake flow_map:generate_all'
                }
            }
        }
        
        stage('結果をアーカイブ') {
            steps {
                archiveArtifacts artifacts: 'doc/flow_maps/**/*', fingerprint: true
                publishHTML([
                    allowMissing: false,
                    alwaysLinkToLastBuild: true,
                    keepAll: true,
                    reportDir: 'doc/flow_maps',
                    reportFiles: 'index.html',
                    reportName: 'アーキテクチャドキュメント'
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

### PR分析を含むマルチブランチパイプライン

```groovy
pipeline {
    agent any
    
    environment {
        CHANGE_TARGET = "${env.CHANGE_TARGET ?: 'main'}"
    }
    
    stages {
        stage('チェックアウト') {
            steps {
                checkout scm
                script {
                    if (env.CHANGE_ID) {
                        sh "git fetch origin ${env.CHANGE_TARGET}:${env.CHANGE_TARGET}"
                    }
                }
            }
        }
        
        stage('アーキテクチャ差分') {
            when {
                changeRequest()
            }
            steps {
                script {
                    // ベースブランチを分析
                    sh """
                        git checkout ${env.CHANGE_TARGET}
                        bundle exec rake flow_map:analyze > base_architecture.json
                    """
                    
                    // PRブランチを分析
                    sh """
                        git checkout ${env.GIT_COMMIT}
                        bundle exec rake flow_map:analyze > pr_architecture.json
                    """
                    
                    // 差分を生成
                    sh """
                        bundle exec rake flow_map:diff \
                            BASE=base_architecture.json \
                            CURRENT=pr_architecture.json \
                            FORMAT=html > architecture_diff.html
                    """
                }
            }
        }
        
        stage('結果を公開') {
            steps {
                publishHTML([
                    reportDir: '.',
                    reportFiles: 'architecture_diff.html',
                    reportName: 'アーキテクチャ変更'
                ])
                
                // GitHubを使用している場合はPRにコメント
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

## ベストプラクティス

### 1. 依存関係のキャッシュ

Rubyのgemをキャッシュしてビルドを高速化：

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

### 2. 分析の並列化

異なる分析を並列で実行：

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

### 3. リソース制限の設定

大規模なコードベースでのメモリ問題を防ぐ：

```ruby
# config/initializers/rails_flow_map.rb
RailsFlowMap.configure do |config|
  config.memory_limit = ENV.fetch('CI_MEMORY_LIMIT', '2GB')
  config.analysis_timeout = ENV.fetch('CI_TIMEOUT', '300').to_i.seconds
end
```

### 4. 条件付き生成

関連ファイルが変更された場合のみドキュメントを生成：

```yaml
# GitHub Actions
- name: 関連する変更をチェック
  id: changes
  uses: dorny/paths-filter@v2
  with:
    filters: |
      ruby:
        - 'app/**/*.rb'
        - 'lib/**/*.rb'
        - 'config/routes.rb'

- name: ドキュメントを生成
  if: steps.changes.outputs.ruby == 'true'
  run: bundle exec rake flow_map:generate_all
```

### 5. アーティファクト管理

履歴データの保存と比較：

```yaml
# 分析結果を保存
- uses: actions/upload-artifact@v3
  with:
    name: architecture-${{ github.sha }}
    path: architecture.json
    retention-days: 90

# 比較用にダウンロード
- uses: actions/download-artifact@v3
  with:
    name: architecture-${{ github.event.before }}
    path: previous/
```

## トラブルシューティング

### 一般的な問題

1. **メモリ不足**
   ```yaml
   # メモリ制限を増やす
   env:
     RAILS_FLOW_MAP_MEMORY_LIMIT: 4GB
   ```

2. **大規模リポジトリでのタイムアウト**
   ```yaml
   # タイムアウトを増やす
   timeout-minutes: 30
   ```

3. **依存関係の欠落**
   ```yaml
   # システム依存関係をインストール
   - run: apt-get update && apt-get install -y graphviz
   ```

4. **権限の問題**
   ```yaml
   # 書き込み権限を確保
   - run: chmod +x bundle exec rake flow_map:generate
   ```

### デバッグモード

トラブルシューティング用の詳細ログを有効化：

```yaml
env:
  RAILS_FLOW_MAP_LOG_LEVEL: debug
  RAILS_FLOW_MAP_VERBOSE: true
```

---

より多くの例と設定については、[examples directory](https://github.com/railsflowmap/rails-flow-map/tree/main/examples/ci_cd)を参照してください。