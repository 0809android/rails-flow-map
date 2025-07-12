#!/usr/bin/env ruby
# frozen_string_literal: true

# Test script for new Rails Flow Map features in blog_sample
# This script tests all the newly implemented improvements:
# - Error handling and logging
# - Security features
# - Enhanced functionality

# Setup paths
$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))
$LOAD_PATH.unshift(File.expand_path('lib', __dir__))
$LOAD_PATH.unshift(File.expand_path('blog_sample/lib', __dir__))

require 'rails_flow_map'
require 'stringio'
require 'fileutils'

# Try to load mock_rails if it exists
begin
  require 'mock_rails'
rescue LoadError
  # Create a minimal mock if not available
  module Rails
    def self.root
      Pathname.new(__dir__)
    end
    
    def self.env
      'test'
    end
  end
end

class NewFeaturesTest
  def self.run_all_tests
    puts "🧪 Rails Flow Map - 新機能テスト (blog_sample)"
    puts "=" * 60
    
    # Setup
    setup_environment
    
    # Run tests
    test_logging_functionality
    test_error_handling
    test_security_features
    test_enhanced_export_functionality
    test_performance_monitoring
    test_real_world_scenarios
    
    puts "\n✅ 全ての新機能テストが完了しました！"
  end

  private

  def self.setup_environment
    puts "\n🔧 環境セットアップ中..."
    
    # Configure Rails Flow Map with logging
    RailsFlowMap.configure do |config|
      config.output_directory = File.join(Dir.pwd, 'tmp', 'flow_maps')
      config.exclude_paths = ['tmp/', 'vendor/', 'spec/']
    end
    
    # Ensure output directory exists
    FileUtils.mkdir_p(RailsFlowMap.configuration.output_directory)
    
    puts "✓ 設定完了"
  end

  def self.test_logging_functionality
    puts "\n📊 ログ機能テスト"
    puts "-" * 30
    
    # Setup log capture
    log_output = StringIO.new
    RailsFlowMap::Logging.logger = Logger.new(log_output)
    RailsFlowMap::Logging.logger.level = Logger::DEBUG
    
    # Test basic logging
    RailsFlowMap::Logging.logger.info("テストメッセージ")
    
    # Test contextual logging
    RailsFlowMap::Logging.with_context(test: 'blog_sample') do
      RailsFlowMap::Logging.logger.info("コンテキスト付きログ")
    end
    
    # Test performance logging
    RailsFlowMap::Logging.log_performance('test_operation', 0.123, nodes: 10)
    
    # Test security logging
    RailsFlowMap::Logging.log_security('テストセキュリティイベント', severity: :medium)
    
    # Verify logs
    log_content = log_output.string
    puts "✓ 基本ログ: #{log_content.include?('テストメッセージ') ? '成功' : '失敗'}"
    puts "✓ コンテキストログ: #{log_content.include?('test=blog_sample') ? '成功' : '失敗'}"
    puts "✓ パフォーマンスログ: #{log_content.include?('Performance') ? '成功' : '失敗'}"
    puts "✓ セキュリティログ: #{log_content.include?('SECURITY') ? '成功' : '失敗'}"
  end

  def self.test_error_handling
    puts "\n🛡️ エラーハンドリングテスト"
    puts "-" * 30
    
    # Test 1: Invalid format error
    begin
      graph = create_blog_sample_graph
      RailsFlowMap.export(graph, format: :invalid_format)
      puts "✗ 無効フォーマットエラーテスト: 失敗（エラーが発生しなかった）"
    rescue RailsFlowMap::InvalidInputError => e
      puts "✓ 無効フォーマットエラーテスト: 成功"
      puts "  エラーコード: #{e.error_code}"
      puts "  カテゴリ: #{e.category}"
    rescue RailsFlowMap::FormatterError => e
      puts "✓ 無効フォーマットエラーテスト: 成功 (FormatterError)"
      puts "  エラーコード: #{e.error_code}"
      puts "  カテゴリ: #{e.category}"
    rescue => e
      puts "✗ 無効フォーマットエラーテスト: 予期しないエラー - #{e.class}: #{e.message}"
    end
    
    # Test 2: Invalid graph parameter
    begin
      RailsFlowMap.export("not a graph", format: :mermaid)
      puts "✗ 無効グラフパラメータテスト: 失敗"
    rescue RailsFlowMap::InvalidInputError => e
      puts "✓ 無効グラフパラメータテスト: 成功"
      puts "  コンテキスト: #{e.context.keys.join(', ')}"
    end
    
    # Test 3: User-friendly error messages
    test_error = RailsFlowMap::FileOperationError.new("ファイル操作エラー")
    friendly_message = RailsFlowMap::ErrorHandler.user_friendly_message(test_error)
    puts "✓ ユーザーフレンドリーメッセージ: #{friendly_message}"
  end

  def self.test_security_features
    puts "\n🔒 セキュリティ機能テスト"
    puts "-" * 30
    
    graph = create_blog_sample_graph
    
    # Test 1: Path traversal protection
    begin
      malicious_path = File.join('..', '..', 'etc', 'passwd')
      RailsFlowMap.export(graph, format: :mermaid, output: malicious_path)
      puts "✗ パストラバーサル保護: 失敗（攻撃が防がれなかった）"
    rescue RailsFlowMap::SecurityError => e
      puts "✓ パストラバーサル保護: 成功"
      puts "  検出された攻撃: #{e.context[:path]}"
    rescue RailsFlowMap::FileOperationError => e
      puts "✓ パストラバーサル保護: 成功 (ファイル操作エラーとして検出)"
      puts "  メッセージ: #{e.message}"
    end
    
    # Test 2: System directory protection
    begin
      system_path = '/etc/malicious_file.txt'
      RailsFlowMap.export(graph, format: :mermaid, output: system_path)
      puts "✗ システムディレクトリ保護: 失敗"
    rescue RailsFlowMap::SecurityError => e
      puts "✓ システムディレクトリ保護: 成功"
    rescue RailsFlowMap::FileOperationError => e
      puts "✓ システムディレクトリ保護: 成功 (ファイル操作エラーとして検出)"
    end
    
    # Test 3: XSS protection in content
    malicious_node = RailsFlowMap::FlowNode.new(
      id: 'malicious',
      name: '<script>alert("xss")</script>',
      type: :model
    )
    graph.add_node(malicious_node)
    
    d3js_output = RailsFlowMap.export(graph, format: :d3js)
    xss_protected = !d3js_output.match(/<script[^>]*>(?!.*JSON\.parse).*alert\(/i)
    puts "✓ XSS保護: #{xss_protected ? '成功' : '失敗'}"
  end

  def self.test_enhanced_export_functionality
    puts "\n🚀 強化されたエクスポート機能テスト"
    puts "-" * 30
    
    graph = create_blog_sample_graph
    output_dir = RailsFlowMap.configuration.output_directory
    
    # Test enhanced export with validation and logging
    formats_to_test = {
      mermaid: 'blog_architecture.md',
      d3js: 'blog_interactive.html',
      openapi: 'blog_api.yaml',
      sequence: 'blog_sequence.md',
      metrics: 'blog_metrics.md'
    }
    
    formats_to_test.each do |format, filename|
      begin
        output_path = File.join(output_dir, filename)
        result = RailsFlowMap.export(graph, format: format, output: output_path)
        
        if File.exist?(output_path)
          file_size = File.size(output_path)
          puts "✓ #{format}エクスポート: 成功 (#{file_size} bytes)"
        else
          puts "✗ #{format}エクスポート: ファイルが作成されませんでした"
        end
      rescue => e
        puts "✗ #{format}エクスポート: #{e.class.name} - #{e.message}"
      end
    end
  end

  def self.test_performance_monitoring
    puts "\n⚡ パフォーマンス監視テスト"
    puts "-" * 30
    
    # Setup performance logging
    log_output = StringIO.new
    RailsFlowMap::Logging.logger = Logger.new(log_output)
    
    graph = create_blog_sample_graph
    
    # Test time_operation functionality
    result = RailsFlowMap::Logging.time_operation('blog_export_test') do
      RailsFlowMap.export(graph, format: :mermaid)
    end
    
    log_content = log_output.string
    performance_logged = log_content.include?('Performance: blog_export_test completed')
    
    puts "✓ パフォーマンス監視: #{performance_logged ? '成功' : '失敗'}"
    
    if performance_logged
      # Extract duration from log
      duration_match = log_content.match(/completed in ([\d.]+)s/)
      if duration_match
        puts "  実行時間: #{duration_match[1]}秒"
      end
    end
  end

  def self.test_real_world_scenarios
    puts "\n🌍 実際のシナリオテスト"
    puts "-" * 30
    
    graph = create_blog_sample_graph
    
    # Scenario 1: API documentation generation
    puts "シナリオ1: API仕様書生成"
    api_spec = RailsFlowMap.export(graph, 
      format: :openapi,
      api_version: '1.0.0',
      title: 'Blog Sample API'
    )
    puts "✓ API仕様書生成: #{api_spec.length} 文字"
    
    # Scenario 2: Interactive documentation
    puts "シナリオ2: インタラクティブドキュメント生成"
    interactive_html = RailsFlowMap.export(graph, 
      format: :d3js,
      width: 1200,
      height: 800
    )
    puts "✓ インタラクティブHTML: #{interactive_html.length} 文字"
    
    # Scenario 3: Endpoint flow analysis
    puts "シナリオ3: エンドポイントフロー解析"
    sequence_diagram = RailsFlowMap.export(graph, 
      format: :sequence,
      endpoint: '/api/v1/posts',
      include_middleware: true,
      include_callbacks: true
    )
    puts "✓ シーケンス図: #{sequence_diagram.length} 文字"
    
    # Scenario 4: Architecture metrics
    puts "シナリオ4: アーキテクチャメトリクス"
    metrics_report = RailsFlowMap.export(graph, format: :metrics)
    puts "✓ メトリクスレポート: #{metrics_report.length} 文字"
  end

  def self.create_blog_sample_graph
    graph = RailsFlowMap::FlowGraph.new
    
    # Blog sample models
    models = [
      { id: 'user', name: 'User', associations: ['has_many :posts', 'has_many :comments'] },
      { id: 'post', name: 'Post', associations: ['belongs_to :user', 'has_many :comments'] },
      { id: 'comment', name: 'Comment', associations: ['belongs_to :user', 'belongs_to :post'] },
      { id: 'category', name: 'Category', associations: ['has_many :posts'] },
      { id: 'tag', name: 'Tag', associations: ['has_many :post_tags'] },
      { id: 'like', name: 'Like', associations: ['belongs_to :user', 'belongs_to :post'] }
    ]
    
    models.each do |model_data|
      node = RailsFlowMap::FlowNode.new(
        id: model_data[:id],
        name: model_data[:name],
        type: :model,
        attributes: { associations: model_data[:associations] }
      )
      graph.add_node(node)
    end
    
    # Controllers
    controllers = [
      { id: 'users_controller', name: 'Api::V1::UsersController', actions: ['index', 'show', 'create'] },
      { id: 'posts_controller', name: 'Api::V1::PostsController', actions: ['index', 'show', 'create'] },
      { id: 'comments_controller', name: 'Api::V1::CommentsController', actions: ['create', 'destroy'] }
    ]
    
    controllers.each do |controller_data|
      node = RailsFlowMap::FlowNode.new(
        id: controller_data[:id],
        name: controller_data[:name],
        type: :controller,
        attributes: { actions: controller_data[:actions] }
      )
      graph.add_node(node)
    end
    
    # Services
    services = [
      { id: 'user_service', name: 'UserService' },
      { id: 'post_service', name: 'PostService' },
      { id: 'comment_service', name: 'CommentService' }
    ]
    
    services.each do |service_data|
      node = RailsFlowMap::FlowNode.new(
        id: service_data[:id],
        name: service_data[:name],
        type: :service
      )
      graph.add_node(node)
    end
    
    # Routes
    routes = [
      { 
        id: 'users_index_route', 
        name: 'GET /api/v1/users', 
        path: '/api/v1/users', 
        verb: 'GET',
        controller: 'api/v1/users',
        action: 'index'
      },
      { 
        id: 'posts_index_route', 
        name: 'GET /api/v1/posts', 
        path: '/api/v1/posts', 
        verb: 'GET',
        controller: 'api/v1/posts',
        action: 'index'
      }
    ]
    
    routes.each do |route_data|
      node = RailsFlowMap::FlowNode.new(
        id: route_data[:id],
        name: route_data[:name],
        type: :route,
        attributes: route_data.reject { |k, v| [:id, :name].include?(k) }
      )
      graph.add_node(node)
    end
    
    # Add relationships
    relationships = [
      # Model relationships
      ['post', 'user', :belongs_to],
      ['comment', 'user', :belongs_to],
      ['comment', 'post', :belongs_to],
      ['like', 'user', :belongs_to],
      ['like', 'post', :belongs_to],
      
      # Controller to model relationships
      ['users_controller', 'user', :uses_model],
      ['posts_controller', 'post', :uses_model],
      ['comments_controller', 'comment', :uses_model],
      
      # Controller to service relationships
      ['users_controller', 'user_service', :uses_service],
      ['posts_controller', 'post_service', :uses_service],
      ['comments_controller', 'comment_service', :uses_service],
      
      # Route to controller relationships
      ['users_index_route', 'users_controller', :routes_to],
      ['posts_index_route', 'posts_controller', :routes_to]
    ]
    
    relationships.each do |from, to, type|
      edge = RailsFlowMap::FlowEdge.new(from: from, to: to, type: type)
      graph.add_edge(edge)
    end
    
    graph
  end
end

# Run the tests
if __FILE__ == $0
  NewFeaturesTest.run_all_tests
end