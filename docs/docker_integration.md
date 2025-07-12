# Docker Integration Guide

This guide explains how to use Rails Flow Map with Docker and containerized Rails applications.

## Table of Contents

- [Overview](#overview)
- [Basic Docker Setup](#basic-docker-setup)
- [Docker Compose Integration](#docker-compose-integration)
- [Multi-stage Builds](#multi-stage-builds)
- [Development Workflow](#development-workflow)
- [Production Deployment](#production-deployment)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)

## Overview

Using Rails Flow Map with Docker provides:

- **Consistent environment** - Same analysis results across different systems
- **Easy setup** - No need to install Ruby/Rails locally
- **CI/CD friendly** - Seamless integration with containerized pipelines
- **Isolation** - Keep your analysis tools separate from your application

## Basic Docker Setup

### Dockerfile for Rails Flow Map

Create a `Dockerfile` in your Rails project:

```dockerfile
# Base image with Ruby
FROM ruby:3.1-slim

# Install dependencies
RUN apt-get update -qq && \
    apt-get install -y \
    build-essential \
    git \
    nodejs \
    graphviz \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy Gemfile
COPY Gemfile Gemfile.lock ./

# Install gems
RUN bundle config set --local deployment 'true' && \
    bundle config set --local without 'development test' && \
    bundle install

# Copy application code
COPY . .

# Add Rails Flow Map to the Gemfile if not already present
RUN if ! grep -q "rails-flow-map" Gemfile; then \
      echo "gem 'rails-flow-map'" >> Gemfile && \
      bundle install; \
    fi

# Create output directory
RUN mkdir -p /app/doc/flow_maps

# Default command
CMD ["bundle", "exec", "rake", "flow_map:generate_all"]
```

### Building and Running

```bash
# Build the Docker image
docker build -t rails-flow-analyzer .

# Run analysis
docker run -v $(pwd)/doc:/app/doc rails-flow-analyzer

# Run specific task
docker run -v $(pwd)/doc:/app/doc rails-flow-analyzer \
  bundle exec rake flow_map:generate FORMAT=mermaid
```

## Docker Compose Integration

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

Specialized Dockerfile for Rails Flow Map:

```dockerfile
FROM ruby:3.1-slim

# Install minimal dependencies
RUN apt-get update -qq && \
    apt-get install -y \
    build-essential \
    git \
    graphviz \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy only necessary files
COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

# Install Rails Flow Map
RUN gem install rails-flow-map

# Create output directory
RUN mkdir -p /app/doc/flow_maps

# Set default command
CMD ["bundle", "exec", "rake", "flow_map:generate_all"]
```

### Running with Docker Compose

```bash
# Generate documentation
docker-compose run --rm flow_map

# Generate specific format
docker-compose run --rm flow_map bundle exec rake flow_map:generate FORMAT=d3js

# Watch mode (if implemented)
docker-compose up flow_map
```

## Multi-stage Builds

### Optimized Dockerfile

```dockerfile
# Stage 1: Dependencies
FROM ruby:3.1-slim AS dependencies

RUN apt-get update -qq && \
    apt-get install -y build-essential git

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle config set --local deployment 'true' && \
    bundle install --jobs 4

# Stage 2: Analysis
FROM ruby:3.1-slim AS analyzer

# Install runtime dependencies only
RUN apt-get update -qq && \
    apt-get install -y graphviz && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy gems from dependencies stage
COPY --from=dependencies /usr/local/bundle /usr/local/bundle

# Copy application code
COPY . .

# Install Rails Flow Map
RUN gem install rails-flow-map

# Create output directory
RUN mkdir -p /app/doc/flow_maps

# Run analysis
RUN bundle exec rake flow_map:generate_all

# Stage 3: Final output
FROM scratch AS output

# Copy only the generated documentation
COPY --from=analyzer /app/doc/flow_maps /doc/flow_maps
```

### Building Multi-stage

```bash
# Build and extract documentation
docker build --target output -o ./doc .

# Or use BuildKit
DOCKER_BUILDKIT=1 docker build --output type=local,dest=./doc .
```

## Development Workflow

### Live Reload Setup

Create a development-specific compose file:

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

### Usage

```bash
# Start development environment
docker-compose -f docker-compose.dev.yml up

# View generated docs at http://localhost:8080
```

## Production Deployment

### Production Dockerfile

```dockerfile
FROM ruby:3.1-slim AS production

# Install production dependencies only
RUN apt-get update -qq && \
    apt-get install -y \
    graphviz \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy pre-built gems
COPY vendor/bundle vendor/bundle
COPY Gemfile Gemfile.lock ./

# Copy application code
COPY . .

# Configure bundler for production
RUN bundle config set --local deployment 'true' && \
    bundle config set --local path 'vendor/bundle' && \
    bundle config set --local without 'development test'

# Install Rails Flow Map if needed
RUN bundle add rails-flow-map --skip-install && \
    bundle install

# Generate documentation at build time
RUN bundle exec rake flow_map:generate_all

# Serve documentation with a lightweight web server
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

        # Cache static assets
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }
}
```

## Best Practices

### 1. Optimize Image Size

```dockerfile
# Use slim images
FROM ruby:3.1-slim

# Remove package manager cache
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Use multi-stage builds
FROM ruby:3.1-slim AS builder
# Build stage...

FROM ruby:3.1-slim AS runtime
# Runtime stage with minimal dependencies
```

### 2. Cache Dependencies

```dockerfile
# Copy Gemfile first for better caching
COPY Gemfile Gemfile.lock ./
RUN bundle install

# Then copy application code
COPY . .
```

### 3. Security Considerations

```dockerfile
# Run as non-root user
RUN useradd -m -u 1000 railsflow
USER railsflow

# Use read-only filesystem where possible
FROM nginx:alpine
COPY --from=builder /app/doc/flow_maps /usr/share/nginx/html:ro
```

### 4. Environment Variables

```dockerfile
# Allow configuration via environment
ENV RAILS_FLOW_MAP_OUTPUT_DIR=/app/output
ENV RAILS_FLOW_MAP_FORMAT=mermaid
ENV RAILS_FLOW_MAP_MEMORY_LIMIT=1GB

# Use in commands
CMD bundle exec rake flow_map:generate \
    OUTPUT_DIR=$RAILS_FLOW_MAP_OUTPUT_DIR \
    FORMAT=$RAILS_FLOW_MAP_FORMAT
```

### 5. Volume Management

```yaml
# docker-compose.yml
services:
  flow_map:
    volumes:
      # Source code (read-only)
      - .:/app:ro
      # Output directory (read-write)
      - ./doc/flow_maps:/app/doc/flow_maps
      # Gem cache (for faster rebuilds)
      - gem_cache:/usr/local/bundle
```

## Troubleshooting

### Common Issues

1. **Permission Denied**
   ```bash
   # Fix ownership issues
   docker run --rm -v $(pwd):/app rails-flow-analyzer \
     chown -R $(id -u):$(id -g) /app/doc
   ```

2. **Out of Memory**
   ```yaml
   # Increase memory limits
   services:
     flow_map:
       deploy:
         resources:
           limits:
             memory: 2G
   ```

3. **Missing Dependencies**
   ```dockerfile
   # Install additional system packages
   RUN apt-get update && apt-get install -y \
       libpq-dev \
       libxml2-dev \
       libxslt-dev
   ```

4. **Slow Builds**
   ```dockerfile
   # Use BuildKit for better caching
   # syntax=docker/dockerfile:1
   FROM ruby:3.1-slim
   
   # Mount cache for package downloads
   RUN --mount=type=cache,target=/var/cache/apt \
       apt-get update && apt-get install -y build-essential
   ```

### Debug Mode

```dockerfile
# Add debug tools
RUN apt-get install -y \
    vim \
    less \
    procps

# Enable verbose logging
ENV RAILS_FLOW_MAP_LOG_LEVEL=debug

# Use interactive shell for debugging
CMD ["/bin/bash"]
```

### Container Logs

```bash
# View logs
docker logs -f container_name

# Debug with shell
docker run -it --rm -v $(pwd):/app rails-flow-analyzer /bin/bash

# Inside container
bundle exec rake flow_map:generate --trace
```

---

For more Docker examples and configurations, check the [examples directory](https://github.com/railsflowmap/rails-flow-map/tree/main/examples/docker).