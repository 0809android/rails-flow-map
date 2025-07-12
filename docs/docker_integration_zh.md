# Docker 集成指南

本指南说明如何在 Docker 和容器化的 Rails 应用程序中使用 Rails Flow Map。

## 目录

- [概述](#概述)
- [基本 Docker 设置](#基本-docker-设置)
- [Docker Compose 集成](#docker-compose-集成)
- [多阶段构建](#多阶段构建)
- [开发工作流](#开发工作流)
- [生产部署](#生产部署)
- [最佳实践](#最佳实践)
- [故障排除](#故障排除)

## 概述

在 Docker 中使用 Rails Flow Map 可以提供：

- **一致的环境** - 不同系统间相同的分析结果
- **轻松设置** - 无需本地安装 Ruby/Rails
- **CI/CD 友好** - 与容器化管道无缝集成
- **隔离性** - 将分析工具与应用程序分离

## 基本 Docker 设置

### Rails Flow Map 的 Dockerfile

在您的 Rails 项目中创建 `Dockerfile`：

```dockerfile
# 带有 Ruby 的基础镜像
FROM ruby:3.1-slim

# 安装依赖
RUN apt-get update -qq && \
    apt-get install -y \
    build-essential \
    git \
    nodejs \
    graphviz \
    && rm -rf /var/lib/apt/lists/*

# 设置工作目录
WORKDIR /app

# 复制 Gemfile
COPY Gemfile Gemfile.lock ./

# 安装 gems
RUN bundle config set --local deployment 'true' && \
    bundle config set --local without 'development test' && \
    bundle install

# 复制应用程序代码
COPY . .

# 如果 Gemfile 中没有 Rails Flow Map，则添加
RUN if ! grep -q "rails-flow-map" Gemfile; then \
      echo "gem 'rails-flow-map'" >> Gemfile && \
      bundle install; \
    fi

# 创建输出目录
RUN mkdir -p /app/doc/flow_maps

# 默认命令
CMD ["bundle", "exec", "rake", "flow_map:generate_all"]
```

### 构建和运行

```bash
# 构建 Docker 镜像
docker build -t rails-flow-analyzer .

# 运行分析
docker run -v $(pwd)/doc:/app/doc rails-flow-analyzer

# 运行特定任务
docker run -v $(pwd)/doc:/app/doc rails-flow-analyzer \
  bundle exec rake flow_map:generate FORMAT=mermaid
```

## Docker Compose 集成

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

专门用于 Rails Flow Map 的 Dockerfile：

```dockerfile
FROM ruby:3.1-slim

# 安装最小依赖
RUN apt-get update -qq && \
    apt-get install -y \
    build-essential \
    git \
    graphviz \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 仅复制必要文件
COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

# 安装 Rails Flow Map
RUN gem install rails-flow-map

# 创建输出目录
RUN mkdir -p /app/doc/flow_maps

# 设置默认命令
CMD ["bundle", "exec", "rake", "flow_map:generate_all"]
```

### 使用 Docker Compose 运行

```bash
# 生成文档
docker-compose run --rm flow_map

# 生成特定格式
docker-compose run --rm flow_map bundle exec rake flow_map:generate FORMAT=d3js

# 监视模式（如果已实现）
docker-compose up flow_map
```

## 多阶段构建

### 优化的 Dockerfile

```dockerfile
# 阶段 1：依赖项
FROM ruby:3.1-slim AS dependencies

RUN apt-get update -qq && \
    apt-get install -y build-essential git

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle config set --local deployment 'true' && \
    bundle install --jobs 4

# 阶段 2：分析
FROM ruby:3.1-slim AS analyzer

# 仅安装运行时依赖
RUN apt-get update -qq && \
    apt-get install -y graphviz && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 从依赖阶段复制 gems
COPY --from=dependencies /usr/local/bundle /usr/local/bundle

# 复制应用程序代码
COPY . .

# 安装 Rails Flow Map
RUN gem install rails-flow-map

# 创建输出目录
RUN mkdir -p /app/doc/flow_maps

# 运行分析
RUN bundle exec rake flow_map:generate_all

# 阶段 3：最终输出
FROM scratch AS output

# 仅复制生成的文档
COPY --from=analyzer /app/doc/flow_maps /doc/flow_maps
```

### 构建多阶段

```bash
# 构建并提取文档
docker build --target output -o ./doc .

# 或使用 BuildKit
DOCKER_BUILDKIT=1 docker build --output type=local,dest=./doc .
```

## 开发工作流

### 实时重载设置

创建开发专用的 compose 文件：

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
# 启动开发环境
docker-compose -f docker-compose.dev.yml up

# 在 http://localhost:8080 查看生成的文档
```

## 生产部署

### 生产 Dockerfile

```dockerfile
FROM ruby:3.1-slim AS production

# 仅安装生产依赖
RUN apt-get update -qq && \
    apt-get install -y \
    graphviz \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 复制预构建的 gems
COPY vendor/bundle vendor/bundle
COPY Gemfile Gemfile.lock ./

# 复制应用程序代码
COPY . .

# 为生产配置 bundler
RUN bundle config set --local deployment 'true' && \
    bundle config set --local path 'vendor/bundle' && \
    bundle config set --local without 'development test'

# 如需要则安装 Rails Flow Map
RUN bundle add rails-flow-map --skip-install && \
    bundle install

# 在构建时生成文档
RUN bundle exec rake flow_map:generate_all

# 使用轻量级 Web 服务器提供文档
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

        # 缓存静态资源
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }
}
```

## 最佳实践

### 1. 优化镜像大小

```dockerfile
# 使用 slim 镜像
FROM ruby:3.1-slim

# 删除包管理器缓存
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# 使用多阶段构建
FROM ruby:3.1-slim AS builder
# 构建阶段...

FROM ruby:3.1-slim AS runtime
# 带有最小依赖的运行时阶段
```

### 2. 缓存依赖项

```dockerfile
# 先复制 Gemfile 以获得更好的缓存
COPY Gemfile Gemfile.lock ./
RUN bundle install

# 然后复制应用程序代码
COPY . .
```

### 3. 安全考虑

```dockerfile
# 以非 root 用户运行
RUN useradd -m -u 1000 railsflow
USER railsflow

# 尽可能使用只读文件系统
FROM nginx:alpine
COPY --from=builder /app/doc/flow_maps /usr/share/nginx/html:ro
```

### 4. 环境变量

```dockerfile
# 允许通过环境进行配置
ENV RAILS_FLOW_MAP_OUTPUT_DIR=/app/output
ENV RAILS_FLOW_MAP_FORMAT=mermaid
ENV RAILS_FLOW_MAP_MEMORY_LIMIT=1GB

# 在命令中使用
CMD bundle exec rake flow_map:generate \
    OUTPUT_DIR=$RAILS_FLOW_MAP_OUTPUT_DIR \
    FORMAT=$RAILS_FLOW_MAP_FORMAT
```

### 5. 卷管理

```yaml
# docker-compose.yml
services:
  flow_map:
    volumes:
      # 源代码（只读）
      - .:/app:ro
      # 输出目录（读写）
      - ./doc/flow_maps:/app/doc/flow_maps
      # Gem 缓存（用于更快的重建）
      - gem_cache:/usr/local/bundle
```

## 故障排除

### 常见问题

1. **权限被拒绝**
   ```bash
   # 修复所有权问题
   docker run --rm -v $(pwd):/app rails-flow-analyzer \
     chown -R $(id -u):$(id -g) /app/doc
   ```

2. **内存不足**
   ```yaml
   # 增加内存限制
   services:
     flow_map:
       deploy:
         resources:
           limits:
             memory: 2G
   ```

3. **缺少依赖项**
   ```dockerfile
   # 安装额外的系统包
   RUN apt-get update && apt-get install -y \
       libpq-dev \
       libxml2-dev \
       libxslt-dev
   ```

4. **构建缓慢**
   ```dockerfile
   # 使用 BuildKit 获得更好的缓存
   # syntax=docker/dockerfile:1
   FROM ruby:3.1-slim
   
   # 为包下载挂载缓存
   RUN --mount=type=cache,target=/var/cache/apt \
       apt-get update && apt-get install -y build-essential
   ```

### 调试模式

```dockerfile
# 添加调试工具
RUN apt-get install -y \
    vim \
    less \
    procps

# 启用详细日志记录
ENV RAILS_FLOW_MAP_LOG_LEVEL=debug

# 使用交互式 shell 进行调试
CMD ["/bin/bash"]
```

### 容器日志

```bash
# 查看日志
docker logs -f container_name

# 使用 shell 调试
docker run -it --rm -v $(pwd):/app rails-flow-analyzer /bin/bash

# 在容器内
bundle exec rake flow_map:generate --trace
```

---

有关更多 Docker 示例和配置，请查看 [examples directory](https://github.com/railsflowmap/rails-flow-map/tree/main/examples/docker)。