# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"

require "simplecov"
SimpleCov.start "rails" do
  enable_coverage :branch

  # Baseline at the time coverage tracking was introduced (see docs/llms/testing.md).
  # Ratchet these up as coverage improves; never lower them without discussion.
  coverage :line do
    minimum 45
    maximum_drop 2
  end

  coverage :branch do
    minimum 30
    maximum_drop 2
  end
end

require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    # SimpleCov (started above) auto-detects Minitest's fork-based workers and
    # merges their coverage into a single report.
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Ensure FTS5 tables exist for tests (bin/rails test doesn't run db:test:prepare)
    setup do
      unless ActiveRecord::Base.connection.table_exists?("entries_fts")
        ActiveRecord::Base.connection.execute(<<-SQL)
          CREATE VIRTUAL TABLE IF NOT EXISTS entries_fts USING fts5(
            entry_id UNINDEXED,
            title,
            description,
            tags,
            tokenize='porter ascii'
          );
        SQL
      end

      unless ActiveRecord::Base.connection.table_exists?("authors_fts")
        ActiveRecord::Base.connection.execute(<<-SQL)
          CREATE VIRTUAL TABLE IF NOT EXISTS authors_fts USING fts5(
            author_id UNINDEXED,
            name,
            tokenize='porter ascii'
          );
        SQL
      end
    end

    # Add more helper methods to be used by all tests here...
  end
end
