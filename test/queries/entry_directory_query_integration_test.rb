# frozen_string_literal: true

require "test_helper"

class EntryDirectoryQueryIntegrationTest < ActiveSupport::TestCase
  def setup
    # Ensure FTS5 tables exist (needed for parallel test runs)
    create_fts_tables_if_missing

    # Clean up before each test
    ActiveRecord::Base.connection.execute("DELETE FROM entries_fts")
    Entry.destroy_all
    RubyGem.destroy_all
    Category.destroy_all

    # Create test category
    @web_category = Category.create!(name: "Web Development", slug: "web-development")

    # Create test entries
    @gem1 = RubyGem.create!(gem_name: "rails", rubygems_url: "https://rubygems.org/gems/rails")
    @entry1 = Entry.create!(
      title: "Rails Framework",
      description: "Ruby on Rails is a web application framework",
      url: "https://rubyonrails.org",
      entryable: @gem1,
      tags: [ "web", "mvc" ],
      status: :approved,
      published: true,
      experience_level: :intermediate
    )
    @entry1.categories << @web_category

    @gem2 = RubyGem.create!(gem_name: "sinatra", rubygems_url: "https://rubygems.org/gems/sinatra")
    @entry2 = Entry.create!(
      title: "Sinatra",
      description: "Lightweight web microframework",
      url: "https://sinatrarb.com",
      entryable: @gem2,
      tags: [ "web", "dsl" ],
      status: :approved,
      published: true,
      experience_level: :beginner
    )
    @entry2.categories << @web_category

    @gem3 = RubyGem.create!(gem_name: "rspec", rubygems_url: "https://rubygems.org/gems/rspec")
    @entry3 = Entry.create!(
      title: "RSpec",
      description: "Testing tool for behavior-driven development",
      url: "https://rspec.info",
      entryable: @gem3,
      tags: [ "testing", "bdd" ],
      status: :approved,
      published: true,
      experience_level: :intermediate
    )
  end

  def teardown
    # Clean up after each test
    ActiveRecord::Base.connection.execute("DELETE FROM entries_fts")
    Entry.destroy_all
    RubyGem.destroy_all
    Category.destroy_all
  end

  # Test 1: FTS search + category filter
  test "filters by FTS search and category" do
    query = EntryDirectoryQuery.new({ q: "web", category: "web-development" })
    results = query.call.to_a

    assert_equal 2, results.count, "Should find 2 web entries in web development category"
    assert_includes results, @entry1
    assert_includes results, @entry2
    assert_not_includes results, @entry3
  end

  # Test 2: FTS search + level filter
  test "filters by FTS search and experience level" do
    query = EntryDirectoryQuery.new({ q: "rails", level: "intermediate" })
    results = query.call.to_a

    assert_equal 1, results.count, "Should find 1 intermediate Rails entry"
    assert_includes results, @entry1
    assert_not_includes results, @entry2
    assert_not_includes results, @entry3
  end

  # Test 3: FTS search + category + level filter
  test "filters by FTS search, category, and experience level" do
    query = EntryDirectoryQuery.new({
      q: "web",
      category: "web-development",
      level: "beginner"
    })
    results = query.call.to_a

    assert_equal 1, results.count, "Should find 1 beginner web entry"
    assert_includes results, @entry2
    assert_not_includes results, @entry1
    assert_not_includes results, @entry3
  end

  test "level filter includes all_levels entries" do
    @entry3.update!(experience_level: :all_levels)

    query = EntryDirectoryQuery.new({ level: "beginner" })
    results = query.call.to_a

    assert_includes results, @entry2
    assert_includes results, @entry3, "Should include all_levels entries with level filter"
  end

  test "category and level filter include all_levels entries" do
    @entry3.update!(experience_level: :all_levels)
    @entry3.categories << @web_category

    query = EntryDirectoryQuery.new({ category: "web-development", level: "intermediate" })
    results = query.call.to_a

    assert_includes results, @entry1
    assert_includes results, @entry3, "Should include all_levels entries within category filter"
    assert_not_includes results, @entry2
  end

  # Test 4: Only category filter (no FTS search)
  test "filters by category without FTS search" do
    query = EntryDirectoryQuery.new({ category: "web-development" })
    results = query.call.to_a

    assert_equal 2, results.count, "Should find 2 web development entries"
    assert_includes results, @entry1
    assert_includes results, @entry2
    assert_not_includes results, @entry3
  end

  # Test 5: Only level filter (no FTS search)
  test "filters by level without FTS search" do
    query = EntryDirectoryQuery.new({ level: "intermediate" })
    results = query.call.to_a

    assert_equal 2, results.count, "Should find 2 intermediate entries"
    assert_includes results, @entry1
    assert_includes results, @entry3
    assert_not_includes results, @entry2
  end

  # Test 6: Respects visibility scopes
  test "only returns published and approved entries" do
    # Create unpublished entry
    gem4 = RubyGem.create!(gem_name: "draft", rubygems_url: "https://rubygems.org/gems/draft")
    unpublished = Entry.create!(
      title: "Draft Entry",
      description: "Web application not published",
      url: "https://example.com",
      entryable: gem4,
      status: :approved,
      published: false
    )

    # Create unapproved entry
    gem5 = RubyGem.create!(gem_name: "pending", rubygems_url: "https://rubygems.org/gems/pending")
    unapproved = Entry.create!(
      title: "Pending Entry",
      description: "Web application not approved",
      url: "https://example.com",
      entryable: gem5,
      status: :pending,
      published: true,
      submitter_email: "pending@example.com"
    )

    query = EntryDirectoryQuery.new({ q: "web" })
    results = query.call.to_a

    assert_not_includes results, unpublished, "Should not include unpublished entries"
    assert_not_includes results, unapproved, "Should not include unapproved entries"
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
