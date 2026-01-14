# frozen_string_literal: true

require "test_helper"

class ResourceTypesControllerTest < ActionDispatch::IntegrationTest
  # ====================================================================
  # Resource Type Browse Pages Tests (Task Group 3.1)
  # ====================================================================

  # Test 3.1.1: GET /resources/type/gems returns 200
  test "GET type browse page for gems returns successful response" do
    get resource_type_path("gems")

    assert_response :success
  end

  # Test 3.1.2: Type browse page filters entries by type
  test "GET type browse page filters entries by type" do
    # Create entries of different types
    gem_entry = Entry.create!(
      title: "RSpec Testing Framework",
      url: "https://rspec.info",
      description: "BDD testing framework",
      entryable_type: "RubyGem",
      status: :approved,
      published: true,
      submitter_email: "test@example.com"
    )

    book_entry = Entry.create!(
      title: "The Well-Grounded Rubyist",
      url: "https://manning.com/books/well-grounded-rubyist",
      description: "Comprehensive Ruby guide",
      entryable_type: "Book",
      status: :approved,
      published: true,
      submitter_email: "test@example.com"
    )

    get resource_type_path("gems")

    assert_response :success
    # Should show gem entry
    assert_select "h3", text: "RSpec Testing Framework"
    # Should NOT show book entry
    assert_select "h3", text: "The Well-Grounded Rubyist", count: 0
  end

  # Test 3.1.3: Type browse page works with category filter
  test "GET type browse page works with category filter" do
    testing_category = categories(:testing)

    # Create a gem entry in testing category
    gem_entry = Entry.create!(
      title: "RSpec Testing Framework",
      url: "https://rspec.info",
      description: "BDD testing framework",
      entryable_type: "RubyGem",
      status: :approved,
      published: true,
      submitter_email: "test@example.com"
    )
    gem_entry.categories << testing_category

    # Create another gem entry in different category
    other_gem = Entry.create!(
      title: "Rails Framework",
      url: "https://rubyonrails.org",
      description: "Web framework",
      entryable_type: "RubyGem",
      status: :approved,
      published: true,
      submitter_email: "test@example.com"
    )
    other_gem.categories << categories(:web_development)

    get resource_type_path("gems"), params: { category: "testing" }

    assert_response :success
    # Should show gem in testing category
    assert_select "h3", text: "RSpec Testing Framework"
    # Should NOT show gem in other category
    assert_select "h3", text: "Rails Framework", count: 0
  end

  # Test 3.1.4: Type browse page works with level filter
  test "GET type browse page works with level filter" do
    # Create gem entries with different experience levels
    beginner_gem = Entry.create!(
      title: "Learn Ruby the Hard Way",
      url: "https://learnrubythehardway.org",
      description: "Beginner Ruby tutorial",
      entryable_type: "Book",
      experience_level: :beginner,
      status: :approved,
      published: true,
      submitter_email: "test@example.com"
    )

    advanced_gem = Entry.create!(
      title: "Metaprogramming Ruby",
      url: "https://pragprog.com/titles/ppmetr2",
      description: "Advanced Ruby techniques",
      entryable_type: "Book",
      experience_level: :advanced,
      status: :approved,
      published: true,
      submitter_email: "test@example.com"
    )

    get resource_type_path("books"), params: { level: "beginner" }

    assert_response :success
    # Should show beginner book
    assert_select "h3", text: "Learn Ruby the Hard Way"
    # Should NOT show advanced book
    assert_select "h3", text: "Metaprogramming Ruby", count: 0
  end

  # Test 3.1.5: Type browse page shows entry count
  test "GET type browse page shows entry count" do
    # Create 3 gem entries
    3.times do |i|
      Entry.create!(
        title: "Test Gem #{i + 1}",
        url: "https://example.com/gem-#{i + 1}",
        description: "Test gem description",
        entryable_type: "RubyGem",
        status: :approved,
        published: true,
        submitter_email: "test@example.com"
      )
    end

    get resource_type_path("gems")

    assert_response :success
    # Should display count (exact text will depend on view implementation)
    # Looking for a pattern like "3 curated gems" or "3 Ruby Gems"
    assert_select "p", text: /3.*gem/i
  end

  # Test 3.1.6: Invalid type parameter returns 404
  test "GET type browse page with invalid type returns 404" do
    get resource_type_path("invalid_type")

    assert_response :not_found
  end

  # Test 3.1.7: Pagination works on type browse pages
  test "GET type browse page pagination works correctly" do
    # Create 30 gem entries (more than 25 per page)
    30.times do |i|
      Entry.create!(
        title: "Test Gem #{i + 1}",
        url: "https://example.com/gem-#{i + 1}",
        description: "Test gem description",
        entryable_type: "RubyGem",
        status: :approved,
        published: true,
        submitter_email: "test@example.com"
      )
    end

    # Get first page
    get resource_type_path("gems")
    assert_response :success
    # Should show 25 entries on first page
    assert_select "article.border-gray-200", count: 25

    # Get second page
    get resource_type_path("gems"), params: { page: 2 }
    assert_response :success
    # Should show remaining 5 entries on second page
    assert_select "article.border-gray-200", count: 5
  end

  # Test 3.1.8: Type browse page works with search query
  test "GET type browse page works with search query" do
    # Create gem entries with different content
    rspec_gem = Entry.create!(
      title: "RSpec Testing Framework",
      url: "https://rspec.info",
      description: "BDD testing framework for Ruby",
      entryable_type: "RubyGem",
      status: :approved,
      published: true,
      submitter_email: "test@example.com"
    )

    rails_gem = Entry.create!(
      title: "Ruby on Rails",
      url: "https://rubyonrails.org",
      description: "Full-stack web framework",
      entryable_type: "RubyGem",
      status: :approved,
      published: true,
      submitter_email: "test@example.com"
    )

    get resource_type_path("gems"), params: { q: "testing" }

    assert_response :success
    # Should find RSpec (contains "testing")
    assert_select "h3", text: "RSpec Testing Framework"
    # Should NOT find Rails (no "testing" in content)
    assert_select "h3", text: "Ruby on Rails", count: 0
  end

  # ====================================================================
  # Enhanced Browse Pages Tests (Task Group 5.1)
  # ====================================================================

  # Test 5.1.1: Type browse page includes featured entries section when featured entries exist
  test "GET type browse page displays featured entries section" do
    testing_category = categories(:testing)

    # Create a featured gem entry
    featured_gem = Entry.create!(
      title: "Featured Gem",
      url: "https://example.com/featured-gem",
      description: "Featured testing framework",
      entryable_type: "RubyGem",
      status: :approved,
      published: true,
      featured_at: 1.day.ago,
      submitter_email: "test@example.com"
    )
    featured_gem.categories << testing_category

    # Create a non-featured gem entry
    regular_gem = Entry.create!(
      title: "Regular Gem",
      url: "https://example.com/regular-gem",
      description: "Regular testing framework",
      entryable_type: "RubyGem",
      status: :approved,
      published: true,
      submitter_email: "test@example.com"
    )
    regular_gem.categories << testing_category

    get resource_type_path("gems")

    assert_response :success
    # Should have a featured section
    assert_select ".featured-entries", count: 1
    # Featured entry should appear in featured section
    assert_match(/Featured Gem/, response.body)
  end

  # Test 5.1.2: Type browse page displays category stats panel
  test "GET type browse page displays category stats panel" do
    testing_category = categories(:testing)
    web_dev_category = categories(:web_development)

    # Create 3 gem entries in testing category
    3.times do |i|
      gem = Entry.create!(
        title: "Testing Gem #{i + 1}",
        url: "https://example.com/testing-gem-#{i + 1}",
        description: "Testing framework",
        entryable_type: "RubyGem",
        status: :approved,
        published: true,
        submitter_email: "test@example.com"
      )
      gem.categories << testing_category
    end

    # Create 2 gem entries in web development category
    2.times do |i|
      gem = Entry.create!(
        title: "Web Dev Gem #{i + 1}",
        url: "https://example.com/webdev-gem-#{i + 1}",
        description: "Web development framework",
        entryable_type: "RubyGem",
        status: :approved,
        published: true,
        submitter_email: "test@example.com"
      )
      gem.categories << web_dev_category
    end

    get resource_type_path("gems")

    assert_response :success
    # Should have a stats panel
    assert_select ".stats-panel", count: 1
    # Stats panel should show category breakdowns - Testing appears first with 3
    assert_select ".stats-panel", text: /Testing/
    assert_select ".stats-panel", text: /3/
  end

  # Test 5.1.3: Type browse page supports grid view layout
  test "GET type browse page renders with grid view layout by default" do
    # Create a gem entry
    Entry.create!(
      title: "Test Gem",
      url: "https://example.com/test-gem",
      description: "Test gem description",
      entryable_type: "RubyGem",
      status: :approved,
      published: true,
      submitter_email: "test@example.com"
    )

    get resource_type_path("gems")

    assert_response :success
    # Should have grid layout container
    assert_select "[data-view-toggle-target='container']"
    # Default view should be grid
    assert_select "[data-view-mode='grid']"
  end

  # Test 5.1.4: Featured entries ordered by featured_at descending
  test "GET type browse page orders featured entries by most recently featured" do
    testing_category = categories(:testing)

    # Create featured entries with different featured_at timestamps
    older_featured = Entry.create!(
      title: "Older Featured Gem",
      url: "https://example.com/older-featured",
      description: "Older featured gem",
      entryable_type: "RubyGem",
      status: :approved,
      published: true,
      featured_at: 7.days.ago,
      submitter_email: "test@example.com"
    )
    older_featured.categories << testing_category

    newer_featured = Entry.create!(
      title: "Newer Featured Gem",
      url: "https://example.com/newer-featured",
      description: "Newer featured gem",
      entryable_type: "RubyGem",
      status: :approved,
      published: true,
      featured_at: 1.day.ago,
      submitter_email: "test@example.com"
    )
    newer_featured.categories << testing_category

    get resource_type_path("gems")

    assert_response :success
    # Newer featured entry should appear before older featured entry in response body
    newer_position = response.body.index("Newer Featured Gem")
    older_position = response.body.index("Older Featured Gem")
    assert newer_position < older_position, "Newer featured entry should appear before older featured entry"
  end

  # Test 5.1.5: Stats panel shows correct category counts for specific type
  test "GET type browse page stats panel filters by current type only" do
    testing_category = categories(:testing)

    # Create 3 gem entries in testing category
    3.times do |i|
      gem = Entry.create!(
        title: "Gem #{i + 1}",
        url: "https://example.com/gem-#{i + 1}",
        description: "Testing gem",
        entryable_type: "RubyGem",
        status: :approved,
        published: true,
        submitter_email: "test@example.com"
      )
      gem.categories << testing_category
    end

    # Create 2 book entries in testing category (should NOT be counted in gems stats)
    2.times do |i|
      book = Entry.create!(
        title: "Book #{i + 1}",
        url: "https://example.com/book-#{i + 1}",
        description: "Testing book",
        entryable_type: "Book",
        status: :approved,
        published: true,
        submitter_email: "test@example.com"
      )
      book.categories << testing_category
    end

    get resource_type_path("gems")

    assert_response :success
    # Stats panel should show 3 for testing category (not 5)
    assert_select ".stats-panel", text: /Testing/
    assert_select ".stats-panel", text: /3/
  end
end
