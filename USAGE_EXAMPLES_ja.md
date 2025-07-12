# Rails Flow Map - 使用例

このドキュメントは、Rails Flow Mapを効果的に使用するための包括的な例を提供します。

## 目次

1. [基本的な使用方法](#基本的な使用方法)
2. [高度な分析](#高度な分析)
3. [様々な出力形式](#様々な出力形式)
4. [ワークフロー統合](#ワークフロー統合)
5. [設定オプション](#設定オプション)
6. [パフォーマンス最適化](#パフォーマンス最適化)
7. [トラブルシューティング](#トラブルシューティング)
8. [ベストプラクティス](#ベストプラクティス)

## 基本的な使用方法

### クイックスタート

```ruby
# 1. アプリケーション全体の基本的なフローマップを生成
graph = RailsFlowMap.analyze
result = RailsFlowMap.export(graph, format: :mermaid, output: 'docs/architecture.md')

# 2. 特定のコンポーネントのみを分析
graph = RailsFlowMap.analyze(models: true, controllers: false)
result = RailsFlowMap.export(graph, format: :plantuml, output: 'docs/models.puml')

# 3. インタラクティブな可視化を作成
graph = RailsFlowMap.analyze
RailsFlowMap.export(graph, format: :d3js, output: 'public/architecture.html')
```

### Rakeタスクの使用

```bash
# すべての可視化を生成
rake flow_map:generate

# 特定の形式を生成
rake flow_map:generate FORMAT=mermaid OUTPUT=docs/flow.md

# 特定のエンドポイントを分析
rake flow_map:endpoint ENDPOINT=/api/v1/users FORMAT=sequence
```

## 高度な分析

### エンドポイント固有の分析

```ruby
# 特定のAPIエンドポイントのフローを分析
graph = RailsFlowMap.analyze_endpoint('/api/v1/users')

# エンドポイントのシーケンス図を生成
sequence = RailsFlowMap.export(graph, 
  format: :sequence, 
  endpoint: '/api/v1/users',
  include_middleware: true,
  include_callbacks: true,
  include_validations: true
)

puts sequence
```

### 異なるバージョンの比較

```ruby
# 現在のバージョンと以前のバージョンを比較
before_graph = RailsFlowMap.analyze_at('v1.0.0')  # Gitタグ/ブランチ
after_graph = RailsFlowMap.analyze                # 現在の状態

# 差分可視化を生成
diff_html = RailsFlowMap.diff(before_graph, after_graph, format: :html)
File.write('docs/architecture_changes.html', diff_html)

# Mermaid形式で差分を生成
diff_md = RailsFlowMap.diff(before_graph, after_graph, format: :mermaid)
File.write('docs/architecture_diff.md', diff_md)
```

### カスタム設定

```ruby
# プロジェクト用にRails Flow Mapを設定
RailsFlowMap.configure do |config|
  config.include_models = true
  config.include_controllers = true
  config.include_routes = true
  config.include_services = true
  config.output_dir = 'doc/flow_maps'
  config.excluded_paths = ['tmp/', 'vendor/', 'spec/']
end

# 設定済みの設定を使用
graph = RailsFlowMap.analyze
```

## 様々な出力形式

### 1. Mermaid図（GitHub対応）

```ruby
graph = RailsFlowMap.analyze

# 基本的なMermaid図
mermaid = RailsFlowMap.export(graph, format: :mermaid)

# カスタムスタイリングオプション付き
mermaid = RailsFlowMap.export(graph, 
  format: :mermaid,
  theme: 'dark',
  show_attributes: true,
  max_depth: 3
)

File.write('README_architecture.md', <<~MARKDOWN)
  # アプリケーションアーキテクチャ

  ```mermaid
  #{mermaid}
  ```
MARKDOWN
```

### 2. PlantUML図

```ruby
# 詳細なドキュメント用のPlantUMLを生成
plantuml = RailsFlowMap.export(graph, 
  format: :plantuml,
  include_methods: true,
  show_associations: true
)

File.write('docs/detailed_models.puml', plantuml)

# PlantUMLサーバーまたはローカルインストールで使用
# plantuml -tpng docs/detailed_models.puml
```

### 3. インタラクティブD3.js可視化

```ruby
# フィルタリングとズーム機能付きのインタラクティブHTML
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

### 4. APIドキュメント（OpenAPI）

```ruby
# ルートからOpenAPI仕様を生成
api_spec = RailsFlowMap.export(graph, 
  format: :openapi,
  api_version: '1.0.0',
  title: 'My API Documentation',
  description: 'Rails Flow Mapから自動生成されたAPIドキュメント'
)

File.write('docs/api_spec.yaml', api_spec)

# Swagger UIまたは他のOpenAPIツールで使用
```

### 5. エンドポイントのシーケンス図

```ruby
# 特定のエンドポイントの詳細なシーケンス図
sequence = RailsFlowMap.export(graph, 
  format: :sequence,
  endpoint: '/api/v1/posts',
  include_middleware: true,
  include_callbacks: true,
  include_validations: true,
  include_database: true
)

File.write('docs/post_creation_flow.md', <<~MARKDOWN)
  # 投稿作成フロー

  #{sequence}
MARKDOWN
```

### 6. メトリクスと分析

```ruby
# 包括的なメトリクスレポートを生成
metrics = RailsFlowMap.export(graph, 
  format: :metrics,
  include_complexity: true,
  include_coupling: true,
  include_recommendations: true
)

File.write('docs/architecture_metrics.md', metrics)
```

## ワークフロー統合

### GitHub Actions統合

`.github/workflows/architecture_docs.yml`を作成:

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
        ruby-version: 3.1
        bundler-cache: true
    
    - name: アーキテクチャドキュメントを生成
      run: |
        bundle exec rake flow_map:generate_all
        
    - name: 変更をチェック
      run: |
        if [ -n "$(git status --porcelain docs/)" ]; then
          echo "アーキテクチャドキュメントに変更があります"
          echo "::set-output name=changes::true"
        fi
      id: check_changes
    
    - name: 変更をコミット
      if: steps.check_changes.outputs.changes == 'true'
      run: |
        git config --local user.email "action@github.com"
        git config --local user.name "GitHub Action"
        git add docs/
        git commit -m "📊 アーキテクチャドキュメントを更新 [skip ci]"
        git push
```

### Pre-commitフック

`.git/hooks/pre-commit`を作成:

```bash
#!/bin/bash

# レビュー用のアーキテクチャ差分を生成
if [ -f "Gemfile" ] && bundle exec rake flow_map:diff > /dev/null 2>&1; then
    echo "✅ レビュー用アーキテクチャ差分を生成しました"
else
    echo "⚠️  アーキテクチャ差分を生成できませんでした"
fi
```

### VS Code統合

`.vscode/tasks.json`に追加:

```json
{
    "version": "2.0.0",
    "tasks": [
        {
            "label": "アーキテクチャドキュメント生成",
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
            "label": "エンドポイント分析",
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
            "description": "エンドポイントパスを入力",
            "default": "/api/v1/users",
            "type": "promptString"
        }
    ]
}
```

## 設定オプション

### グローバル設定

```ruby
# config/initializers/rails_flow_map.rb
RailsFlowMap.configure do |config|
  # 分析オプション
  config.include_models = true
  config.include_controllers = true
  config.include_routes = true
  config.include_services = true
  config.include_jobs = true
  config.include_mailers = true
  
  # 出力オプション
  config.output_dir = Rails.root.join('doc', 'flow_maps')
  config.auto_generate = Rails.env.development?
  
  # 除外設定
  config.excluded_paths = [
    'tmp/',
    'vendor/',
    'spec/',
    'test/',
    'node_modules/'
  ]
  
  # パフォーマンス
  config.max_file_size = 1.megabyte
  config.analysis_timeout = 30.seconds
  
  # セキュリティ
  config.allow_system_paths = false
  config.sanitize_output = true
end
```

### 環境固有の設定

```ruby
# 環境ごとの異なる設定
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

## パフォーマンス最適化

### 大規模アプリケーション

```ruby
# 大規模アプリケーションの場合、段階的に分析
def generate_architecture_docs
  # 1. まずコアモデルを分析
  models_graph = RailsFlowMap.analyze(
    models: true, 
    controllers: false, 
    routes: false
  )
  RailsFlowMap.export(models_graph, 
    format: :mermaid, 
    output: 'docs/models_overview.md'
  )
  
  # 2. APIコントローラーを別途分析
  api_graph = RailsFlowMap.analyze_controllers(
    pattern: 'app/controllers/api/**/*_controller.rb'
  )
  RailsFlowMap.export(api_graph, 
    format: :openapi, 
    output: 'docs/api_spec.yaml'
  )
  
  # 3. メトリクスレポートを生成
  full_graph = RailsFlowMap.analyze
  RailsFlowMap.export(full_graph, 
    format: :metrics, 
    output: 'docs/metrics.md'
  )
end
```

### 結果のキャッシング

```ruby
# 分析結果をキャッシュ
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

## トラブルシューティング

### 一般的な問題と解決策

#### 1. 大規模アプリケーションでのメモリ使用量

```ruby
# 問題：高いメモリ使用量
# 解決策：ストリーミングまたは段階的分析を使用

RailsFlowMap.configure do |config|
  config.streaming_mode = true
  config.batch_size = 100
  config.memory_limit = 512.megabytes
end

# またはチャンクで分析
%w[models controllers services].each do |component|
  graph = RailsFlowMap.analyze(component.to_sym => true)
  RailsFlowMap.export(graph, 
    format: :mermaid, 
    output: "docs/#{component}.md"
  )
end
```

#### 2. 分析パフォーマンスが遅い

```ruby
# 問題：分析が遅い
# 解決策：不要なファイルを除外し、キャッシングを使用

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

#### 3. 依存関係の欠落

```ruby
# 問題：関連付けや関係が欠落している
# 解決策：すべての関連ファイルが含まれていることを確認

graph = RailsFlowMap.analyze(
  models: true,
  controllers: true,
  routes: true,
  services: true,
  jobs: true,
  mailers: true
)

# 欠落している関係をチェック
puts "ノード数: #{graph.nodes.count}"
puts "エッジ数: #{graph.edges.count}"
```

#### 4. 出力形式の問題

```ruby
# 問題：生成された図が複雑すぎる
# 解決策：フィルタリングと深さ制限を使用

RailsFlowMap.export(graph, 
  format: :mermaid,
  max_depth: 2,
  exclude_types: [:job, :mailer],
  focus_on: ['User', 'Post', 'Comment']
)
```

## ベストプラクティス

### 1. ドキュメントワークフロー

```ruby
# 包括的なドキュメント生成スクリプトを作成
class DocumentationGenerator
  def self.run
    puts "アーキテクチャドキュメントを生成中..."
    
    # 1. アプリケーション全体の概要
    generate_overview
    
    # 2. APIドキュメント
    generate_api_docs
    
    # 3. データベーススキーマ可視化
    generate_schema_docs
    
    # 4. メトリクスと分析
    generate_metrics
    
    puts "ドキュメントの生成が完了しました！"
  end
  
  private
  
  def self.generate_overview
    graph = RailsFlowMap.analyze
    
    # GitHub README用のMermaid
    mermaid = RailsFlowMap.export(graph, format: :mermaid)
    update_readme_with_architecture(mermaid)
    
    # 詳細な探索用のインタラクティブHTML
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

### 2. チームコラボレーション

```ruby
# チーム固有のビューを作成
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

### 3. コードレビュー統合

```ruby
# コードレビュー用の差分を生成
class CodeReviewHelper
  def self.generate_architecture_diff(base_branch = 'main')
    # 現在の状態を保存
    after_graph = RailsFlowMap.analyze
    
    # ベースブランチをチェックアウトして分析
    system("git stash")
    system("git checkout #{base_branch}")
    before_graph = RailsFlowMap.analyze
    system("git checkout -")
    system("git stash pop")
    
    # 差分を生成
    diff = RailsFlowMap.diff(before_graph, after_graph, format: :mermaid)
    
    File.write('ARCHITECTURE_CHANGES.md', <<~MARKDOWN)
      # アーキテクチャの変更

      このドキュメントは、このPRでのアーキテクチャの変更を示しています。
      
      #{diff}
      
      ## 概要
      
      - **追加**: #{(after_graph.nodes.keys - before_graph.nodes.keys).count} コンポーネント
      - **変更**: #{detect_modifications(before_graph, after_graph).count} コンポーネント
      - **削除**: #{(before_graph.nodes.keys - after_graph.nodes.keys).count} コンポーネント
    MARKDOWN
  end
end
```

### 4. 継続的ドキュメント

```ruby
# デプロイスクリプトに追加
namespace :deploy do
  desc "アーキテクチャドキュメントを更新"
  task :update_docs do
    puts "アーキテクチャドキュメントを更新中..."
    
    graph = RailsFlowMap.analyze
    
    # パブリックドキュメントを更新
    RailsFlowMap.export(graph, 
      format: :d3js, 
      output: Rails.root.join('public', 'architecture.html')
    )
    
    # APIドキュメントを更新
    RailsFlowMap.export(graph, 
      format: :openapi, 
      output: Rails.root.join('public', 'api_docs.yaml')
    )
    
    puts "ドキュメントの更新が完了しました！"
  end
end

# Capistrano deploy.rbに追加
after 'deploy:migrate', 'deploy:update_docs'
```

---

この包括的なガイドは、Rails Flow Mapを開発ワークフローで最大限に活用するのに役立つはずです。より高度な使用方法やカスタマイズオプションについては、APIドキュメントとソースコードを参照してください。