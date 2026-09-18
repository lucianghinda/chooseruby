# frozen_string_literal: true

SimpleCov.load_profile "rails"
SimpleCov.coverage_dir ENV.fetch("COVERAGE_DIR", "coverage")
SimpleCov.command_name ENV["COVERAGE_COMMAND_NAME"] if ENV["COVERAGE_COMMAND_NAME"]

SimpleCov.coverage :line do
  minimum 100
  minimum 100, per: :file
end

SimpleCov.coverage :branch do
  ignore :eval_generated
  minimum 100
  minimum 100, per: :file
end
