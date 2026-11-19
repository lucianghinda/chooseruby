# frozen_string_literal: true

# Configuration only; `SimpleCov.start` lives in config/boot.rb and test_helper.rb.
SimpleCov.load_profile "rails"

# Parallel agents and parallel runs share one resultset file. Point a run at its
# own directory with COVERAGE_DIR to keep the numbers honest.
SimpleCov.coverage_dir ENV.fetch("COVERAGE_DIR", "coverage")

# Rails runs tests in forked workers; track them too.
SimpleCov.merge_subprocesses true

# Minimums only make sense for a full-suite run: a subset, and `test:system`
# on its own, can never reach them. Set SKIP_COVERAGE_CHECK=1 for a subset.
subset = ARGV.grep(/\Atest:/).any?
enforce = ENV["SKIP_COVERAGE_CHECK"].to_s.empty? && !subset

# 100% line and branch, globally and per file. Never lower these: when a line or
# branch is uncovered, either the code does too much or a test is missing.
SimpleCov.coverage :line do
  if enforce
    minimum 100
    minimum 100, per: :file
  end
end

SimpleCov.coverage :branch do
  ignore :eval_generated

  if enforce
    minimum 100
    minimum 100, per: :file
  end
end
