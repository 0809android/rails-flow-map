# Docker統合ガイド

このガイドでは、Dockerおよびコンテナ化されたRailsアプリケーションでRails Flow Mapを使用する方法を説明します。

## 目次

- [概要](#概要)
- [基本的なDockerセットアップ](#基本的なdockerセットアップ)
- [Docker Compose統合](#docker-compose統合)
- [マルチステージビルド](#マルチステージビルド)
- [開発ワークフロー](#開発ワークフロー)
- [本番デプロイメント](#本番デプロイメント)
- [ベストプラクティス](#ベストプラクティス)
- [トラブルシューティング](#トラブルシューティング)

## 概要

DockerでRails Flow Mapを使用することで以下が実現できます：

- **一貫した環境** - 異なるシステム間で同じ分析結果
- **簡単なセットアップ** - ローカルにRuby/Railsをインストール不要
- **CI/CDフレンドリー** - コンテナ化されたパイプラインとのシームレスな統合
- **分離** - 分析ツールをアプリケーションから分離

## 基本的なDockerセットアップ

### Rails Flow Map用のDockerfile

Railsプロジェクトに`Dockerfile`を作成：

```dockerfile
# Rubyベースイメージ
FROM ruby:3.1-slim

# 依存関係をインストール
RUN apt-get update -qq && \
    apt-get install -y \
    build-essential \
    git \
    nodejs \
    graphviz \
    && rm -rf /var/lib/apt/lists/*

# 作業ディレクトリを設定
WORKDIR /app

# Gemfileをコピー
COPY Gemfile Gemfile.lock ./

# gemをインストール
RUN bundle config set --local deployment 'true' && \
    bundle config set --local without 'development test' && \
    bundle install

# アプリケーションコードをコピー
COPY . .

# Rails Flow MapがGemfileにない場合は追加
RUN if ! grep -q "rails-flow-map" Gemfile; then \
      echo "gem 'rails-flow-map'" >> Gemfile && \
      bundle install; \
    fi

# 出力ディレクトリを作成
RUN mkdir -p /app/doc/flow_maps

# デフォルトコマンド
CMD ["bundle", "exec", "rake", "flow_map:generate_all"]
```

### ビルドと実行

```bash
# Dockerイメージをビルド
docker build -t rails-flow-analyzer .

# 分析を実行
docker run -v $(pwd)/doc:/app/doc rails-flow-analyzer

# 特定のタスクを実行
docker run -v $(pwd)/doc:/app/doc rails-flow-analyzer \
  bundle exec rake flow_map:generate FORMAT=mermaid
```

## Docker Compose統合

### docker-compose.yml

```yaml
version: '3.8'

services:
  app:
    build: .
    volumes:
      - .:/app
      - bundle_cache:/usr/local/bundle
    environment:
      - RAILS_ENV=development
    command: bundle exec rails server -b 0.0.0.0
    ports:
      - "3000:3000"

  flow_map:
    build:
      context: .
      dockerfile: Dockerfile.flowmap
    volumes:
      - .:/app
      - ./doc/flow_maps:/app/doc/flow_maps
    environment:
      - RAILS_ENV=development
    command: bundle exec rake flow_map:watch

volumes:
  bundle_cache:
```

### Dockerfile.flowmap

Rails Flow Map専用のDockerfile：

```dockerfile
FROM ruby:3.1-slim

# 最小限の依存関係をインストール
RUN apt-get update -qq && \
    apt-get install -y \
    build-essential \
    git \
    graphviz \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 必要なファイルのみコピー
COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

# Rails Flow Mapをインストール
RUN gem install rails-flow-map

# 出力ディレクトリを作成
RUN mkdir -p /app/doc/flow_maps

# デフォルトコマンドを設定
CMD ["bundle", "exec", "rake", "flow_map:generate_all"]
```

### Docker Composeで実行

```bash
# ドキュメントを生成
docker-compose run --rm flow_map

# 特定の形式を生成
docker-compose run --rm flow_map bundle exec rake flow_map:generate FORMAT=d3js

# ウォッチモード（実装されている場合）
docker-compose up flow_map
```

## マルチステージビルド

### 最適化されたDockerfile

```dockerfile
# ステージ1: 依存関係
FROM ruby:3.1-slim AS dependencies

RUN apt-get update -qq && \
    apt-get install -y build-essential git

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle config set --local deployment 'true' && \
    bundle install --jobs 4

# ステージ2: 分析
FROM ruby:3.1-slim AS analyzer

# ランタイム依存関係のみインストール
RUN apt-get update -qq && \
    apt-get install -y graphviz && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 依存関係ステージからgemをコピー
COPY --from=dependencies /usr/local/bundle /usr/local/bundle

# アプリケーションコードをコピー
COPY . .

# Rails Flow Mapをインストール
RUN gem install rails-flow-map

# 出力ディレクトリを作成
RUN mkdir -p /app/doc/flow_maps

# 分析を実行
RUN bundle exec rake flow_map:generate_all

# ステージ3: 最終出力
FROM scratch AS output

# 生成されたドキュメントのみコピー
COPY --from=analyzer /app/doc/flow_maps /doc/flow_maps
```

### マルチステージビルド

```bash
# ビルドしてドキュメントを抽出
docker build --target output -o ./doc .

# またはBuildKitを使用
DOCKER_BUILDKIT=1 docker build --output type=local,dest=./doc .
```

## 開発ワークフロー

### ライブリロードセットアップ

開発専用のcomposeファイルを作成：

```yaml
# docker-compose.dev.yml
version: '3.8'

services:
  flow_map_dev:
    build:
      context: .
      dockerfile: Dockerfile.flowmap
      args:
        - INSTALL_DEV_DEPS=true
    volumes:
      - .:/app
      - ./doc/flow_maps:/app/doc/flow_maps
      - bundle_cache:/usr/local/bundle
    environment:
      - RAILS_ENV=development
      - RAILS_FLOW_MAP_WATCH=true
    command: |
      sh -c "
        while true; do
          bundle exec rake flow_map:generate_all
          sleep 30
        done
      "
    
  flow_map_ui:
    image: nginx:alpine
    volumes:
      - ./doc/flow_maps:/usr/share/nginx/html:ro
    ports:
      - "8080:80"
    depends_on:
      - flow_map_dev

volumes:
  bundle_cache:
```

### 使用方法

```bash
# 開発環境を起動
docker-compose -f docker-compose.dev.yml up

# 生成されたドキュメントを http://localhost:8080 で表示
```

## 本番デプロイメント

### 本番用Dockerfile

```dockerfile
FROM ruby:3.1-slim AS production

# 本番依存関係のみインストール
RUN apt-get update -qq && \
    apt-get install -y \
    graphviz \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# プリビルドされたgemをコピー
COPY vendor/bundle vendor/bundle
COPY Gemfile Gemfile.lock ./

# アプリケーションコードをコピー
COPY . .

# 本番用にbundlerを設定
RUN bundle config set --local deployment 'true' && \
    bundle config set --local path 'vendor/bundle' && \
    bundle config set --local without 'development test'

# 必要に応じてRails Flow Mapをインストール
RUN bundle add rails-flow-map --skip-install && \
    bundle install

# ビルド時にドキュメントを生成
RUN bundle exec rake flow_map:generate_all

# 軽量Webサーバーでドキュメントを提供
FROM nginx:alpine

COPY --from=production /app/doc/flow_maps /usr/share/nginx/html
COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
```

### nginx.conf

```nginx
events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    server {
        listen 80;
        server_name localhost;

        root /usr/share/nginx/html;
        index index.html;

        location / {
            try_files $uri $uri/ /index.html;
        }

        # 静的アセットをキャッシュ
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }
}
```

## ベストプラクティス

### 1. イメージサイズの最適化

```dockerfile
# slimイメージを使用
FROM ruby:3.1-slim

# パッケージマネージャーのキャッシュを削除
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# マルチステージビルドを使用
FROM ruby:3.1-slim AS builder
# ビルドステージ...

FROM ruby:3.1-slim AS runtime
# 最小限の依存関係でランタイムステージ
```

### 2. 依存関係のキャッシュ

```dockerfile
# より良いキャッシングのためGemfileを先にコピー
COPY Gemfile Gemfile.lock ./
RUN bundle install

# その後アプリケーションコードをコピー
COPY . .
```

### 3. セキュリティの考慮事項

```dockerfile
# 非rootユーザーとして実行
RUN useradd -m -u 1000 railsflow
USER railsflow

# 可能な限り読み取り専用ファイルシステムを使用
FROM nginx:alpine
COPY --from=builder /app/doc/flow_maps /usr/share/nginx/html:ro
```

### 4. 環境変数

```dockerfile
# 環境変数による設定を許可
ENV RAILS_FLOW_MAP_OUTPUT_DIR=/app/output
ENV RAILS_FLOW_MAP_FORMAT=mermaid
ENV RAILS_FLOW_MAP_MEMORY_LIMIT=1GB

# コマンドで使用
CMD bundle exec rake flow_map:generate \
    OUTPUT_DIR=$RAILS_FLOW_MAP_OUTPUT_DIR \
    FORMAT=$RAILS_FLOW_MAP_FORMAT
```

### 5. ボリューム管理

```yaml
# docker-compose.yml
services:
  flow_map:
    volumes:
      # ソースコード（読み取り専用）
      - .:/app:ro
      # 出力ディレクトリ（読み書き可能）
      - ./doc/flow_maps:/app/doc/flow_maps
      # gemキャッシュ（より高速な再ビルド用）
      - gem_cache:/usr/local/bundle
```

## トラブルシューティング

### 一般的な問題

1. **権限が拒否される**
   ```bash
   # 所有権の問題を修正
   docker run --rm -v $(pwd):/app rails-flow-analyzer \
     chown -R $(id -u):$(id -g) /app/doc
   ```

2. **メモリ不足**
   ```yaml
   # メモリ制限を増やす
   services:
     flow_map:
       deploy:
         resources:
           limits:
             memory: 2G
   ```

3. **依存関係の欠落**
   ```dockerfile
   # 追加のシステムパッケージをインストール
   RUN apt-get update && apt-get install -y \
       libpq-dev \
       libxml2-dev \
       libxslt-dev
   ```

4. **ビルドが遅い**
   ```dockerfile
   # より良いキャッシングのためBuildKitを使用
   # syntax=docker/dockerfile:1
   FROM ruby:3.1-slim
   
   # パッケージダウンロード用のキャッシュをマウント
   RUN --mount=type=cache,target=/var/cache/apt \
       apt-get update && apt-get install -y build-essential
   ```

### デバッグモード

```dockerfile
# デバッグツールを追加
RUN apt-get install -y \
    vim \
    less \
    procps

# 詳細ログを有効化
ENV RAILS_FLOW_MAP_LOG_LEVEL=debug

# デバッグ用にインタラクティブシェルを使用
CMD ["/bin/bash"]
```

### コンテナログ

```bash
# ログを表示
docker logs -f container_name

# シェルでデバッグ
docker run -it --rm -v $(pwd):/app rails-flow-analyzer /bin/bash

# コンテナ内で
bundle exec rake flow_map:generate --trace
```

---

より多くのDocker例と設定については、[examples directory](https://github.com/railsflowmap/rails-flow-map/tree/main/examples/docker)を参照してください。