# frozen_string_literal: true

# Mutation runs measure selected tests against changed code, not suite coverage.
unless ENV["MUTANT"] == "1"
  require "simplecov"
  require "fileutils"

  # Keep only this invocation's results. Forked Rails workers inherit this
  # setup and SimpleCov merges their results after they finish.
  FileUtils.rm_f(File.join(SimpleCov.coverage_path, ".resultset.json"))
  SimpleCov.start
end
