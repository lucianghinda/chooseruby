# frozen_string_literal: true

require "test_helper"
require "cgi"

# Integration tests for Resource Type Organization feature
# Tests critical end-to-end workflows across controllers, views, and models
class ResourceTypeWorkflowsTest < ActionDispatch::IntegrationTest
  # Task 7.3.1: Integration test - type browse page + category filter + pagination
  test "user can browse by type, filter by category, and paginate results" do
    # Create test category
    testing_category = Category.create!(
      name: "Testing Integration",
      slug: "testing-integration",
      description: "Testing category for integration tests"
    )

    # Create 30 gem entries in testing category
    30.times do |i|
      gem = RubyGem.create!(gem_name: "test-gem-#{i}")
      entry = Entry.create!(
        title: "Test Gem #{i}",
        url: "https://example.com/gem-#{i}",
        description: "Test gem description",
        entryable: gem,
        status: :approved,
        published: true
      )
      entry.categories << testing_category
    end

    # Create gem entries NOT in testing category
    5.times do |i|
      gem = RubyGem.create!(gem_name: "other-gem-#{i}")
      Entry.create!(
        title: "Other Gem #{i}",
        url: "https://example.com/other-#{i}",
        description: "Other gem",
        entryable: gem,
        status: :approved,
        published: true
      )
    end

    # Step 1: Browse gems by type
    get resource_type_path("gems")
    assert_response :success
    assert_select "h1", text: /Gems Directory/i

    # Step 2: Filter by category
    get resource_type_path("gems"), params: { category: "testing-integration" }
    assert_response :success
    # Should show only gems in testing category (25 on page 1)
    assert_select "article.border-gray-200", count: 25
    # Verify category filter is active
    assert_select ".bg-slate-900", text: "Testing Integration"

    # Step 3: Navigate to page 2
    get resource_type_path("gems"), params: { category: "testing-integration", page: 2 }
    assert_response :success
    # Should show remaining 5 entries
    assert_select "article.border-gray-200", count: 5
  end

  # Task 7.3.2: Integration test - homepage type section links to browse page with correct filter
  test "homepage type section links correctly to type browse pages" do
    # Create entries for multiple types
    gem = RubyGem.create!(gem_name: "test-gem")
    Entry.create!(
      title: "Test Gem",
      url: "https://example.com/gem",
      description: "A gem",
      entryable: gem,
      status: :approved,
      published: true
    )

    book = Book.create!
    Entry.create!(
      title: "Test Book",
      url: "https://example.com/book",
      description: "A book",
      entryable: book,
      status: :approved,
      published: true
    )

    # Visit homepage
    get root_path
    assert_response :success

    # Verify "View all" links exist for type sections
    assert_select "a[href='#{resource_type_path("gems")}']", text: /View all/i
    assert_select "a[href='#{resource_type_path("books")}']", text: /View all/i

    # Follow link to gems browse page
    get resource_type_path("gems")
    assert_response :success
    assert_select "h1", text: /Gems Directory/i
    assert_select "article", text: /Test Gem/i
    assert_select "article", { text: /Test Book/i, count: 0 }
  end

  # Task 7.3.3: Test - Entry type scopes work with strict_loading
  test "type scopes are compatible with strict_loading" do
    # Create gem entry with associations
    category = Category.create!(name: "Test Category", slug: "test-category")
    author = Author.create!(name: "Test Author")
    gem = RubyGem.create!(gem_name: "strict-test")
    entry = Entry.create!(
      title: "Strict Loading Gem",
      url: "https://example.com/strict",
      description: "Testing strict loading",
      entryable: gem,
      status: :approved,
      published: true
    )
    entry.categories << category
    entry.authors << author

    # Query with strict_loading enabled
    entries = Entry.gems.with_directory_includes.strict_loading

    # Should not raise errors when accessing preloaded associations
    assert_nothing_raised do
      entries.each do |e|
        e.categories.to_a
        e.authors.to_a
        e.entryable.gem_name if e.entryable.present?
      end
    end

    # Should raise error when accessing non-preloaded association
    assert_raises(ActiveRecord::StrictLoadingViolationError) do
      entries.each do |e|
        e.entry_reviews.to_a # This is NOT included in with_directory_includes
      end
    end
  end

  # Task 7.3.4: Test - type-specific metadata renders for all 8 types
  test "type-specific metadata renders correctly for all resource types" do
    # Create entries for each type with metadata

    # 1. RubyGem
    gem = RubyGem.create!(gem_name: "metadata-gem")
    gem_entry = Entry.create!(
      title: "Metadata Gem",
      url: "https://example.com/gem",
      entryable: gem,
      status: :approved,
      published: true
    )

    # 2. Book
    book = Book.create!(
      publication_year: 2023,
      publisher: "O'Reilly",
      format: "ebook"
    )
    book_entry = Entry.create!(
      title: "Metadata Book",
      url: "https://example.com/book",
      entryable: book,
      status: :approved,
      published: true
    )

    # 3. Course
    course = Course.create!(
      platform: "Udemy",
      instructor: "Test Instructor",
      duration_hours: 10
    )
    course_entry = Entry.create!(
      title: "Metadata Course",
      url: "https://example.com/course",
      entryable: course,
      status: :approved,
      published: true
    )

    # 4. Tutorial
    tutorial = Tutorial.create!(
      platform: "YouTube",
      publication_date: Date.new(2023, 6, 1),
      reading_time_minutes: 30
    )
    tutorial_entry = Entry.create!(
      title: "Metadata Tutorial",
      url: "https://example.com/tutorial",
      entryable: tutorial,
      status: :approved,
      published: true
    )

    # 5. Article
    article = Article.create!(
      platform: "Dev.to",
      publication_date: Date.new(2023, 7, 1),
      reading_time_minutes: 15
    )
    article_entry = Entry.create!(
      title: "Metadata Article",
      url: "https://example.com/article",
      entryable: article,
      status: :approved,
      published: true
    )

    # 6. Tool
    tool = Tool.create!(tool_type: "CLI")
    tool_entry = Entry.create!(
      title: "Metadata Tool",
      url: "https://example.com/tool",
      entryable: tool,
      status: :approved,
      published: true
    )

    # 7. Podcast
    podcast = Podcast.create!(host: "Test Host")
    podcast_entry = Entry.create!(
      title: "Metadata Podcast",
      url: "https://example.com/podcast",
      entryable: podcast,
      status: :approved,
      published: true
    )

    # 8. Community
    community = Community.create!(
      platform: "Discord",
      join_url: "https://discord.gg/test"
    )
    community_entry = Entry.create!(
      title: "Metadata Community",
      url: "https://example.com/community",
      entryable: community,
      status: :approved,
      published: true
    )

    # Visit each type browse page and verify metadata renders

    # Books should show year, publisher, format
    get resource_type_path("books")
    assert_response :success
    page = CGI.unescapeHTML(response.body)
    assert_match(/2023/, page)
    assert_match(/O'Reilly/, page)
    assert_match(/Ebook/, page)

    # Courses should show platform, instructor, duration
    get resource_type_path("courses")
    assert_response :success
    page = CGI.unescapeHTML(response.body)
    assert_match(/Udemy/, page)
    assert_match(/Test Instructor/, page)
    assert_match(/10(\.0)? hours/, page)

    # Tutorials should show platform, date, reading time
    get resource_type_path("tutorials")
    assert_response :success
    page = CGI.unescapeHTML(response.body)
    assert_match(/YouTube/, page)
    assert_match(/June 2023/, page)
    assert_match(/30 min read/, page)

    # Articles should show platform, date, reading time
    get resource_type_path("articles")
    assert_response :success
    page = CGI.unescapeHTML(response.body)
    assert_match(/Dev\.to/, page)
    assert_match(/July 2023/, page)
    assert_match(/15 min read/, page)

    # Tools should show tool_type
    get resource_type_path("tools")
    assert_response :success
    page = CGI.unescapeHTML(response.body)
    assert_match(/CLI/, page)

    # Podcasts should show host
    get resource_type_path("podcasts")
    assert_response :success
    page = CGI.unescapeHTML(response.body)
    assert_match(/Hosted by Test Host/, page)

    # Communities should show platform
    get resource_type_path("communities")
    assert_response :success
    page = CGI.unescapeHTML(response.body)
    assert_match(/Discord community/, page)
  end

  # Task 7.3.5: Test - invalid type parameter handling in controller
  test "invalid type parameter returns 404 with helpful error" do
    get resource_type_path("invalid_type_xyz")

    assert_response :not_found
  end

  # Task 7.3.6: Test - type filtering combined with all filters (integration)
  test "type filtering works correctly with category, level, and search filters combined" do
    # Create testing category
    testing_cat = Category.create!(name: "Testing Combo", slug: "testing-combo")

    # Create beginner gem in testing category matching search term "rspec"
    gem1 = RubyGem.create!(gem_name: "rspec-rails")
    entry1 = Entry.create!(
      title: "RSpec Rails",
      description: "Testing framework for Rails applications",
      url: "https://rspec.info/rails",
      entryable: gem1,
      experience_level: :beginner,
      status: :approved,
      published: true
    )
    entry1.categories << testing_cat

    # Create intermediate gem in testing category NOT matching search
    gem2 = RubyGem.create!(gem_name: "minitest")
    entry2 = Entry.create!(
      title: "Minitest",
      description: "Alternative testing framework",
      url: "https://minitest.info",
      entryable: gem2,
      experience_level: :intermediate,
      status: :approved,
      published: true
    )
    entry2.categories << testing_cat

    # Create beginner book in testing category matching search
    book = Book.create!
    entry3 = Entry.create!(
      title: "RSpec Book",
      description: "Learn RSpec testing",
      url: "https://example.com/book",
      entryable: book,
      experience_level: :beginner,
      status: :approved,
      published: true
    )
    entry3.categories << testing_cat

    # Query: type=gems + category=testing-combo + level=beginner + q=rspec
    get resource_type_path("gems"), params: {
      category: "testing-combo",
      level: "beginner",
      q: "rspec"
    }

    assert_response :success
    # Should ONLY show entry1 (beginner gem in testing category matching "rspec")
    assert_select "h3", text: "RSpec Rails"
    assert_select "h3", { text: "Minitest", count: 0 } # Wrong level
    assert_select "h3", { text: "RSpec Book", count: 0 } # Wrong type
  end

  # Task 7.3.7: Test - homepage sections only load recent entries efficiently
  test "homepage type sections query only necessary data" do
    # Create entries with different timestamps for gems and books
    gem = RubyGem.create!(gem_name: "old-gem")
    Entry.create!(
      title: "Old Gem",
      url: "https://example.com/old-gem",
      entryable: gem,
      status: :approved,
      published: true,
      updated_at: 3.days.ago
    )

    [ 1, 2, 3, 4, 5 ].each do |i|
      gem = RubyGem.create!(gem_name: "recent-gem-#{i}")
      Entry.create!(
        title: "Recent Gem #{i}",
        url: "https://example.com/gem-#{i}",
        entryable: gem,
        status: :approved,
        published: true,
        updated_at: i.hours.ago
      )
    end

    get root_path
    assert_response :success

    # Should show only 4 most recent gems (not all 6)
    gems_section = css_select("section").find do |section|
      heading = section.at("h2")
      heading&.text&.include?("Ruby Gems")
    end

    assert_not_nil gems_section, "Ruby Gems type section should render"
    assert_select gems_section, "a.rounded-3xl", count: 4
    assert_select gems_section, "h3", text: "Recent Gem 1"
    assert_select gems_section, "h3", text: "Recent Gem 4"
    # Old gem and the 5th recent gem should be excluded from the type section
    assert_select gems_section, "h3", text: "Old Gem", count: 0
    assert_select gems_section, "h3", text: "Recent Gem 5", count: 0
  end

  # Task 7.3.8: Test - navigation dropdown shows all types
  test "browse by type navigation includes all 8 types with emojis" do
    get root_path
    assert_response :success

    # Verify all 8 types are in navigation
    assert_match(/💎.*Gems/m, response.body)
    assert_match(/📚.*Books/m, response.body)
    assert_match(/🎓.*Courses/m, response.body)
    assert_match(/📝.*Tutorials/m, response.body)
    assert_match(/📰.*Articles/m, response.body)
    assert_match(/🛠️.*Tools/m, response.body)
    assert_match(/🎙️.*Podcasts/m, response.body)
    assert_match(/👥.*Communities/m, response.body)

    # Verify all links point to correct paths
    Entry::VALID_TYPES.keys.each do |type|
      assert_select "a[href='#{resource_type_path(type)}']", minimum: 1
    end
  end

  # Task 7.3.9: Test - type browse pages maintain query params across filter changes
  test "type browse pages preserve search query when changing filters" do
    testing_cat = Category.create!(name: "Preservation Test", slug: "preservation-test")

    gem = RubyGem.create!(gem_name: "search-gem")
    entry = Entry.create!(
      title: "Search Gem",
      description: "Searchable gem for testing",
      url: "https://example.com/search",
      entryable: gem,
      experience_level: :beginner,
      status: :approved,
      published: true
    )
    entry.categories << testing_cat

    # Initial search query
    get resource_type_path("gems"), params: { q: "search" }
    assert_response :success
    assert_select "input[value='search']"

    # Verify category filter links preserve search query
    assert_select "a[href*='q=search'][href*='category=preservation-test']"

    # Verify level filter links preserve search query
    assert_select "a[href*='q=search'][href*='level=beginner']"
  end

  # Task 7.3.10: Test - type scope filters exclude non-visible entries
  test "type scopes only return visible entries (published and approved)" do
    # Create visible gem
    visible_gem = RubyGem.create!(gem_name: "visible-gem")
    visible_entry = Entry.create!(
      title: "Visible Gem",
      url: "https://example.com/visible",
      entryable: visible_gem,
      status: :approved,
      published: true
    )

    # Create non-visible gems
    unpublished_gem = RubyGem.create!(gem_name: "unpublished")
    Entry.create!(
      title: "Unpublished Gem",
      url: "https://example.com/unpublished",
      entryable: unpublished_gem,
      status: :approved,
      published: false
    )

    pending_gem = RubyGem.create!(gem_name: "pending")
    Entry.create!(
      title: "Pending Gem",
      url: "https://example.com/pending",
      entryable: pending_gem,
      status: :pending,
      published: true,
      submitter_email: "test@example.com"
    )

    rejected_gem = RubyGem.create!(gem_name: "rejected")
    Entry.create!(
      title: "Rejected Gem",
      url: "https://example.com/rejected",
      entryable: rejected_gem,
      status: :rejected,
      published: true
    )

    # Browse gems page should only show visible entry
    get resource_type_path("gems")
    assert_response :success
    assert_select "h3", text: "Visible Gem"
    assert_select "h3", { text: "Unpublished Gem", count: 0 }
    assert_select "h3", { text: "Pending Gem", count: 0 }
    assert_select "h3", { text: "Rejected Gem", count: 0 }

    # Verify via scope query
    gems = Entry.gems.visible
    assert_includes gems, visible_entry
    assert_equal 1, gems.count
  end
end
