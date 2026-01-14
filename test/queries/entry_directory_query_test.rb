# frozen_string_literal: true

require "test_helper"

class EntryDirectoryQueryTest < ActiveSupport::TestCase
  def setup
    # Ensure FTS5 tables exist (needed for parallel test runs)
    create_fts_tables_if_missing

    # Clean up before each test
    ActiveRecord::Base.connection.execute("DELETE FROM entries_fts")
    Entry.destroy_all
    RubyGem.destroy_all
    Book.destroy_all
    Category.destroy_all

    # Create test entries with FTS data
    @gem1 = RubyGem.create!(gem_name: "rails", rubygems_url: "https://rubygems.org/gems/rails")
    @entry1 = Entry.create!(
      title: "Rails Framework",
      description: "Ruby on Rails is a web framework for building applications",
      url: "https://rubyonrails.org",
      entryable: @gem1,
      tags: [ "web", "framework" ],
      status: :approved,
      published: true
    )

    @gem2 = RubyGem.create!(gem_name: "rspec", rubygems_url: "https://rubygems.org/gems/rspec")
    @entry2 = Entry.create!(
      title: "RSpec Testing",
      description: "RSpec is a behavior-driven development framework",
      url: "https://rspec.info",
      entryable: @gem2,
      tags: [ "testing", "bdd" ],
      status: :approved,
      published: true
    )

    @gem3 = RubyGem.create!(gem_name: "sidekiq", rubygems_url: "https://rubygems.org/gems/sidekiq")
    @entry3 = Entry.create!(
      title: "Sidekiq",
      description: "Simple, efficient background jobs for Ruby",
      url: "https://sidekiq.org",
      entryable: @gem3,
      tags: [ "background", "jobs" ],
      status: :approved,
      published: true
    )

    # Create a book entry for type filtering tests
    @book1 = Book.create!(publisher: "O'Reilly", publication_year: 2023)
    @entry4 = Entry.create!(
      title: "The Ruby Programming Language",
      description: "Comprehensive guide to Ruby programming",
      url: "https://example.com/ruby-book",
      entryable: @book1,
      tags: [ "programming", "reference" ],
      status: :approved,
      published: true
    )
  end

  def teardown
    # Clean up after each test
    ActiveRecord::Base.connection.execute("DELETE FROM entries_fts")
    Entry.destroy_all
    RubyGem.destroy_all
    Book.destroy_all
    Category.destroy_all
  end

  # Test 1: Partial word matching (e.g., "rail" finds "Rails")
  test "searches with partial word matching using FTS5" do
    query = EntryDirectoryQuery.new({ q: "rail" })
    results = query.call

    assert_includes results, @entry1, "Should find Rails Framework with partial match 'rail'"
    assert_not_includes results, @entry2, "Should not include RSpec"
    assert_not_includes results, @entry3, "Should not include Sidekiq"
  end

  # Test 2: Phrase search with quotes (e.g., "web framework")
  test "searches with phrase matching using quotes" do
    query = EntryDirectoryQuery.new({ q: '"web framework"' })
    results = query.call

    assert_includes results, @entry1, "Should find Rails with exact phrase 'web framework'"
    assert_not_includes results, @entry2, "Should not include RSpec"
    assert_not_includes results, @entry3, "Should not include Sidekiq"
  end

  # Test 3: Mixed queries (partial + phrase)
  test "searches with mixed partial and phrase matching" do
    query = EntryDirectoryQuery.new({ q: 'rails "web framework"' })
    results = query.call

    assert_includes results, @entry1, "Should find Rails with both partial and phrase match"
    assert_not_includes results, @entry2, "Should not include RSpec"
    assert_not_includes results, @entry3, "Should not include Sidekiq"
  end

  # Test 4: FTS5 special character sanitization
  test "sanitizes FTS5 special characters in query" do
    # Create entry with special chars in content
    gem = RubyGem.create!(gem_name: "test-gem", rubygems_url: "https://rubygems.org/gems/test-gem")
    entry = Entry.create!(
      title: "Test (Alpha)",
      description: "A gem for testing - with special chars",
      url: "https://example.com",
      entryable: gem,
      status: :approved,
      published: true
    )

    # Query with special characters that need escaping
    query = EntryDirectoryQuery.new({ q: "test (alpha)" })
    results = query.call

    assert_includes results, entry, "Should handle special chars in query"
  end

  # Test 4b: Handles apostrophes without FTS5 syntax errors
  test "sanitizes apostrophes in query" do
    gem = RubyGem.create!(gem_name: "entry-guide", rubygems_url: "https://rubygems.org/gems/entry-guide")
    entry = Entry.create!(
      title: "Entry's Guide",
      description: "A guide with an apostrophe",
      url: "https://example.com/entry-guide",
      entryable: gem,
      status: :approved,
      published: true
    )

    query = EntryDirectoryQuery.new({ q: "Entr'" })
    assert_nothing_raised { query.call }
    assert_includes query.call, entry, "Should match even with apostrophe in query"
  end

  # Test 5: Relevance ranking (BM25 order)
  test "orders results by BM25 relevance ranking" do
    # Create entries with varying relevance
    gem_high = RubyGem.create!(gem_name: "ruby-rails", rubygems_url: "https://rubygems.org/gems/ruby-rails")
    high_relevance = Entry.create!(
      title: "Ruby on Rails",
      description: "Ruby on Rails Ruby on Rails Ruby on Rails",
      url: "https://example.com/high",
      entryable: gem_high,
      tags: [ "ruby", "rails" ],
      status: :approved,
      published: true
    )

    gem_low = RubyGem.create!(gem_name: "other-gem", rubygems_url: "https://rubygems.org/gems/other-gem")
    low_relevance = Entry.create!(
      title: "Other Gem",
      description: "This mentions Ruby once",
      url: "https://example.com/low",
      entryable: gem_low,
      status: :approved,
      published: true
    )

    query = EntryDirectoryQuery.new({ q: "ruby" })
    results = query.call.to_a

    # High relevance entry should come before low relevance
    assert_equal high_relevance.id, results.first.id, "Higher relevance entry should be first"
  end

  # Test 6: Empty query handling
  test "returns all visible entries when query is blank" do
    query = EntryDirectoryQuery.new({ q: "" })
    results = query.call

    assert_equal 4, results.count, "Should return all visible entries with blank query"
    assert_includes results, @entry1
    assert_includes results, @entry2
    assert_includes results, @entry3
    assert_includes results, @entry4
  end

  # Test 7: Whitespace-only query handling
  test "returns all visible entries when query is whitespace only" do
    query = EntryDirectoryQuery.new({ q: "   " })
    results = query.call

    assert_equal 4, results.count, "Should return all visible entries with whitespace query"
  end

  # Test 8: Search in tags
  test "searches in tags field" do
    query = EntryDirectoryQuery.new({ q: "background" })
    results = query.call

    assert_includes results, @entry3, "Should find Sidekiq by tag 'background'"
    assert_not_includes results, @entry1
    assert_not_includes results, @entry2
  end

  # Type filtering tests (Task 2.1)

  # Test 9: Query initialization with type parameter
  test "initializes query with type parameter" do
    query = EntryDirectoryQuery.new({ type: "gems" })

    assert_equal "gems", query.type, "Should store type parameter"
  end

  # Test 10: filter_by_type filters by single type (gems)
  test "filters entries by single type gems" do
    query = EntryDirectoryQuery.new({ type: "gems" })
    results = query.call

    assert_equal 3, results.count, "Should return only gem entries"
    assert_includes results, @entry1
    assert_includes results, @entry2
    assert_includes results, @entry3
    assert_not_includes results, @entry4, "Should not include book entry"
  end

  # Test 11: filter_by_type filters by books type
  test "filters entries by books type" do
    query = EntryDirectoryQuery.new({ type: "books" })
    results = query.call

    assert_equal 1, results.count, "Should return only book entries"
    assert_includes results, @entry4
    assert_not_includes results, @entry1, "Should not include gem entries"
    assert_not_includes results, @entry2, "Should not include gem entries"
    assert_not_includes results, @entry3, "Should not include gem entries"
  end

  # Test 12: Type filtering combined with category filter
  test "filters by type and category together" do
    category = Category.create!(name: "Testing", slug: "testing")
    @entry2.categories << category
    @entry4.categories << category

    query = EntryDirectoryQuery.new({ type: "gems", category: "testing" })
    results = query.call

    assert_equal 1, results.count, "Should return only gem entries in testing category"
    assert_includes results, @entry2
    assert_not_includes results, @entry4, "Should not include book entry even if in same category"
  end

  # Test 13: Type filtering combined with level filter
  test "filters by type and experience level together" do
    @entry1.update!(experience_level: :beginner)
    @entry2.update!(experience_level: :intermediate)
    @entry4.update!(experience_level: :beginner)

    query = EntryDirectoryQuery.new({ type: "gems", level: "beginner" })
    results = query.call

    assert_equal 1, results.count, "Should return only beginner gem entries"
    assert_includes results, @entry1
    assert_not_includes results, @entry2, "Should not include intermediate gem"
    assert_not_includes results, @entry4, "Should not include beginner book"
  end

  # Test 14: Type filtering combined with search query
  test "filters by type and search query together" do
    query = EntryDirectoryQuery.new({ type: "gems", q: "rails" })
    results = query.call

    assert_equal 1, results.count, "Should return only gem entries matching search"
    assert_includes results, @entry1
    assert_not_includes results, @entry2, "Should not include gem not matching search"
    assert_not_includes results, @entry4, "Should not include book even if it might match"
  end

  test "filters beginner level and includes all_levels entries" do
    @entry1.update!(experience_level: :beginner)
    @entry2.update!(experience_level: :all_levels)
    @entry3.update!(experience_level: :intermediate)

    query = EntryDirectoryQuery.new({ level: "beginner" })
    results = query.call

    assert_includes results, @entry1
    assert_includes results, @entry2, "Should include all_levels entries with beginner filter"
    assert_not_includes results, @entry3
  end

  test "filters intermediate level and includes all_levels entries" do
    @entry1.update!(experience_level: :intermediate)
    @entry2.update!(experience_level: :all_levels)

    query = EntryDirectoryQuery.new({ level: "intermediate" })
    results = query.call

    assert_includes results, @entry1
    assert_includes results, @entry2, "Should include all_levels entries with intermediate filter"
  end

  test "filters advanced level and includes all_levels entries" do
    @entry1.update!(experience_level: :advanced)
    @entry2.update!(experience_level: :all_levels)

    query = EntryDirectoryQuery.new({ level: "advanced" })
    results = query.call

    assert_includes results, @entry1
    assert_includes results, @entry2, "Should include all_levels entries with advanced filter"
  end

  test "returns all entries when level parameter is blank" do
    @entry1.update!(experience_level: :beginner)
    @entry2.update!(experience_level: :advanced)
    @entry3.update!(experience_level: :all_levels)

    results = EntryDirectoryQuery.new({ level: "" }).call

    assert_equal 4, results.count
    assert_includes results, @entry1
    assert_includes results, @entry2
    assert_includes results, @entry3
    assert_includes results, @entry4
  end

  # Test 15: Invalid type parameter is handled gracefully
  test "handles invalid type parameter gracefully" do
    query = EntryDirectoryQuery.new({ type: "invalid_type" })
    results = query.call

    # Should return all entries when type is invalid (graceful degradation)
    assert_equal 4, results.count, "Should return all entries with invalid type"
  end

  # Test 16: FTS5 search works with type filter
  test "maintains FTS5 relevance ordering with type filter" do
    gem_high = RubyGem.create!(gem_name: "ruby-test", rubygems_url: "https://rubygems.org/gems/ruby-test")
    high_relevance = Entry.create!(
      title: "Ruby Testing",
      description: "Ruby Testing Ruby Testing Ruby Testing",
      url: "https://example.com/high",
      entryable: gem_high,
      tags: [ "ruby", "testing" ],
      status: :approved,
      published: true
    )

    query = EntryDirectoryQuery.new({ type: "gems", q: "testing" })
    results = query.call.to_a

    # High relevance gem entry should come first
    assert_equal high_relevance.id, results.first.id, "Should maintain FTS5 relevance with type filter"
    assert_includes results, @entry2, "Should include other gem matching search"
  end

  private

  # Create FTS5 tables if they don't exist
  def create_fts_tables_if_missing
    result = ActiveRecord::Base.connection.execute(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='entries_fts'"
    ).first

    return if result.present?

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
