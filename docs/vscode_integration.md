# VS Code Integration for Rails Flow Map

This document describes how to integrate Rails Flow Map visualization into Visual Studio Code for a seamless development experience.

## Overview

Rails Flow Map can be integrated into VS Code to provide real-time visualization of your Rails application architecture directly within your editor. This integration helps developers understand code relationships, navigate between components, and visualize the impact of changes.

## Integration Options

### 1. VS Code Extension (rails-flow-map-vscode)

A dedicated VS Code extension that provides:

#### Features
- **Sidebar Panel**: Interactive flow diagram in the Explorer sidebar
- **CodeLens Integration**: Inline visualizations above classes and methods
- **Command Palette**: Quick access to all Rails Flow Map features
- **Real-time Updates**: Automatic refresh when files change
- **Navigation**: Click nodes to jump to source code
- **Hover Information**: Detailed tooltips showing relationships

#### Installation
```bash
# From VS Code Marketplace (future release)
ext install rails-flow-map-vscode

# Or install from VSIX
code --install-extension rails-flow-map-vscode-0.1.0.vsix
```

#### Usage
1. Open a Rails project in VS Code
2. Open the Rails Flow Map panel from the Activity Bar
3. Select visualization type (Mermaid, D3.js, etc.)
4. Click on nodes to navigate to source files

### 2. VS Code Tasks Integration

Configure VS Code tasks to generate visualizations on demand:

#### .vscode/tasks.json
```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Rails Flow Map: Generate All",
      "type": "shell",
      "command": "bundle exec rake rails_flow_map:export",
      "group": "build",
      "presentation": {
        "reveal": "silent"
      }
    },
    {
      "label": "Rails Flow Map: Interactive View",
      "type": "shell",
      "command": "bundle exec rake rails_flow_map:export FORMAT=d3js OUTPUT=.vscode/flow.html && open .vscode/flow.html",
      "group": "build"
    },
    {
      "label": "Rails Flow Map: Update Documentation",
      "type": "shell",
      "command": "bundle exec rake rails_flow_map:export FORMAT=mermaid OUTPUT=doc/flow.md",
      "group": "build"
    }
  ]
}
```

### 3. Custom VS Code Snippets

Add Rails Flow Map snippets for quick access:

#### .vscode/rails-flow-map.code-snippets
```json
{
  "Rails Flow Map: Analyze Current File": {
    "prefix": "rfm-analyze",
    "body": [
      "# Rails Flow Map Analysis",
      "# Run: bundle exec rails console",
      "require 'rails_flow_map'",
      "graph = RailsFlowMap.analyze",
      "RailsFlowMap.export(graph, format: :mermaid, output: 'analysis.md')"
    ],
    "description": "Generate flow map analysis"
  },
  "Rails Flow Map: Service Pattern": {
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
      "    ${0:# Implementation}",
      "  end",
      "end"
    ],
    "description": "Create a service with flow map annotations"
  }
}
```

### 4. Workspace Settings

Configure Rails Flow Map behavior in VS Code:

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

### 5. Integrated Terminal Commands

Add custom terminal commands for quick access:

#### .vscode/settings.json (additional)
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

## Development Workflow Integration

### 1. Pre-commit Hooks

Automatically update flow diagrams before commits:

#### .git/hooks/pre-commit
```bash
#!/bin/sh
# Update Rails Flow Map documentation
bundle exec rake rails_flow_map:export FORMAT=mermaid OUTPUT=doc/ARCHITECTURE.md
git add doc/ARCHITECTURE.md
```

### 2. Code Review Integration

Generate diffs for pull requests:

```bash
# In your PR template
rails_flow_map:diff FROM=main TO=HEAD FORMAT=mermaid
```

### 3. Debugging Support

Use flow maps during debugging sessions:

```ruby
# In VS Code Debug Console
require 'rails_flow_map'
graph = RailsFlowMap.analyze_endpoint('/api/users')
puts RailsFlowMap.export(graph, format: :text)
```

## Extension API (For Extension Developers)

### WebView Provider

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
    // Load D3.js visualization
    return `<!DOCTYPE html>
    <html>
      <head>
        <script src="https://d3js.org/d3.v7.min.js"></script>
      </head>
      <body>
        <div id="flow-map"></div>
        <script>
          // D3.js visualization code
        </script>
      </body>
    </html>`;
  }
}
```

### Language Server Protocol (LSP) Integration

```typescript
// Provide flow information via LSP
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

## Keyboard Shortcuts

Configure keyboard shortcuts for quick access:

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

## Status Bar Integration

Show current file's position in the application flow:

```typescript
// Status bar item showing relationships
const statusBarItem = vscode.window.createStatusBarItem(
  vscode.StatusBarAlignment.Right,
  100
);
statusBarItem.text = "$(circuit-board) 5 deps | 3 refs";
statusBarItem.tooltip = "Rails Flow Map: Click to see relationships";
statusBarItem.command = "rails-flow-map.showRelationships";
statusBarItem.show();
```

## Future Enhancements

1. **AI-Powered Suggestions**: Use flow analysis to suggest refactoring
2. **Test Coverage Overlay**: Show test coverage on flow diagrams
3. **Performance Metrics**: Display response times on routes
4. **Git History Integration**: Show how flows evolved over time
5. **Team Collaboration**: Share and annotate flow diagrams

## Resources

- [VS Code Extension API](https://code.visualstudio.com/api)
- [Rails Flow Map GitHub](https://github.com/your-org/rails-flow-map)
- [Extension Marketplace](https://marketplace.visualstudio.com/)

## Contributing

To contribute to the VS Code extension:

1. Fork the repository
2. Create your feature branch
3. Add tests for your changes
4. Submit a pull request

For questions or support, please open an issue on GitHub.