# Rails Flow Map - クイックリファレンス

Rails Flow Mapの最も一般的な操作のクイックリファレンスです。

## インストール & セットアップ

```bash
# Gemfileに追加
gem 'rails-flow-map'

# インストール
bundle install

# イニシャライザーを生成
rails generate rails_flow_map:install
```

## 基本コマンド

### Ruby/Railsコンソール

```ruby
# 基本的な分析
graph = RailsFlowMap.analyze
result = RailsFlowMap.export(graph, format: :mermaid)

# ファイルに保存
RailsFlowMap.export(graph, format: :mermaid, output: 'docs/architecture.md')

# 異なる形式
RailsFlowMap.export(graph, format: :plantuml, output: 'docs/models.puml')
RailsFlowMap.export(graph, format: :d3js, output: 'public/interactive.html')
RailsFlowMap.export(graph, format: :openapi, output: 'docs/api.yaml')
```

### Rakeタスク

```bash
# すべての形式を生成
rake flow_map:generate

# 特定の形式
rake flow_map:generate FORMAT=mermaid OUTPUT=docs/flow.md

# エンドポイント分析
rake flow_map:endpoint ENDPOINT=/api/v1/users FORMAT=sequence

# バージョン比較
rake flow_map:diff BEFORE=v1.0.0 AFTER=HEAD FORMAT=html
```

## 形式別クイックリファレンス

| 形式 | 用途 | 出力 |
|--------|----------|---------|
| `:mermaid` | GitHub README、ドキュメント | Mermaid図付きMarkdown |
| `:plantuml` | 詳細なUML図 | PlantUMLコード |
| `:d3js` | インタラクティブ探索 | D3.js可視化付きHTML |
| `:openapi` | APIドキュメント | OpenAPI仕様のYAML |
| `:sequence` | エンドポイントフロー分析 | Mermaidシーケンス図 |
| `:erd` | データベーススキーマ | テキストベースERD |
| `:metrics` | コード品質分析 | Markdownメトリクスレポート |
| `:graphviz` | ネットワーク図 | Graphviz用DOTファイル |

## 一般的なパターン

### GitHubドキュメント

```ruby
# README.md用
graph = RailsFlowMap.analyze
mermaid = RailsFlowMap.export(graph, format: :mermaid)

# README.mdに追加:
# ```mermaid
# #{mermaid}
# ```
```

### APIドキュメント

```ruby
# OpenAPI仕様を生成
graph = RailsFlowMap.analyze
api_spec = RailsFlowMap.export(graph, 
  format: :openapi,
  api_version: '1.0.0',
  title: 'My API'
)
```

### エンドポイント分析

```ruby
# 詳細なエンドポイントフロー
sequence = RailsFlowMap.export(graph, 
  format: :sequence,
  endpoint: '/api/v1/users',
  include_middleware: true,
  include_callbacks: true
)
```

### バージョン比較

```ruby
# 前後の比較
before = RailsFlowMap.analyze_at('v1.0.0')
after = RailsFlowMap.analyze
diff = RailsFlowMap.diff(before, after, format: :html)
```

## 設定のクイックセットアップ

```ruby
# config/initializers/rails_flow_map.rb
RailsFlowMap.configure do |config|
  config.output_dir = 'doc/flow_maps'
  config.excluded_paths = ['vendor/', 'tmp/']
  config.include_models = true
  config.include_controllers = true
end
```

## エラーハンドリング

```ruby
begin
  graph = RailsFlowMap.analyze
  result = RailsFlowMap.export(graph, format: :mermaid, output: 'docs/flow.md')
rescue RailsFlowMap::SecurityError => e
  puts "セキュリティエラー: #{e.message}"
rescue RailsFlowMap::FileOperationError => e
  puts "ファイルエラー: #{e.message}"
rescue RailsFlowMap::Error => e
  puts "一般エラー: #{e.message}"
end
```

## パフォーマンスのコツ

```ruby
# 大規模アプリケーション - 部分的に分析
models_graph = RailsFlowMap.analyze(models: true, controllers: false)
controllers_graph = RailsFlowMap.analyze(models: false, controllers: true)

# 繰り返し操作にキャッシュを使用
RailsFlowMap.configure do |config|
  config.enable_caching = true
  config.cache_ttl = 1.hour
end
```

## トラブルシューティング

| 問題 | 解決策 |
|-------|----------|
| 高いメモリ使用量 | 設定で `streaming_mode: true` を使用 |
| 遅い分析 | `excluded_paths` にパスを追加 |
| 関係の欠落 | すべての関連コンポーネントタイプを含める |
| 複雑な図 | `max_depth` とフィルタリングオプションを使用 |
| 権限エラー | ファイル/ディレクトリの権限を確認 |
| 空の出力 | Railsアプリの構造を確認 |

## VS Code統合

`.vscode/tasks.json`に追加:

```json
{
    "label": "アーキテクチャドキュメントを生成",
    "type": "shell",
    "command": "bundle exec rake flow_map:generate_all"
}
```

## GitHub Actions

```yaml
- name: ドキュメントを生成
  run: bundle exec rake flow_map:generate_all
```

## 便利なスニペット

### すべての形式を生成

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
    puts "#{output}を生成しました"
  end
end
```

### チーム固有のビュー

```ruby
# バックエンドチーム
backend_graph = RailsFlowMap.analyze(
  models: true, 
  controllers: true, 
  services: true
)

# フロントエンドチーム
api_spec = RailsFlowMap.export(graph, format: :openapi)

# DevOpsチーム
metrics = RailsFlowMap.export(graph, format: :metrics)
```