# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"

require "simplecov"
SimpleCov.start "rails" do
  enable_coverage :branch

  # Baseline at the time coverage tracking was introduced (see docs/llms/testing.md).
  # Ratchet these up as coverage improves; never lower them without discussion.
  #
  # No maximum_drop here on purpose: it compares against coverage/.last_run.json,
  # which is a local, gitignored cache. CI starts every run with an empty
  # coverage/, so maximum_drop would silently never fire there, while locally
  # it compares against whatever partial/full run you happened to run last -
  # a false "regression" as likely as a real one. `minimum` alone is stable
  # regardless of run history, so it is the only gate here.
  # Nudged down from 47/32 after the over-engineering pass in
  # docs/llms/development.md: deleting duplicate/dead code shrinks the
  # denominator too, so the same well-tested code can read as a lower
  # percentage. Round-tripping the floor with real coverage, not a
  # regression - see that doc before raising or lowering further.
  coverage(:line) { minimum 46 }
  coverage(:branch) { minimum 31 }
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

    # N+1 query detection (config/initializers/prosopite.rb, currently log-only -
    # see docs/llms/testing.md). Wraps the whole test, not just controller actions,
    # so model/query/service tests are covered too. Must run per-test, never around
    # the whole suite.
    setup { Prosopite.scan }
    teardown { Prosopite.finish }

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
