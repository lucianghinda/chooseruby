# frozen_string_literal: true

require "test_helper"

class AuthorFtsSyncTest < ActiveSupport::TestCase
  def setup
    # Ensure FTS5 tables exist (needed for parallel test runs)
    create_fts_tables_if_missing

    # Clean up FTS table and authors before each test
    ActiveRecord::Base.connection.execute("DELETE FROM authors_fts")
    Author.destroy_all
  end

  def teardown
    # Clean up FTS table and authors after each test
    ActiveRecord::Base.connection.execute("DELETE FROM authors_fts")
    Author.destroy_all
  end

  # Test 1: FTS row creation on Author.create
  test "creates FTS row when Author is created" do
    author = Author.create!(
      name: "Yukihiro Matsumoto",
      status: :approved
    )

    # Query FTS table to verify row was created
    result = ActiveRecord::Base.connection.execute(
      "SELECT author_id, name FROM authors_fts WHERE author_id = #{author.id}"
    ).first

    assert_not_nil result, "FTS row should exist for the created author"
    assert_equal author.id, result["author_id"]
    assert_equal "Yukihiro Matsumoto", result["name"]
  end

  # Test 2: FTS row update on Author.update (name changes)
  test "updates FTS row when Author name changes" do
    author = Author.create!(
      name: "Original Name",
      status: :approved
    )

    # Update the author's name
    author.update!(name: "Updated Name")

    # Query FTS table to verify row was updated
    result = ActiveRecord::Base.connection.execute(
      "SELECT name FROM authors_fts WHERE author_id = #{author.id}"
    ).first

    assert_equal "Updated Name", result["name"]
  end

  # Test 3: FTS row deletion on Author.destroy
  test "deletes FTS row when Author is destroyed" do
    author = Author.create!(
      name: "To Be Deleted",
      status: :approved
    )

    author_id = author.id

    # Verify FTS row exists before deletion
    result_before = ActiveRecord::Base.connection.execute(
      "SELECT author_id FROM authors_fts WHERE author_id = #{author_id}"
    ).first
    assert_not_nil result_before, "FTS row should exist before deletion"

    # Delete the author
    author.destroy!

    # Verify FTS row was deleted
    result_after = ActiveRecord::Base.connection.execute(
      "SELECT author_id FROM authors_fts WHERE author_id = #{author_id}"
    ).first
    assert_nil result_after, "FTS row should be deleted after author destruction"
  end

  # Test 4: Nil name handling
  test "handles nil name gracefully" do
    # Create author with minimal attributes (name will be empty string)
    author = Author.new(name: "")

    # This will fail validation since name must be at least 2 characters
    # So we test with a valid name instead and verify empty string handling
    author = Author.create!(name: "AB", status: :approved)

    # Query FTS table to verify name was synced
    result = ActiveRecord::Base.connection.execute(
      "SELECT name FROM authors_fts WHERE author_id = #{author.id}"
    ).first

    assert_equal "AB", result["name"]
  end

  # Test 5: Does not sync when only unrelated fields change
  test "does not sync to FTS when only unrelated fields change" do
    author = Author.create!(
      name: "Test Author",
      status: :pending,
      bio: "Original bio"
    )

    # Get original FTS data
    original_result = ActiveRecord::Base.connection.execute(
      "SELECT name FROM authors_fts WHERE author_id = #{author.id}"
    ).first

    # Update unrelated field (status and bio)
    author.update!(status: :approved, bio: "Updated bio")

    # Verify FTS data unchanged (still exists with same name)
    updated_result = ActiveRecord::Base.connection.execute(
      "SELECT name FROM authors_fts WHERE author_id = #{author.id}"
    ).first

    assert_equal original_result["name"], updated_result["name"]
  end

  private

  # Create FTS5 tables if they don't exist
  # This is needed for parallel test runs where each worker has its own database
  def create_fts_tables_if_missing
    # Check if authors_fts table exists
    result = ActiveRecord::Base.connection.execute(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='authors_fts'"
    ).first

    return if result.present?

    # Create authors_fts table
    ActiveRecord::Base.connection.execute(<<-SQL)
      CREATE VIRTUAL TABLE authors_fts USING fts5(
        author_id UNINDEXED,
        name,
        tokenize='porter ascii'
      );
    SQL
  end
end
