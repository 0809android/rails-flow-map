require 'spec_helper'

RSpec.describe RailsFlowMap::Error do
  describe '.new' do
    it 'creates error with message and defaults' do
      error = described_class.new("Test error")
      
      expect(error.message).to eq("Test error")
      expect(error.context).to eq({})
      expect(error.error_code).to eq("error")
      expect(error.category).to eq(:general)
    end

    it 'creates error with custom attributes' do
      error = described_class.new(
        "Test error",
        context: { operation: 'test' },
        error_code: 'TEST001',
        category: :validation
      )
      
      expect(error.context).to eq({ operation: 'test' })
      expect(error.error_code).to eq('TEST001')
      expect(error.category).to eq(:validation)
    end
  end

  describe '#to_h' do
    it 'returns complete error information' do
      error = described_class.new(
        "Test error",
        context: { operation: 'test' },
        error_code: 'TEST001',
        category: :validation
      )
      
      result = error.to_h
      
      expect(result[:error_class]).to eq('RailsFlowMap::Error')
      expect(result[:message]).to eq('Test error')
      expect(result[:error_code]).to eq('TEST001')
      expect(result[:category]).to eq(:validation)
      expect(result[:context]).to eq({ operation: 'test' })
      expect(result[:backtrace]).to be_an(Array)
    end
  end

  describe '#to_json' do
    it 'returns JSON representation' do
      error = described_class.new("Test error", context: { operation: 'test' })
      json_result = error.to_json
      
      expect(json_result).to be_a(String)
      
      parsed = JSON.parse(json_result)
      expect(parsed['message']).to eq('Test error')
      expect(parsed['context']['operation']).to eq('test')
    end
  end
end

RSpec.describe RailsFlowMap::GraphParseError do
  it 'has parsing category' do
    error = described_class.new("Parse failed")
    expect(error.category).to eq(:parsing)
  end
end

RSpec.describe RailsFlowMap::FormatterError do
  it 'has formatting category' do
    error = described_class.new("Format failed")
    expect(error.category).to eq(:formatting)
  end
end

RSpec.describe RailsFlowMap::FileOperationError do
  it 'has file_operation category' do
    error = described_class.new("File operation failed")
    expect(error.category).to eq(:file_operation)
  end
end

RSpec.describe RailsFlowMap::SecurityError do
  it 'has security category' do
    error = described_class.new("Security violation")
    expect(error.category).to eq(:security)
  end
end

RSpec.describe RailsFlowMap::InvalidInputError do
  it 'has invalid_input category' do
    error = described_class.new("Invalid input")
    expect(error.category).to eq(:invalid_input)
  end
end

RSpec.describe RailsFlowMap::ResourceLimitError do
  it 'has resource_limit category' do
    error = described_class.new("Resource limit exceeded")
    expect(error.category).to eq(:resource_limit)
  end
end

