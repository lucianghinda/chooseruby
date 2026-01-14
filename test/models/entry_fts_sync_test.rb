# frozen_string_literal: true

require "test_helper"

class EntryFtsSyncTest < ActiveSupport::TestCase
  def setup
    # Ensure FTS5 tables exist (needed for parallel test runs)
    create_fts_tables_if_missing

    # Clean up FTS table and entries before each test
    ActiveRecord::Base.connection.execute("DELETE FROM entries_fts")
    Entry.destroy_all
    RubyGem.destroy_all
  end

  def teardown
    # Clean up FTS table and entries after each test
    ActiveRecord::Base.connection.execute("DELETE FROM entries_fts")
    Entry.destroy_all
    RubyGem.destroy_all
  end

  # Test 1: FTS row creation on Entry.create
  test "creates FTS row when Entry is created" do
    gem = RubyGem.create!(gem_name: "test-gem", rubygems_url: "https://rubygems.org/gems/test-gem")
    entry = Entry.create!(
      title: "Test Gem",
      description: "A test gem for testing",
      url: "https://example.com",
      entryable: gem,
      tags: [ "testing", "gem" ],
      status: :approved,
      published: true
    )

    # Query FTS table to verify row was created
    result = ActiveRecord::Base.connection.execute(
      "SELECT entry_id, title, description, tags FROM entries_fts WHERE entry_id = #{entry.id}"
    ).first

    assert_not_nil result, "FTS row should exist for the created entry"
    assert_equal entry.id, result["entry_id"]
    assert_equal "Test Gem", result["title"]
    assert_equal "A test gem for testing", result["description"]
    assert_equal "testing gem", result["tags"]
  end

  # Test 2: FTS row update on Entry.update (title, description, tags changes)
  test "updates FTS row when Entry title, description, or tags change" do
    gem = RubyGem.create!(gem_name: "update-gem", rubygems_url: "https://rubygems.org/gems/update-gem")
    entry = Entry.create!(
      title: "Original Title",
      description: "Original description",
      url: "https://example.com",
      entryable: gem,
      tags: [ "original" ],
      status: :approved,
      published: true
    )

    # Update the entry
    entry.update!(
      title: "Updated Title",
      description: "Updated description",
      tags: [ "updated", "new" ]
    )

    # Query FTS table to verify row was updated
    result = ActiveRecord::Base.connection.execute(
      "SELECT title, description, tags FROM entries_fts WHERE entry_id = #{entry.id}"
    ).first

    assert_equal "Updated Title", result["title"]
    assert_equal "Updated description", result["description"]
    assert_equal "updated new", result["tags"]
  end

  # Test 3: FTS row deletion on Entry.destroy
  test "deletes FTS row when Entry is destroyed" do
    gem = RubyGem.create!(gem_name: "destroy-gem", rubygems_url: "https://rubygems.org/gems/destroy-gem")
    entry = Entry.create!(
      title: "To Be Deleted",
      description: "This entry will be deleted",
      url: "https://example.com",
      entryable: gem,
      status: :approved,
      published: true
    )

    entry_id = entry.id

    # Verify FTS row exists before deletion
    result_before = ActiveRecord::Base.connection.execute(
      "SELECT entry_id FROM entries_fts WHERE entry_id = #{entry_id}"
    ).first
    assert_not_nil result_before, "FTS row should exist before deletion"

    # Delete the entry
    entry.destroy!

    # Verify FTS row was deleted
    result_after = ActiveRecord::Base.connection.execute(
      "SELECT entry_id FROM entries_fts WHERE entry_id = #{entry_id}"
    ).first
    assert_nil result_after, "FTS row should be deleted after entry destruction"
  end

  # Test 4: ActionText plain text extraction for description field
  test "extracts plain text from ActionText description" do
    gem = RubyGem.create!(gem_name: "actiontext-gem", rubygems_url: "https://rubygems.org/gems/actiontext-gem")
    entry = Entry.new(
      title: "ActionText Test",
      url: "https://example.com",
      entryable: gem,
      status: :approved,
      published: true
    )

    # Set rich text description with HTML
    entry.description = "<p>This is <strong>bold</strong> and <em>italic</em> text</p>"
    entry.save!

    # Query FTS table to verify plain text was extracted
    result = ActiveRecord::Base.connection.execute(
      "SELECT description FROM entries_fts WHERE entry_id = #{entry.id}"
    ).first

    # ActionText to_plain_text should strip HTML tags
    assert_equal "This is bold and italic text", result["description"]
  end

  # Test 5: Tags array serialization to searchable text
  test "converts tags array to space-separated string" do
    gem = RubyGem.create!(gem_name: "tags-gem", rubygems_url: "https://rubygems.org/gems/tags-gem")
    entry = Entry.create!(
      title: "Tags Test",
      description: "Testing tags serialization",
      url: "https://example.com",
      entryable: gem,
      tags: [ "ruby", "rails", "web-framework" ],
      status: :approved,
      published: true
    )

    # Query FTS table to verify tags were serialized
    result = ActiveRecord::Base.connection.execute(
      "SELECT tags FROM entries_fts WHERE entry_id = #{entry.id}"
    ).first

    assert_equal "ruby rails web-framework", result["tags"]
  end

  # Test 6: Nil description handling
  test "handles nil description gracefully" do
    gem = RubyGem.create!(gem_name: "nil-desc-gem", rubygems_url: "https://rubygems.org/gems/nil-desc-gem")
    entry = Entry.create!(
      title: "No Description",
      url: "https://example.com",
      entryable: gem,
      status: :approved,
      published: true
      # description is intentionally not set (will be nil)
    )

    # Query FTS table to verify empty string was used
    result = ActiveRecord::Base.connection.execute(
      "SELECT description FROM entries_fts WHERE entry_id = #{entry.id}"
    ).first

    assert_equal "", result["description"]
  end

  # Test 7: Empty tags array handling
  test "handles empty tags array gracefully" do
    gem = RubyGem.create!(gem_name: "empty-tags-gem", rubygems_url: "https://rubygems.org/gems/empty-tags-gem")
    entry = Entry.create!(
      title: "No Tags",
      description: "Entry with no tags",
      url: "https://example.com",
      entryable: gem,
      tags: [],
      status: :approved,
      published: true
    )

    # Query FTS table to verify empty string was used
    result = ActiveRecord::Base.connection.execute(
      "SELECT tags FROM entries_fts WHERE entry_id = #{entry.id}"
    ).first

    assert_equal "", result["tags"]
  end

  # Test 8: should_sync_fts? returns true when title changes
  test "should_sync_fts? returns true when title changes" do
    gem = RubyGem.create!(gem_name: "sync-test-gem", rubygems_url: "https://rubygems.org/gems/sync-test-gem")
    entry = Entry.create!(
      title: "Original Title",
      description: "Test description",
      url: "https://example.com",
      entryable: gem,
      status: :approved,
      published: true
    )

    entry.title = "New Title"
    entry.save!

    # Verify FTS was updated
    result = ActiveRecord::Base.connection.execute(
      "SELECT title FROM entries_fts WHERE entry_id = #{entry.id}"
    ).first

    assert_equal "New Title", result["title"]
  end

  # Test 9: should_sync_fts? skips sync when unrelated fields change
  test "does not sync to FTS when only unrelated fields change" do
    gem = RubyGem.create!(gem_name: "no-sync-gem", rubygems_url: "https://rubygems.org/gems/no-sync-gem")
    entry = Entry.create!(
      title: "Test Entry",
      description: "Test description",
      url: "https://example.com",
      entryable: gem,
      status: :approved,
      published: true
    )

    # Get original FTS data
    original_result = ActiveRecord::Base.connection.execute(
      "SELECT title, description, tags FROM entries_fts WHERE entry_id = #{entry.id}"
    ).first

    # Update unrelated field (published status)
    entry.update!(published: false)

    # Verify FTS data unchanged
    updated_result = ActiveRecord::Base.connection.execute(
      "SELECT title, description, tags FROM entries_fts WHERE entry_id = #{entry.id}"
    ).first

    assert_equal original_result["title"], updated_result["title"]
    assert_equal original_result["description"], updated_result["description"]
    assert_equal original_result["tags"], updated_result["tags"]
  end

  private

  # Create FTS5 tables if they don't exist
  # This is needed for parallel test runs where each worker has its own database
  def create_fts_tables_if_missing
    # Check if entries_fts table exists
    result = ActiveRecord::Base.connection.execute(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='entries_fts'"
    ).first

    return if result.present?

    # Create entries_fts table
    ActiveRecord::Base.connection.execute(<<-SQL)
      CREATE VIRTUAL TABLE entries_fts USING fts5(
        entry_id UNINDEXED,
        title,
        description,
        tags,
        tokenize='porter ascii'
      );
    SQL
  end
end
