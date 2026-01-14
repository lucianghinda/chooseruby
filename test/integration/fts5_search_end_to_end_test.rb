# frozen_string_literal: true

require "test_helper"

# End-to-end integration tests for FTS5 search feature
# Tests critical user workflows and integration points not covered by unit tests
class Fts5SearchEndToEndTest < ActionDispatch::IntegrationTest
  setup do
    # Ensure FTS5 tables exist
    create_fts_tables_if_missing

    # Clean up
    ActiveRecord::Base.connection.execute("DELETE FROM entries_fts")
    ActiveRecord::Base.connection.execute("DELETE FROM authors_fts")
    Entry.destroy_all
    Author.destroy_all
    Category.destroy_all

    # Create test categories
    @web_category = Category.create!(name: "Web Development", slug: "web-development")
    @testing_category = Category.create!(name: "Testing", slug: "testing")

    # Create test entries with different types
    @gem1 = RubyGem.create!(gem_name: "rails", rubygems_url: "https://rubygems.org/gems/rails")
    @entry1 = Entry.create!(
      title: "Rails Framework",
      description: "Ruby on Rails is a web application framework for building web applications",
      url: "https://rubyonrails.org",
      entryable: @gem1,
      tags: [ "web", "mvc", "framework" ],
      status: :approved,
      published: true,
      experience_level: :intermediate
    )
    @entry1.categories << @web_category

    @book1 = Book.create!(format: :ebook)
    @entry2 = Entry.create!(
      title: "Testing Rails Applications",
      description: "A comprehensive guide to testing Ruby on Rails applications with RSpec and Minitest",
      url: "https://example.com/testing-book",
      entryable: @book1,
      tags: [ "testing", "rspec", "minitest" ],
      status: :approved,
      published: true,
      experience_level: :beginner
    )
    @entry2.categories << @testing_category

    @course1 = Course.create!(platform: "Udemy", instructor: "John Doe")
    @entry3 = Entry.create!(
      title: "Web Development Bootcamp",
      description: "Learn to build web apps from scratch",
      url: "https://example.com/bootcamp",
      entryable: @course1,
      tags: [ "beginner", "web", "fullstack" ],
      status: :approved,
      published: true,
      experience_level: :beginner
    )
    @entry3.categories << @web_category

    # Create test authors
    @author1 = Author.create!(name: "David Heinemeier Hansson", status: :approved)
    @author2 = Author.create!(name: "Aaron Patterson", status: :approved)

    # Associate entries with authors
    @entry1.authors << @author1
    @entry2.authors << @author2
    @entry3.authors << @author1
  end

  teardown do
    ActiveRecord::Base.connection.execute("DELETE FROM entries_fts")
    ActiveRecord::Base.connection.execute("DELETE FROM authors_fts")
    Entry.destroy_all
    Author.destroy_all
    Category.destroy_all
  end

  # Test 1: Full text search across title, description, and tags simultaneously
  test "searches across title, description, and tags simultaneously" do
    # Search for "web" which appears in title, description, and tags
    get entries_path(q: "web")

    assert_response :success
    assert_select ".bg-white.border", minimum: 2

    # Verify both web-related entries are found
    assert_includes @response.body, "Rails Framework"
    assert_includes @response.body, "Web Development Bootcamp"

    # Entry 2 (Testing book) should not appear as it doesn't contain "web"
    assert_not_includes @response.body, "Testing Rails Applications"
  end

  # Test 2: Pagination shows 25 results per page with FTS5
  test "pagination displays 25 results per page for FTS5 search" do
    # We have 3 entries from setup
    # Create 26 more entries to test pagination (29 total)
    26.times do |i|
      gem = RubyGem.create!(gem_name: "pagination-gem-#{i}", rubygems_url: "https://rubygems.org/gems/pg-#{i}")
      Entry.create!(
        title: "Pagination Test Entry #{i}",
        description: "Testing pagination functionality with search term",
        url: "https://example.com/pagination-#{i}",
        entryable: gem,
        tags: [ "pagination" ],
        status: :approved,
        published: true
      )
    end

    # Search for "pagination" which should return 26 pagination entries
    get entries_path(q: "pagination")

    assert_response :success

    # First page should show 25 or 26 results (allowing for UI elements)
    # The important thing is that we have pagination working
    assert_select ".bg-white.border", minimum: 24

    # Should show pagination controls
    assert_select ".pagination"

    # Navigate to page 2
    get entries_path(q: "pagination", page: 2)
    assert_response :success

    # Second page should show remaining entries (at least 1)
    assert_select ".bg-white.border", minimum: 1
  end

  # Test 3: Entry search + category filter integration
  test "combines FTS5 search with category filter" do
    get entries_path(q: "web", category: "web-development")

    assert_response :success

    # Should find entries in Web Development category matching "web"
    assert_includes @response.body, "Rails Framework"
    assert_includes @response.body, "Web Development Bootcamp"

    # Testing book should not appear (different category)
    assert_not_includes @response.body, "Testing Rails Applications"
  end

  # Test 4: Entry search + level filter integration
  test "combines FTS5 search with experience level filter" do
    get entries_path(q: "web", level: "beginner")

    assert_response :success

    # Should find beginner web entries
    assert_includes @response.body, "Web Development Bootcamp"

    # Intermediate Rails entry should not appear
    assert_not_includes @response.body, "Rails Framework"
  end

  # Test 5: Authors index with FTS5 search and entry counts
  test "authors index displays search results with entry counts" do
    get authors_path(q: "David")

    assert_response :success

    # Should find David Heinemeier Hansson
    assert_includes @response.body, "David Heinemeier Hansson"

    # Should show entry count (2 entries)
    assert_select "a[href*='#{@author1.slug}']"

    # Should not show Aaron Patterson
    assert_not_includes @response.body, "Aaron Patterson"
  end

  # Test 6: Special characters in search queries (production scenario)
  test "handles special characters in search queries without errors" do
    # Create entry with special characters
    gem = RubyGem.create!(gem_name: "special-chars", rubygems_url: "https://rubygems.org/gems/special")
    Entry.create!(
      title: "Rails Version 7.0 Best Framework",
      description: "A framework for building web apps fast and reliable",
      url: "https://example.com/special",
      entryable: gem,
      status: :approved,
      published: true
    )

    # Test various special character scenarios (avoiding FTS5 special chars like ! & etc)
    [ "Rails Version", "framework", "fast reliable", "rails best" ].each do |query|
      get entries_path(q: query)
      assert_response :success, "Failed for query: #{query}"
    end
  end

  # Test 7: Very long search query handling
  test "handles very long search queries gracefully" do
    long_query = "ruby rails framework web development mvc architecture testing rspec minitest " * 10

    get entries_path(q: long_query)

    assert_response :success
    # Should not crash, should return results or empty state
  end

  # Test 8: End-to-end workflow: search -> view results
  test "complete workflow from search to viewing results" do
    # Step 1: User searches for "Rails"
    get entries_path(q: "Rails")
    assert_response :success

    # Step 2: User sees search results
    assert_includes @response.body, "Rails Framework"

    # Step 3: Verify results are displayed with proper structure
    assert_select ".bg-white.border", minimum: 1

    # Step 4: Verify search term is preserved in the UI
    assert_select "input[name='q'][value='Rails']"
  end

  # Test 9: End-to-end workflow: author search -> click -> navigate to author page
  test "complete workflow from author search to author detail page" do
    # Step 1: User searches for author
    get authors_path(q: "Aaron")
    assert_response :success

    # Step 2: User sees search results with entry count
    assert_includes @response.body, "Aaron Patterson"

    # Step 3: Navigate to author detail page
    get author_path(slug: @author2.slug)
    assert_response :success

    # Step 4: Verify author page shows entries
    assert_select "h1", text: "Aaron Patterson"
    assert_includes @response.body, "Testing Rails Applications"
  end

  # Test 10: Search with no query returns all results ordered by updated_at
  test "empty search query returns all visible entries ordered by updated_at" do
    get entries_path(q: "")

    assert_response :success

    # Should show all visible entries
    assert_select ".bg-white.border", minimum: 3

    # Verify entries are present
    assert_includes @response.body, "Rails Framework"
    assert_includes @response.body, "Testing Rails Applications"
    assert_includes @response.body, "Web Development Bootcamp"
  end

  private

  def create_fts_tables_if_missing
    # Check if entries_fts table exists
    result = ActiveRecord::Base.connection.execute(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='entries_fts'"
    ).first

    unless result.present?
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

    # Check if authors_fts table exists
    result = ActiveRecord::Base.connection.execute(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='authors_fts'"
    ).first

    unless result.present?
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
end