RSpec.describe RailsFlowMap::ErrorHandler do
  let(:test_operation) { 'test_operation' }
  let(:test_context) { { param: 'value' } }

  describe '.with_error_handling' do
    it 'executes block successfully' do
      result = described_class.with_error_handling(test_operation) do
        'success'
      end
      
      expect(result).to eq('success')
    end

    it 'converts standard errors to RailsFlowMap errors' do
      expect do
        described_class.with_error_handling(test_operation) do
          raise ArgumentError, "Invalid argument"
        end
      end.to raise_error(RailsFlowMap::InvalidInputError) do |error|
        expect(error.message).to include("Invalid input during #{test_operation}")
        expect(error.context[:operation]).to eq(test_operation)
        expect(error.context[:original_error]).to eq('ArgumentError')
      end
    end

    it 'retries transient errors' do
      attempt_count = 0
      
      result = described_class.with_error_handling(test_operation, retries: 2) do
        attempt_count += 1
        if attempt_count <= 2
          raise Errno::EAGAIN, "Resource temporarily unavailable"
        end
        'success_after_retry'
      end
      
      expect(result).to eq('success_after_retry')
      expect(attempt_count).to eq(3)
    end

    it 'fails after max retries' do
      expect do
        described_class.with_error_handling(test_operation, retries: 1) do
          raise Errno::EAGAIN, "Resource temporarily unavailable"
        end
      end.to raise_error(RailsFlowMap::FileOperationError) do |error|
        expect(error.context[:max_retries_exceeded]).to be true
      end
    end

    it 'preserves RailsFlowMap errors' do
      original_error = RailsFlowMap::SecurityError.new("Security violation")
      
      expect do
        described_class.with_error_handling(test_operation) do
          raise original_error
        end
      end.to raise_error(RailsFlowMap::SecurityError, "Security violation")
    end
  end

  describe '.handle_error' do
    it 'converts JSON::ParserError to GraphParseError' do
      json_error = JSON::ParserError.new("Invalid JSON")
      
      expect do
        described_class.handle_error(json_error, test_operation, test_context)
      end.to raise_error(RailsFlowMap::GraphParseError) do |error|
        expect(error.message).to include("Failed to parse data")
        expect(error.context[:operation]).to eq(test_operation)
      end
    end

    it 'converts Errno::ENOENT to FileOperationError' do
      file_error = Errno::ENOENT.new("File not found")
      
      expect do
        described_class.handle_error(file_error, test_operation, test_context)
      end.to raise_error(RailsFlowMap::FileOperationError) do |error|
        expect(error.message).to include("File operation failed")
        expect(error.context[:operation]).to eq(test_operation)
      end
    end

    it 'converts ArgumentError to InvalidInputError' do
      arg_error = ArgumentError.new("Invalid argument")
      
      expect do
        described_class.handle_error(arg_error, test_operation, test_context)
      end.to raise_error(RailsFlowMap::InvalidInputError) do |error|
        expect(error.message).to include("Invalid input")
        expect(error.context[:operation]).to eq(test_operation)
      end
    end

    it 'converts SystemStackError to ResourceLimitError' do
      stack_error = SystemStackError.new("Stack overflow")
      
      expect do
        described_class.handle_error(stack_error, test_operation, test_context)
      end.to raise_error(RailsFlowMap::ResourceLimitError) do |error|
        expect(error.message).to include("Stack overflow")
        expect(error.context[:operation]).to eq(test_operation)
      end
    end

    it 'converts unknown errors to generic Error' do
      unknown_error = RuntimeError.new("Unknown error")
      
      expect do
        described_class.handle_error(unknown_error, test_operation, test_context)
      end.to raise_error(RailsFlowMap::Error) do |error|
        expect(error.message).to include("Unexpected error")
        expect(error.context[:operation]).to eq(test_operation)
      end
    end
  end

  describe '.validate_input!' do
    it 'passes when all validations succeed' do
      validations = {
        param1: -> { true },
        param2: -> { "test".is_a?(String) }
      }
      
      expect do
        described_class.validate_input!(validations)
      end.not_to raise_error
    end

    it 'raises InvalidInputError when validation fails' do
      validations = {
        param1: -> { false }
      }
      
      expect do
        described_class.validate_input!(validations, context: { operation: 'test' })
      end.to raise_error(RailsFlowMap::InvalidInputError) do |error|
        expect(error.message).to include("Invalid value for parameter 'param1'")
        expect(error.context[:parameter]).to eq('param1')
        expect(error.context[:operation]).to eq('test')
      end
    end

    it 'raises InvalidInputError when validation throws exception' do
      validations = {
        param1: -> { raise StandardError, "Validation failed" }
      }
      
      expect do
        described_class.validate_input!(validations)
      end.to raise_error(RailsFlowMap::InvalidInputError) do |error|
        expect(error.message).to include("Validation failed for parameter 'param1': Validation failed")
      end
    end
  end

  describe '.retryable?' do
    it 'returns true for retryable errors' do
      expect(described_class.retryable?(Errno::ENOENT.new)).to be true
      expect(described_class.retryable?(Errno::EACCES.new)).to be true
      expect(described_class.retryable?(Errno::EAGAIN.new)).to be true
      expect(described_class.retryable?(Timeout::Error.new)).to be true
    end

    it 'returns false for non-retryable errors' do
      expect(described_class.retryable?(ArgumentError.new)).to be false
      expect(described_class.retryable?(StandardError.new)).to be false
    end
  end

  describe '.user_friendly_message' do
    it 'provides friendly messages for RailsFlowMap errors' do
      parse_error = RailsFlowMap::GraphParseError.new("JSON parse error")
      expect(described_class.user_friendly_message(parse_error)).to eq(
        "Failed to parse the graph data. Please check your input format."
      )

      file_error = RailsFlowMap::FileOperationError.new("Permission denied")
      expect(described_class.user_friendly_message(file_error)).to eq(
        "File operation failed. Please check file permissions and paths."
      )

      input_error = RailsFlowMap::InvalidInputError.new("Invalid parameter")
      expect(described_class.user_friendly_message(input_error)).to eq(
        "Invalid input provided. Invalid parameter"
      )

      security_error = RailsFlowMap::SecurityError.new("XSS detected")
      expect(described_class.user_friendly_message(security_error)).to eq(
        "Security validation failed. Operation blocked for safety."
      )

      resource_error = RailsFlowMap::ResourceLimitError.new("Out of memory")
      expect(described_class.user_friendly_message(resource_error)).to eq(
        "Operation exceeded resource limits. Please try with smaller input."
      )
    end

    it 'provides generic message for unknown errors' do
      unknown_error = StandardError.new("Unknown error")
      expect(described_class.user_friendly_message(unknown_error)).to eq(
        "An unexpected error occurred. Please try again."
      )
    end

    it 'preserves original message for RailsFlowMap errors' do
      error = RailsFlowMap::Error.new("Custom error message")
      expect(described_class.user_friendly_message(error)).to eq("Custom error message")
    end
  end
end