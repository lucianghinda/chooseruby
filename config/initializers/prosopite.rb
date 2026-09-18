# frozen_string_literal: true

# N+1 query detection (see docs/llms/development.md). Logs only for now while
# we inventory existing N+1s (see docs/llms/n_plus_one_todo.md) - flip
# Prosopite.raise to true in config/environments/test.rb once that list is
# clear, to make new N+1s fail the test suite.
unless Rails.env.production?
  Prosopite.rails_logger = true
  Prosopite.prosopite_logger = true

  # Prosopite's non-MySQL fingerprinting shells out to the `pg_query` gem,
  # which only parses Postgres syntax. Our SQLite queries come through
  # already parameterized ("... = ?"), which pg_query can't parse at all
  # ("syntax error at end of input") - and the bug in Prosopite's rescue
  # clause turns that parse failure into `raise <the raw SQL string>`,
  # crashing every test that touches the DB. We don't need a real SQL
  # parser here: SQLite queries are already parameterized by the time
  # ActiveSupport sees them, so same-shaped N+1 queries are already
  # byte-for-byte identical strings. Fingerprint = the query itself.
  module Prosopite
    class << self
      alias_method :postgres_or_mysql_fingerprint, :fingerprint

      def fingerprint(query)
        if ActiveRecord::Base.connection_db_config.adapter.include?("sqlite")
          query.squish
        else
          postgres_or_mysql_fingerprint(query)
        end
      end
    end
  end
end
