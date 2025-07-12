# Rails Flow Map VS Code 統合ガイド

このドキュメントでは、Rails Flow Mapの可視化機能をVisual Studio Codeに統合し、シームレスな開発体験を実現する方法について説明します。

## 概要

Rails Flow MapをVS Codeに統合することで、エディタ内でRailsアプリケーションのアーキテクチャをリアルタイムに可視化できます。この統合により、開発者はコードの関係性を理解し、コンポーネント間を簡単にナビゲートし、変更の影響を視覚的に確認できます。

## 統合オプション

### 1. VS Code拡張機能 (rails-flow-map-vscode)

専用のVS Code拡張機能は以下の機能を提供します：

#### 機能
- **サイドバーパネル**: エクスプローラーサイドバーでのインタラクティブなフロー図
- **CodeLens統合**: クラスやメソッドの上にインライン可視化
- **コマンドパレット**: すべてのRails Flow Map機能への素早いアクセス
- **リアルタイム更新**: ファイル変更時の自動更新
- **ナビゲーション**: ノードをクリックしてソースコードにジャンプ
- **ホバー情報**: 関係性を示す詳細なツールチップ

#### インストール
```bash
# VS Code Marketplaceから（将来リリース予定）
ext install rails-flow-map-vscode

# またはVSIXからインストール
code --install-extension rails-flow-map-vscode-0.1.0.vsix
```

#### 使用方法
1. VS CodeでRailsプロジェクトを開く
2. アクティビティバーからRails Flow Mapパネルを開く
3. 可視化タイプを選択（Mermaid、D3.jsなど）
4. ノードをクリックしてソースファイルに移動

### 2. VS Codeタスク統合

オンデマンドで可視化を生成するVS Codeタスクを設定：

#### .vscode/tasks.json
```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Rails Flow Map: すべて生成",
      "type": "shell",
      "command": "bundle exec rake rails_flow_map:export",
      "group": "build",
      "presentation": {
        "reveal": "silent"
      }
    },
    {
      "label": "Rails Flow Map: インタラクティブビュー",
      "type": "shell",
      "command": "bundle exec rake rails_flow_map:export FORMAT=d3js OUTPUT=.vscode/flow.html && open .vscode/flow.html",
      "group": "build"
    },
    {
      "label": "Rails Flow Map: ドキュメント更新",
      "type": "shell",
      "command": "bundle exec rake rails_flow_map:export FORMAT=mermaid OUTPUT=doc/flow.md",
      "group": "build"
    }
  ]
}
```

### 3. カスタムVS Codeスニペット

Rails Flow Mapの素早いアクセスのためのスニペットを追加：

#### .vscode/rails-flow-map.code-snippets
```json
{
  "Rails Flow Map: 現在のファイルを分析": {
    "prefix": "rfm-analyze",
    "body": [
      "# Rails Flow Map 分析",
      "# 実行: bundle exec rails console",
      "require 'rails_flow_map'",
      "graph = RailsFlowMap.analyze",
      "RailsFlowMap.export(graph, format: :mermaid, output: 'analysis.md')"
    ],
    "description": "フローマップ分析を生成"
  },
  "Rails Flow Map: サービスパターン": {
    "prefix": "rfm-service",
    "body": [
      "# @rails_flow_map service: true",
      "# @rails_flow_map calls: [${1:User}, ${2:Post}]",
      "class ${3:ServiceName}Service",
      "  def initialize(${4:params})",
      "    @${4:params} = ${4:params}",
      "  end",
      "",
      "  def call",
      "    ${0:# 実装}",
      "  end",
      "end"
    ],
    "description": "フローマップアノテーション付きサービスを作成"
  }
}
```

### 4. ワークスペース設定

VS CodeでのRails Flow Mapの動作を設定：

#### .vscode/settings.json
```json
{
  "rails-flow-map": {
    "autoRefresh": true,
    "refreshInterval": 5000,
    "defaultFormat": "mermaid",
    "includeTests": false,
    "theme": "dark",
    "layout": "hierarchical",
    "filters": {
      "hideRoutes": false,
      "hideServices": false,
      "hideCallbacks": true
    }
  },
  "files.associations": {
    "*.flow": "mermaid"
  },
  "files.watcherExclude": {
    "**/doc/flow_maps/**": false
  }
}
```

### 5. 統合ターミナルコマンド

素早いアクセスのためのカスタムターミナルコマンドを追加：

