require 'spec_helper'
require 'stringio'

RSpec.describe RailsFlowMap::Logging do
  let(:log_output) { StringIO.new }
  let(:logger) { Logger.new(log_output) }

  before do
    # Use a test logger to capture output
    described_class.logger = logger
    # Clear any existing context
    Thread.current[:rails_flow_map_context] = nil
  end

  after do
    # Reset logger
    described_class.instance_variable_set(:@logger, nil)
    Thread.current[:rails_flow_map_context] = nil
  end

  describe '.logger' do
    it 'creates a default logger when none is set' do
      described_class.instance_variable_set(:@logger, nil)
      logger = described_class.logger
      
      expect(logger).to be_a(Logger)
      expect(logger.progname).to eq('RailsFlowMap')
    end

    it 'allows setting a custom logger' do
      custom_logger = Logger.new(STDOUT)
      described_class.logger = custom_logger
      
      expect(described_class.logger).to eq(custom_logger)
    end
  end

  describe '.log_error' do
    let(:error) { StandardError.new("Test error") }

    it 'logs error with context' do
      described_class.log_error(error, context: { operation: 'test' })
      
      log_content = log_output.string
      expect(log_content).to include('ERROR')
      expect(log_content).to include('StandardError: Test error')
      expect(log_content).to include('operation=test')
    end

    it 'logs backtrace in debug mode' do
      logger.level = Logger::DEBUG
      described_class.log_error(error, context: { operation: 'test' })
      
      log_content = log_output.string
      expect(log_content).to include('Backtrace:')
    end

    it 'respects custom log level' do
      described_class.log_error(error, level: :warn)
      
      log_content = log_output.string
      expect(log_content).to include('WARN')
    end
  end

  describe '.with_context' do
    it 'adds context to log messages' do
      described_class.with_context(formatter: 'MermaidFormatter') do
        described_class.logger.info("Test message")
      end
      
      log_content = log_output.string
      expect(log_content).to include('formatter=MermaidFormatter')
      expect(log_content).to include('Test message')
    end

    it 'merges with existing context' do
      described_class.with_context(operation: 'export') do
        described_class.with_context(formatter: 'MermaidFormatter') do
          described_class.logger.info("Test message")
        end
      end
      
      log_content = log_output.string
      expect(log_content).to include('operation=export')
      expect(log_content).to include('formatter=MermaidFormatter')
    end

    it 'restores previous context after block' do
      described_class.with_context(operation: 'export') do
        described_class.with_context(formatter: 'MermaidFormatter') do
          # Inner context
        end
        described_class.logger.info("Test message")
      end
      
      log_content = log_output.string
      expect(log_content).to include('operation=export')
      expect(log_content).not_to include('formatter=MermaidFormatter')
    end
  end

  describe '.log_performance' do
    it 'logs performance metrics' do
      described_class.log_performance('export', 1.234, nodes: 10)
      
      log_content = log_output.string
      expect(log_content).to include('Performance: export completed in 1.234s')
      expect(log_content).to include('operation=export')
      expect(log_content).to include('duration_seconds=1.234')
      expect(log_content).to include('nodes=10')
    end

    it 'respects log level for performance logging' do
      logger.level = Logger::WARN
      described_class.log_performance('export', 1.0)
      
      log_content = log_output.string
      expect(log_content).to be_empty
    end
  end

  describe '.log_security' do
    it 'logs security events' do
      described_class.log_security('XSS attempt blocked', severity: :high, details: { input: '<script>' })
      
      log_content = log_output.string
      expect(log_content).to include('WARN')
      expect(log_content).to include('SECURITY: XSS attempt blocked')
      expect(log_content).to include('severity=high')
      expect(log_content).to include('input=<script>')
    end

    it 'respects log level for security logging' do
      logger.level = Logger::ERROR
      described_class.log_security('Security event')
      
      log_content = log_output.string
      expect(log_content).to be_empty
    end
  end

  describe '.log_graph_analysis' do
    it 'logs graph analysis information' do
      described_class.log_graph_analysis('node_analysis', nodes: 50, edges: 30)
      
      log_content = log_output.string
      expect(log_content).to include('Graph Analysis: node_analysis')
      expect(log_content).to include('analysis_type=node_analysis')
      expect(log_content).to include('Graph metrics: nodes=50, edges=30')
    end

    it 'respects log level for graph analysis' do
      logger.level = Logger::INFO
      described_class.log_graph_analysis('analysis')
      
      log_content = log_output.string
      expect(log_content).to be_empty
    end
  end

  describe '.time_operation' do
    it 'times operation and logs performance' do
      result = described_class.time_operation('test_operation') do
        sleep(0.01)
        'test_result'
      end
      
      expect(result).to eq('test_result')
      
      log_content = log_output.string
      expect(log_content).to include('Performance: test_operation completed')
      expect(log_content).to include('operation=test_operation')
    end

    it 'logs errors and re-raises them' do
      expect do
        described_class.time_operation('failing_operation') do
          raise StandardError, 'Test error'
        end
      end.to raise_error(StandardError, 'Test error')
      
      log_content = log_output.string
      expect(log_content).to include('ERROR')
      expect(log_content).to include('operation=failing_operation')
    end

    it 'includes additional metrics' do
      described_class.time_operation('test_operation', nodes: 10) do
        'result'
      end
      
      log_content = log_output.string
      expect(log_content).to include('nodes=10')
    end
  end

  describe '.configure_for_environment' do
    it 'configures for development environment' do
      described_class.configure_for_environment(:development)
      
      expect(logger.level).to eq(Logger::DEBUG)
      expect(logger.formatter).to be_a(described_class::StructuredFormatter)
    end

    it 'configures for test environment' do
      described_class.configure_for_environment(:test)
      
      expect(logger.level).to eq(Logger::WARN)
      expect(logger.formatter).to be_a(Logger::Formatter)
    end

    it 'configures for production environment' do
      described_class.configure_for_environment(:production)
      
      expect(logger.level).to eq(Logger::INFO)
      expect(logger.formatter).to be_a(described_class::StructuredFormatter)
    end

    it 'applies custom options' do
      described_class.configure_for_environment(:development, level: Logger::ERROR)
      
      expect(logger.level).to eq(Logger::ERROR)
    end
  end

  describe 'StructuredFormatter' do
    let(:formatter) { described_class::StructuredFormatter.new }
    let(:time) { Time.parse('2023-01-01 12:00:00') }

    it 'formats log messages with context' do
      described_class.with_context(operation: 'test') do
        formatted = formatter.call('INFO', time, nil, 'Test message')
        
        expect(formatted).to include('[2023-01-01 12:00:00]')
        expect(formatted).to include('INFO')
        expect(formatted).to include('[operation=test]')
        expect(formatted).to include('Test message')
      end
    end

    it 'formats messages without context' do
      formatted = formatter.call('INFO', time, nil, 'Test message')
      
      expect(formatted).to include('[2023-01-01 12:00:00]')
      expect(formatted).to include('INFO')
      expect(formatted).to include('Test message')
      expect(formatted).not_to include('[')
    end
  end

  describe 'thread safety' do
    it 'maintains separate context per thread' do
      contexts = {}
      
      threads = 2.times.map do |i|
        Thread.new do
          described_class.with_context(thread_id: i) do
            sleep(0.01)
            contexts[i] = Thread.current[:rails_flow_map_context]
          end
        end
      end
      
      threads.each(&:join)
      
      expect(contexts[0][:thread_id]).to eq(0)
      expect(contexts[1][:thread_id]).to eq(1)
    end
  end
end