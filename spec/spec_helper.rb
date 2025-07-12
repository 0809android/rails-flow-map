require "bundler/setup"
require "fileutils"
require "rails_flow_map"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Create tmp directory for test outputs
  config.before(:suite) do
    FileUtils.mkdir_p("tmp")
  end

  # Clean up tmp directory after tests
  config.after(:suite) do
    FileUtils.rm_rf("tmp")
  end

  # Reset configuration before each test
  config.before(:each) do
    RailsFlowMap.instance_variable_set(:@configuration, nil)
  end
end