#### .vscode/settings.json (追加)
```json
{
  "terminal.integrated.env.osx": {
    "RAILS_FLOW_MAP_FORMAT": "mermaid"
  },
  "terminal.integrated.env.linux": {
    "RAILS_FLOW_MAP_FORMAT": "mermaid"
  },
  "terminal.integrated.shellIntegration.suggestEnabled": true,
  "terminal.integrated.commandsToSkipShell": [
    "rails-flow-map.generate",
    "rails-flow-map.open"
  ]
}
```

## 開発ワークフロー統合

### 1. Pre-commitフック

コミット前に自動的にフロー図を更新：

#### .git/hooks/pre-commit
```bash
#!/bin/sh
# Rails Flow Mapドキュメントを更新
bundle exec rake rails_flow_map:export FORMAT=mermaid OUTPUT=doc/ARCHITECTURE.md
git add doc/ARCHITECTURE.md
```

### 2. コードレビュー統合

プルリクエスト用の差分を生成：

```bash
# PRテンプレート内で
rails_flow_map:diff FROM=main TO=HEAD FORMAT=mermaid
```

### 3. デバッグサポート

デバッグセッション中のフローマップ使用：

```ruby
# VS Codeデバッグコンソールで
require 'rails_flow_map'
graph = RailsFlowMap.analyze_endpoint('/api/users')
puts RailsFlowMap.export(graph, format: :text)
```

## 拡張機能API（拡張機能開発者向け）

### WebViewプロバイダー

```typescript
import * as vscode from 'vscode';

export class RailsFlowMapProvider implements vscode.WebviewViewProvider {
  constructor(private readonly extensionUri: vscode.Uri) {}

  resolveWebviewView(
    webviewView: vscode.WebviewView,
    context: vscode.WebviewViewResolveContext,
    _token: vscode.CancellationToken
  ) {
    webviewView.webview.options = {
      enableScripts: true,
      localResourceRoots: [this.extensionUri]
    };

    webviewView.webview.html = this.getHtmlForWebview(webviewView.webview);
  }

  private getHtmlForWebview(webview: vscode.Webview) {
    // D3.js可視化を読み込む
    return `<!DOCTYPE html>
    <html>
      <head>
        <script src="https://d3js.org/d3.v7.min.js"></script>
      </head>
      <body>
        <div id="flow-map"></div>
        <script>
          // D3.js可視化コード
        </script>
      </body>
    </html>`;
  }
}
```

### Language Server Protocol (LSP) 統合

```typescript
// LSP経由でフロー情報を提供
connection.onRequest('rails-flow-map/getFlow', async (params) => {
  const { uri } = params;
  const flowData = await analyzeFile(uri);
  return {
    nodes: flowData.nodes,
    edges: flowData.edges,
    type: detectComponentType(uri)
  };
});
```

## キーボードショートカット

素早いアクセスのためのキーボードショートカットを設定：

#### keybindings.json
```json
[
  {
    "key": "ctrl+shift+f",
    "command": "rails-flow-map.showFlow",
    "when": "editorTextFocus && resourceExtname == .rb"
  },
  {
    "key": "ctrl+shift+g",
    "command": "rails-flow-map.generateDocs",
    "when": "workbenchState == folder"
  },
  {
    "key": "ctrl+shift+n",
    "command": "rails-flow-map.navigateToRelated",
    "when": "editorTextFocus && resourceExtname == .rb"
  }
]
```

## ステータスバー統合

現在のファイルのアプリケーションフロー内での位置を表示：

```typescript
// 関係性を表示するステータスバーアイテム
const statusBarItem = vscode.window.createStatusBarItem(
  vscode.StatusBarAlignment.Right,
  100
);
statusBarItem.text = "$(circuit-board) 5 依存 | 3 参照";
statusBarItem.tooltip = "Rails Flow Map: クリックして関係性を表示";
statusBarItem.command = "rails-flow-map.showRelationships";
statusBarItem.show();
```

## 今後の機能拡張

1. **AI駆動の提案**: フロー分析を使用してリファクタリングを提案
2. **テストカバレッジオーバーレイ**: フロー図上にテストカバレッジを表示
3. **パフォーマンスメトリクス**: ルート上にレスポンス時間を表示
4. **Git履歴統合**: フローの進化を時系列で表示
5. **チームコラボレーション**: フロー図の共有とアノテーション

## リソース

- [VS Code Extension API](https://code.visualstudio.com/api)
- [Rails Flow Map GitHub](https://github.com/your-org/rails-flow-map)
- [Extension Marketplace](https://marketplace.visualstudio.com/)

## 貢献方法

VS Code拡張機能に貢献するには：

1. リポジトリをフォーク
2. フィーチャーブランチを作成
3. 変更に対するテストを追加
4. プルリクエストを送信

質問やサポートについては、GitHubでissueを開いてください。