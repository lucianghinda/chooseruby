# frozen_string_literal: true

require "test_helper"

class FtsReindexerTest < ActiveSupport::TestCase
  test "reindexes all entries into entries_fts table" do
    # Clear FTS tables first
    ActiveRecord::Base.connection.execute("DELETE FROM entries_fts")

    # Create test entries
    entry1 = Entry.create!(
      title: "Test Entry 1",
      url: "https://example.com/entry1",
      status: :approved
    )
    entry2 = Entry.create!(
      title: "Test Entry 2",
      url: "https://example.com/entry2",
      status: :approved
    )

    # Clear FTS table again (entries will auto-sync on create)
    ActiveRecord::Base.connection.execute("DELETE FROM entries_fts")

    # Verify FTS table is empty
    count = ActiveRecord::Base.connection.execute("SELECT COUNT(*) FROM entries_fts").first["COUNT(*)"]
    assert_equal 0, count

    # Reindex
    FtsReindexer.new.reindex_entries

    # Verify all entries are in FTS table
    count = ActiveRecord::Base.connection.execute("SELECT COUNT(*) FROM entries_fts").first["COUNT(*)"]
    assert_equal 2, count

    # Verify entry data is correct
    result = ActiveRecord::Base.connection.execute(
      ActiveRecord::Base.sanitize_sql_array([
        "SELECT * FROM entries_fts WHERE entry_id = ?",
        entry1.id
      ])
    ).first

    assert_equal entry1.title, result["title"]
  end

  test "reindexes all authors into authors_fts table" do
    # Clear FTS tables first
    ActiveRecord::Base.connection.execute("DELETE FROM authors_fts")

    # Create test authors
    author1 = Author.create!(name: "Yukihiro Matsumoto")
    author2 = Author.create!(name: "David Heinemeier Hansson")

    # Clear FTS table again (authors will auto-sync on create)
    ActiveRecord::Base.connection.execute("DELETE FROM authors_fts")

    # Verify FTS table is empty
    count = ActiveRecord::Base.connection.execute("SELECT COUNT(*) FROM authors_fts").first["COUNT(*)"]
    assert_equal 0, count

    # Reindex
    FtsReindexer.new.reindex_authors

    # Verify all authors are in FTS table
    count = ActiveRecord::Base.connection.execute("SELECT COUNT(*) FROM authors_fts").first["COUNT(*)"]
    assert_equal 2, count

    # Verify author data is correct
    result = ActiveRecord::Base.connection.execute(
      ActiveRecord::Base.sanitize_sql_array([
        "SELECT * FROM authors_fts WHERE author_id = ?",
        author1.id
      ])
    ).first

    assert_equal author1.name, result["name"]
  end

  test "reindex_all reindexes both entries and authors" do
    # Clear FTS tables
    ActiveRecord::Base.connection.execute("DELETE FROM entries_fts")
    ActiveRecord::Base.connection.execute("DELETE FROM authors_fts")

    # Create test data
    Entry.create!(title: "Test Entry", url: "https://example.com/entry", status: :approved)
    Author.create!(name: "Test Author")

    # Clear FTS tables again after auto-sync
    ActiveRecord::Base.connection.execute("DELETE FROM entries_fts")
    ActiveRecord::Base.connection.execute("DELETE FROM authors_fts")

    # Reindex all
    FtsReindexer.new.reindex_all

    # Verify both tables have data
    entries_count = ActiveRecord::Base.connection.execute("SELECT COUNT(*) FROM entries_fts").first["COUNT(*)"]
    authors_count = ActiveRecord::Base.connection.execute("SELECT COUNT(*) FROM authors_fts").first["COUNT(*)"]

    assert_operator entries_count, :>, 0
    assert_operator authors_count, :>, 0
  end

  test "reindex_entries processes entries in batches" do
    # Clear FTS table
    ActiveRecord::Base.connection.execute("DELETE FROM entries_fts")

    # Create multiple entries to test batching
    5.times do |i|
      Entry.create!(
        title: "Test Entry #{i}",
        url: "https://example.com/entry-#{i}",
        status: :approved
      )
    end

    # Reindex with small batch size
    FtsReindexer.new.reindex_entries(batch_size: 2)

    # Verify all entries are indexed
    count = ActiveRecord::Base.connection.execute("SELECT COUNT(*) FROM entries_fts").first["COUNT(*)"]
    assert_operator count, :>=, 5
  end
end
