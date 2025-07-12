# CI/CD Integration Guide

This guide explains how to integrate Rails Flow Map into your continuous integration and deployment pipelines.

## Table of Contents

- [Overview](#overview)
- [GitHub Actions](#github-actions)
- [GitLab CI](#gitlab-ci)
- [CircleCI](#circleci)
- [Jenkins](#jenkins)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)

## Overview

Integrating Rails Flow Map into your CI/CD pipeline provides:

- **Automatic documentation updates** - Keep architecture docs in sync with code
- **PR/MR reviews** - Visualize architectural changes in pull requests
- **Quality gates** - Enforce architectural standards
- **Historical tracking** - Monitor architecture evolution over time

## GitHub Actions

### Basic Setup

Create `.github/workflows/rails-flow-map.yml`:

```yaml
name: Generate Architecture Documentation

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
    
    - name: Set up Ruby
      uses: ruby/setup-ruby@v1
      with:
        ruby-version: '3.1'
        bundler-cache: true
    
    - name: Generate architecture documentation
      run: |
        bundle exec rake flow_map:generate_all
        
    - name: Upload artifacts
      uses: actions/upload-artifact@v3
      with:
        name: architecture-docs
        path: doc/flow_maps/
```

### Advanced Configuration with PR Comments

```yaml
name: Architecture Analysis

on:
  pull_request:
    types: [opened, synchronize]

jobs:
  analyze-architecture:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
      with:
        fetch-depth: 0  # Full history for comparison
    
    - name: Checkout base branch
      run: |
        git fetch origin ${{ github.base_ref }}
        
    - name: Set up Ruby
      uses: ruby/setup-ruby@v1
      with:
        ruby-version: '3.1'
        bundler-cache: true
    
    - name: Generate architecture diff
      id: diff
      run: |
        # Analyze base branch
        git checkout ${{ github.base_ref }}
        bundle exec rake flow_map:analyze > base.json
        
        # Analyze PR branch
        git checkout ${{ github.head_ref }}
        bundle exec rake flow_map:analyze > pr.json
        
        # Generate diff
        bundle exec rake flow_map:diff BASE=base.json CURRENT=pr.json FORMAT=markdown > diff.md
        
        # Set output
        echo "diff<<EOF" >> $GITHUB_OUTPUT
        cat diff.md >> $GITHUB_OUTPUT
        echo "EOF" >> $GITHUB_OUTPUT
    
    - name: Comment PR
      uses: actions/github-script@v6
      with:
        script: |
          const diff = `${{ steps.diff.outputs.diff }}`;
          
          github.rest.issues.createComment({
            issue_number: context.issue.number,
            owner: context.repo.owner,
            repo: context.repo.repo,
            body: `## Architecture Impact Analysis\n\n${diff}`
          });
```

### Scheduled Documentation Updates

```yaml
name: Weekly Architecture Report

on:
  schedule:
    - cron: '0 0 * * 0'  # Every Sunday at midnight
  workflow_dispatch:  # Manual trigger

jobs:
  generate-report:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Set up Ruby
      uses: ruby/setup-ruby@v1
      with:
        ruby-version: '3.1'
        bundler-cache: true
    
    - name: Generate comprehensive report
      run: |
        bundle exec rake flow_map:generate_all
        bundle exec rake flow_map:metrics > metrics.md
        
    - name: Create pull request
      uses: peter-evans/create-pull-request@v5
      with:
        commit-message: 'docs: update architecture documentation'
        title: 'Weekly Architecture Documentation Update'
        body: |
          ## Automated Architecture Update
          
          This PR updates the architecture documentation based on the current codebase.
          
          ### Generated files:
          - Architecture diagrams
          - API documentation
          - Metrics report
        branch: docs/architecture-update
```

## GitLab CI

### Basic Setup

Create `.gitlab-ci.yml`:

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

### Merge Request Integration

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
    expose_as: 'Architecture Changes'
    paths:
      - architecture_diff.md
  only:
    - merge_requests
```

## CircleCI

### Basic Setup

Create `.circleci/config.yml`:

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
          name: Generate architecture documentation
          command: |
            bundle exec rake flow_map:generate_all
            
      - store_artifacts:
          path: doc/flow_maps
          destination: architecture-docs
          
      - run:
          name: Generate metrics report
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

### Advanced Workflow with Comparisons

```yaml
version: 2.1

jobs:
  architecture_analysis:
    docker:
      - image: cimg/ruby:3.1
    steps:
      - checkout
      - run:
          name: Fetch base branch
          command: |
            git fetch origin main:main
            
      - ruby/install-deps
      
      - run:
          name: Analyze architecture changes
          command: |
            # Analyze main branch
            git checkout main
            bundle exec rake flow_map:analyze > main_architecture.json
            
            # Analyze current branch
            git checkout $CIRCLE_BRANCH
            bundle exec rake flow_map:analyze > current_architecture.json
            
            # Generate comparison
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

### Basic Pipeline

Create `Jenkinsfile`:

```groovy
pipeline {
    agent any
    
    stages {
        stage('Setup') {
            steps {
                script {
                    // Install Ruby dependencies
                    sh 'bundle install'
                }
            }
        }
        
        stage('Analyze Architecture') {
            steps {
                script {
                    sh 'bundle exec rake flow_map:analyze'
                    sh 'bundle exec rake flow_map:metrics > metrics.txt'
                }
            }
        }
        
        stage('Generate Documentation') {
            steps {
                script {
                    sh 'bundle exec rake flow_map:generate_all'
                }
            }
        }
        
        stage('Archive Results') {
            steps {
                archiveArtifacts artifacts: 'doc/flow_maps/**/*', fingerprint: true
                publishHTML([
                    allowMissing: false,
                    alwaysLinkToLastBuild: true,
                    keepAll: true,
                    reportDir: 'doc/flow_maps',
                    reportFiles: 'index.html',
                    reportName: 'Architecture Documentation'
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

### Multibranch Pipeline with PR Analysis

```groovy
pipeline {
    agent any
    
    environment {
        CHANGE_TARGET = "${env.CHANGE_TARGET ?: 'main'}"
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
                script {
                    if (env.CHANGE_ID) {
                        sh "git fetch origin ${env.CHANGE_TARGET}:${env.CHANGE_TARGET}"
                    }
                }
            }
        }
        
        stage('Architecture Diff') {
            when {
                changeRequest()
            }
            steps {
                script {
                    // Analyze base branch
                    sh """
                        git checkout ${env.CHANGE_TARGET}
                        bundle exec rake flow_map:analyze > base_architecture.json
                    """
                    
                    // Analyze PR branch
                    sh """
                        git checkout ${env.GIT_COMMIT}
                        bundle exec rake flow_map:analyze > pr_architecture.json
                    """
                    
                    // Generate diff
                    sh """
                        bundle exec rake flow_map:diff \
                            BASE=base_architecture.json \
                            CURRENT=pr_architecture.json \
                            FORMAT=html > architecture_diff.html
                    """
                }
            }
        }
        
        stage('Publish Results') {
            steps {
                publishHTML([
                    reportDir: '.',
                    reportFiles: 'architecture_diff.html',
                    reportName: 'Architecture Changes'
                ])
                
                // Comment on PR if using GitHub
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

## Best Practices

### 1. Cache Dependencies

Speed up builds by caching Ruby gems:

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

### 2. Parallelize Analysis

Run different analyses in parallel:

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

### 3. Set Resource Limits

Prevent memory issues on large codebases:

```ruby
# config/initializers/rails_flow_map.rb
RailsFlowMap.configure do |config|
  config.memory_limit = ENV.fetch('CI_MEMORY_LIMIT', '2GB')
  config.analysis_timeout = ENV.fetch('CI_TIMEOUT', '300').to_i.seconds
end
```

### 4. Conditional Generation

Only generate docs when relevant files change:

```yaml
# GitHub Actions
- name: Check for relevant changes
  id: changes
  uses: dorny/paths-filter@v2
  with:
    filters: |
      ruby:
        - 'app/**/*.rb'
        - 'lib/**/*.rb'
        - 'config/routes.rb'

- name: Generate docs
  if: steps.changes.outputs.ruby == 'true'
  run: bundle exec rake flow_map:generate_all
```

### 5. Artifact Management

Store and compare historical data:

```yaml
# Store analysis results
- uses: actions/upload-artifact@v3
  with:
    name: architecture-${{ github.sha }}
    path: architecture.json
    retention-days: 90

# Download for comparison
- uses: actions/download-artifact@v3
  with:
    name: architecture-${{ github.event.before }}
    path: previous/
```

## Troubleshooting

### Common Issues

1. **Out of Memory**
   ```yaml
   # Increase memory limit
   env:
     RAILS_FLOW_MAP_MEMORY_LIMIT: 4GB
   ```

2. **Timeout on Large Repos**
   ```yaml
   # Increase timeout
   timeout-minutes: 30
   ```

3. **Missing Dependencies**
   ```yaml
   # Install system dependencies
   - run: apt-get update && apt-get install -y graphviz
   ```

4. **Permission Issues**
   ```yaml
   # Ensure write permissions
   - run: chmod +x bundle exec rake flow_map:generate
   ```

### Debug Mode

Enable verbose logging for troubleshooting:

```yaml
env:
  RAILS_FLOW_MAP_LOG_LEVEL: debug
  RAILS_FLOW_MAP_VERBOSE: true
```

---

For more examples and configurations, check the [examples directory](https://github.com/railsflowmap/rails-flow-map/tree/main/examples/ci_cd).