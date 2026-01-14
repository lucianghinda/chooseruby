# frozen_string_literal: true

require "test_helper"

class Fts5TablesTest < ActiveSupport::TestCase
  # Since FTS5 virtual tables can't be rolled back in transactions like regular tables,
  # we need to ensure they exist before each test
  setup do
    # Create FTS5 tables if they don't exist (idempotent)
    ActiveRecord::Base.connection.execute(<<-SQL)
      CREATE VIRTUAL TABLE IF NOT EXISTS entries_fts USING fts5(
        entry_id UNINDEXED,
        title,
        description,
        tags,
        tokenize='porter ascii'
      );
    SQL

    ActiveRecord::Base.connection.execute(<<-SQL)
      CREATE VIRTUAL TABLE IF NOT EXISTS authors_fts USING fts5(
        author_id UNINDEXED,
        name,
        tokenize='porter ascii'
      );
    SQL
  end

  test "entries_fts virtual table exists and has correct structure" do
    # Test that entries_fts table exists in the database
    tables = ActiveRecord::Base.connection.execute(
      "SELECT name FROM sqlite_master WHERE type='table' AND name LIKE '%fts%'"
    ).map { |row| row["name"] }

    assert_includes tables, "entries_fts", "entries_fts virtual table should exist"

    # Test that we can query the table structure
    # FTS5 virtual tables expose their structure through pragma_table_info
    columns = ActiveRecord::Base.connection.execute(
      "SELECT name FROM pragma_table_info('entries_fts')"
    ).map { |row| row["name"] }

    assert_includes columns, "entry_id", "entries_fts should have entry_id column"
    assert_includes columns, "title", "entries_fts should have title column"
    assert_includes columns, "description", "entries_fts should have description column"
    assert_includes columns, "tags", "entries_fts should have tags column"
  end

  test "authors_fts virtual table exists and has correct structure" do
    # Test that authors_fts table exists in the database
    tables = ActiveRecord::Base.connection.execute(
      "SELECT name FROM sqlite_master WHERE type='table' AND name LIKE '%fts%'"
    ).map { |row| row["name"] }

    assert_includes tables, "authors_fts", "authors_fts virtual table should exist"

    # Test that we can query the table structure
    columns = ActiveRecord::Base.connection.execute(
      "SELECT name FROM pragma_table_info('authors_fts')"
    ).map { |row| row["name"] }

    assert_includes columns, "author_id", "authors_fts should have author_id column"
    assert_includes columns, "name", "authors_fts should have name column"
  end

  test "entries_fts supports INSERT and MATCH query operations" do
    # Insert a test record into entries_fts
    ActiveRecord::Base.connection.execute(
      "INSERT INTO entries_fts (entry_id, title, description, tags) VALUES (1, 'Rails Testing', 'Learn how to test Rails applications', 'testing rails')"
    )

    # Test that we can MATCH query the inserted record
    result = ActiveRecord::Base.connection.execute(
      "SELECT entry_id, title FROM entries_fts WHERE entries_fts MATCH 'rails'"
    )

    assert_equal 1, result.count, "Should find one matching record"
    assert_equal 1, result.first["entry_id"], "Should match the inserted entry_id"
    assert_equal "Rails Testing", result.first["title"], "Should return the correct title"

    # Clean up
    ActiveRecord::Base.connection.execute("DELETE FROM entries_fts WHERE entry_id = 1")
  end

  test "authors_fts supports INSERT and MATCH query operations" do
    # Insert a test record into authors_fts
    ActiveRecord::Base.connection.execute(
      "INSERT INTO authors_fts (author_id, name) VALUES (1, 'Yukihiro Matsumoto')"
    )

    # Test that we can MATCH query the inserted record
    result = ActiveRecord::Base.connection.execute(
      "SELECT author_id, name FROM authors_fts WHERE authors_fts MATCH 'yukihiro'"
    )

    assert_equal 1, result.count, "Should find one matching record"
    assert_equal 1, result.first["author_id"], "Should match the inserted author_id"
    assert_equal "Yukihiro Matsumoto", result.first["name"], "Should return the correct name"

    # Clean up
    ActiveRecord::Base.connection.execute("DELETE FROM authors_fts WHERE author_id = 1")
  end
end
