# Rails Flow Map サンプル

このディレクトリには、Rails Flow Mapの実用的なサンプルと使用パターンが含まれています。

## ファイル概要

- **`basic_usage.rb`** - 基本的な使用パターンと一般的な操作
- **`advanced_patterns.rb`** - 複雑なワークフロー、パフォーマンス最適化、統合パターン

## サンプルの実行

### 基本使用例

```bash
cd rails-flow-map
ruby examples/basic_usage.rb
```

これにより以下が実演されます：
- 基本的なグラフ分析とエクスポート
- 複数の出力形式
- ファイル出力操作
- 設定の使用
- エラーハンドリングパターン

### 高度なパターンの例

```bash
ruby examples/advanced_patterns.rb
```

これには以下が含まれます：
- 大規模アプリケーションのパフォーマンス最適化
- カスタム分析ワークフロー
- 複数グラフのバッチ処理
- 高度なフィルタリングとフォーカスエリア
- 統合パターン（CI/CD、ドキュメント、監視）
- カスタムフォーマッター設定
- 監視とロギング統合

## サンプルカテゴリ

### 🚀 はじめに
- 基本分析: `RailsFlowMap.analyze`
- 簡単なエクスポート: `RailsFlowMap.export(graph, format: :mermaid)`
- ファイル操作: 特定の場所への保存
- エラーハンドリング: 異なるエラータイプのキャッチと処理

### 🔧 設定
- グローバル設定のセットアップ
- 環境固有の設定
- パスの除外と包含
- パフォーマンスチューニングオプション

### 📊 出力形式
- **Mermaid**: GitHub対応図
- **PlantUML**: 詳細なUML図
- **D3.js**: インタラクティブ可視化
- **OpenAPI**: APIドキュメント
- **Sequence**: エンドポイントフロー図
- **ERD**: データベーススキーマ可視化
- **Metrics**: コード品質分析

### ⚡ パフォーマンス最適化
- 大規模アプリケーションの処理
- メモリ効率的な処理
- ストリーミングエクスポート
- バッチ操作
- キャッシュ戦略

### 🔗 統合パターン
- **CI/CD**: 自動ドキュメント生成
- **Gitワークフロー**: プリコミットフックとPRチェック
- **ドキュメント**: 自動ドキュメントサイト更新
- **監視**: パフォーマンスと使用状況の追跡

### 🎯 高度なフィルタリング
- コンポーネント固有の分析
- 複雑なグラフの深度制限
- フォーカスエリアと抽象化
- カスタムノード/エッジフィルタリング

## 実世界のシナリオ

### ドキュメントチーム
```ruby
# 包括的なドキュメントスイートを生成
def generate_team_docs
  graph = RailsFlowMap.analyze
  
  # ステークホルダー向け概要
  RailsFlowMap.export(graph, format: :mermaid, output: 'docs/overview.md')
  
  # 開発者向けインタラクティブ探索
  RailsFlowMap.export(graph, format: :d3js, output: 'docs/interactive.html')
  
  # フロントエンドチーム向けAPIドキュメント
  RailsFlowMap.export(graph, format: :openapi, output: 'docs/api.yaml')
end
```

### コードレビュープロセス
```ruby
# PR用のアーキテクチャ差分を生成
def architecture_diff_for_pr
  before = RailsFlowMap.analyze_at('main')
  after = RailsFlowMap.analyze
  
  diff = RailsFlowMap.diff(before, after, format: :mermaid)
  File.write('ARCHITECTURE_CHANGES.md', diff)
end
```

### パフォーマンス監視
```ruby
# 時間経過によるアーキテクチャメトリクスを追跡
def track_architecture_metrics
  graph = RailsFlowMap.analyze
  metrics = RailsFlowMap.export(graph, format: :metrics)
  
  # トレンド分析用にタイムスタンプ付きでメトリクスを保存
  timestamp = Time.current.strftime('%Y%m%d_%H%M%S')
  File.write("metrics/architecture_#{timestamp}.md", metrics)
end
```

## カスタムワークフロー

### マルチ環境分析
```ruby
environments = ['development', 'staging', 'production']
environments.each do |env|
  # 環境コンテキストを切り替え
  ENV['RAILS_ENV'] = env
  graph = RailsFlowMap.analyze
  
  RailsFlowMap.export(graph, 
    format: :metrics, 
    output: "docs/#{env}_metrics.md"
  )
end
```

### 増分ドキュメント
```ruby
# 変更されたコンポーネントのみを更新
def incremental_update
  last_update = File.mtime('docs/architecture.md')
  changed_files = Dir.glob('app/**/*.rb').select { |f| File.mtime(f) > last_update }
  
  if changed_files.any?
    graph = RailsFlowMap.analyze
    RailsFlowMap.export(graph, format: :mermaid, output: 'docs/architecture.md')
    puts "#{changed_files.size} 個の変更されたファイルのドキュメントを更新しました"
  end
end
```

## ヒントとベストプラクティス

### 📈 パフォーマンスのヒント
1. 不要なディレクトリをスキップするため `excluded_paths` を使用
2. 繰り返し操作にキャッシュを有効化
3. 大規模アプリケーションでストリーミングモードを使用
4. 複雑な可視化では深度を制限

### 🔒 セキュリティ考慮事項
1. パストラバーサルを防ぐため出力パスを検証
2. カスタムワークフローでユーザー入力をサニタイズ
3. 出力ファイルに適切なファイル権限を使用
4. 公開前に生成されたコンテンツをレビュー

### 🚀 CI/CD統合
1. マージ時に自動的にドキュメントを生成
2. PRでアーキテクチャの変更を検証
3. ドキュメントサイトを自動更新
4. ドキュメントの新鮮さを監視

### 📚 ドキュメント戦略
1. 異なる対象者向けに複数の形式を生成
2. 開発ワークフローの一部としてドキュメントを更新
3. 複雑なアーキテクチャにはインタラクティブ形式を使用
4. 歴史的なアーキテクチャのスナップショットを維持

## よくある問題のトラブルシューティング

### 高いメモリ使用量
```ruby
# 解決策: ストリーミングとバッチ処理を使用
RailsFlowMap.configure do |config|
  config.streaming_mode = true
  config.batch_size = 100
end
```

### 遅い分析
```ruby
# 解決策: 不要なパスを除外
RailsFlowMap.configure do |config|
  config.excluded_paths += ['vendor/', 'node_modules/', 'tmp/']
end
```

### 複雑な図
```ruby
# 解決策: フィルタリングと深度制限を使用
RailsFlowMap.export(graph, 
  format: :mermaid,
  max_depth: 3,
  focus_on: ['User', 'Post']
)
```

より詳細な例とパターンについては、メインの [USAGE_EXAMPLES_ja.md](../USAGE_EXAMPLES_ja.md) ファイルをご覧ください。