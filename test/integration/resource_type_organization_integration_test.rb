# frozen_string_literal: true

require "test_helper"

# Task 7.3: Strategic integration tests for Resource Type Organization feature
# Testing critical workflows and integration points that weren't fully covered
class ResourceTypeOrganizationIntegrationTest < ActionDispatch::IntegrationTest
  # Test 7.3.1: End-to-end workflow for creating entries with all 11 new types
  test "can create and display entries for all 11 new delegated types end-to-end" do
    # Create one entry for each new type and verify it displays on homepage and browse pages
    new_types = [
      { type: Newsletter, slug: "newsletters", title: "Ruby Weekly" },
      { type: Blog, slug: "blogs", title: "Ruby Blog" },
      { type: Video, slug: "videos", title: "Ruby Video" },
      { type: Channel, slug: "channels", title: "Ruby Channel" },
      { type: Documentation, slug: "documentations", title: "Ruby Docs" },
      { type: TestingResource, slug: "testing-resources", title: "RSpec Guide" },
      { type: DevelopmentEnvironment, slug: "development-environments", title: "Ruby Dev Setup" },
      { type: Job, slug: "jobs", title: "Senior Ruby Developer" },
      { type: Framework, slug: "frameworks", title: "Rails Framework" },
      { type: Directory, slug: "directories", title: "Ruby Resources Directory" },
      { type: Product, slug: "products", title: "Ruby Product" }
    ]

    new_types.each do |type_info|
      # Create entryable
      entryable = type_info[:type].create!(
        name: type_info[:title]
      )

      # Create entry
      entry = Entry.create!(
        title: type_info[:title],
        description: "Test #{type_info[:slug]}",
        url: "https://example.com/#{type_info[:slug]}",
        entryable: entryable,
        status: :approved,
        published: true
      )

      # Verify entry is visible on homepage
      get root_path
      assert_response :success
      assert_match type_info[:title], response.body

      # Verify entry is visible on browse page
      get resource_type_path(type_info[:slug])
      assert_response :success
      assert_match type_info[:title], response.body
    end
  end

  # Test 7.3.2: Featured entries display correctly across different types
  test "featured entries appear in featured section and are filtered by type" do
    testing_category = categories(:testing)

    # Create featured newsletter
    newsletter = Newsletter.create!(name: "Test Newsletter")
    featured_newsletter = Entry.create!(
      title: "Featured Newsletter",
      description: "Featured content",
      url: "https://example.com/featured-newsletter",
      entryable: newsletter,
      status: :approved,
      published: true,
      featured_at: 1.day.ago
    )
    featured_newsletter.categories << testing_category

    # Create featured gem (different type)
    gem = RubyGem.create!(gem_name: "featured-gem")
    featured_gem = Entry.create!(
      title: "Featured Gem",
      description: "Featured gem",
      url: "https://example.com/featured-gem",
      entryable: gem,
      status: :approved,
      published: true,
      featured_at: 2.days.ago
    )
    featured_gem.categories << testing_category

    # Visit newsletters page - should only show featured newsletter
    get resource_type_path("newsletters")
    assert_response :success
    assert_match "Featured Newsletter", response.body
    assert_select ".featured-entries" do
      assert_select "h3", text: "Featured Newsletter"
      # Should NOT show featured gem (different type)
      assert_select "h3", text: "Featured Gem", count: 0
    end

    # Visit gems page - should only show featured gem
    get resource_type_path("gems")
    assert_response :success
    assert_match "Featured Gem", response.body
    assert_select ".featured-entries" do
      assert_select "h3", text: "Featured Gem"
      # Should NOT show featured newsletter (different type)
      assert_select "h3", text: "Featured Newsletter", count: 0
    end
  end

  # Test 7.3.3: Homepage conditional display with exact entry counts (0, 1, 2, 3, 4)
  test "homepage displays sections correctly based on exact entry counts" do
    # Test 0 entries - section should be hidden
    get root_path
    assert_response :success
    assert_select "h2", { text: /Newsletters/i, count: 0 }

    # Test 1 entry - section shows with submission message
    newsletter1 = Newsletter.create!(name: "Test Newsletter")
    Entry.create!(
      title: "One Newsletter",
      description: "First newsletter",
      url: "https://example.com/newsletter-1",
      entryable: newsletter1,
      status: :approved,
      published: true
    )
    get root_path
    assert_response :success
    assert_select "h2", text: /Newsletters/i
    assert_match /Know a great Ruby newsletter/i, response.body

    # Test 3 entries - section shows with submission message
    2.times do |i|
      newsletter = Newsletter.create!(name: "Test Newsletter")
      Entry.create!(
        title: "Newsletter #{i + 2}",
        description: "Newsletter content",
        url: "https://example.com/newsletter-#{i + 2}",
        entryable: newsletter,
        status: :approved,
        published: true
      )
    end
    get root_path
    assert_response :success
    assert_select "h2", text: /Newsletters/i
    assert_match /Know a great Ruby newsletter/i, response.body

    # Test 4 entries - section shows WITHOUT submission message
    newsletter4 = Newsletter.create!(name: "Test Newsletter")
    Entry.create!(
      title: "Newsletter 4",
      description: "Fourth newsletter",
      url: "https://example.com/newsletter-4",
      entryable: newsletter4,
      status: :approved,
      published: true
    )
    get root_path
    assert_response :success
    assert_select "h2", text: /Newsletters/i
    assert_no_match /Know a great Ruby newsletter/i, response.body
  end

  # Test 7.3.4: Stats panel accuracy with multiple categories and types
  test "stats panel shows accurate category counts for specific type across multiple categories" do
    testing_category = categories(:testing)
    web_dev_category = categories(:web_development)
    background_jobs_category = categories(:background_jobs)

    # Create 5 frameworks in testing category
    5.times do |i|
      framework = Framework.create!(name: "Test Framework")
      entry = Entry.create!(
        title: "Testing Framework #{i + 1}",
        description: "Framework for testing",
        url: "https://example.com/framework-#{i + 1}",
        entryable: framework,
        status: :approved,
        published: true
      )
      entry.categories << testing_category
    end

    # Create 3 frameworks in web dev category
    3.times do |i|
      framework = Framework.create!(name: "Test Framework")
      entry = Entry.create!(
        title: "Web Framework #{i + 1}",
        description: "Framework for web",
        url: "https://example.com/web-framework-#{i + 1}",
        entryable: framework,
        status: :approved,
        published: true
      )
      entry.categories << web_dev_category
    end

    # Create 2 frameworks in background jobs category
    2.times do |i|
      framework = Framework.create!(name: "Test Framework")
      entry = Entry.create!(
        title: "Background Framework #{i + 1}",
        description: "Framework for background jobs",
        url: "https://example.com/background-framework-#{i + 1}",
        entryable: framework,
        status: :approved,
        published: true
      )
      entry.categories << background_jobs_category
    end

    # Visit frameworks browse page
    get resource_type_path("frameworks")
    assert_response :success

    # Verify stats panel shows correct counts
    assert_select ".stats-panel" do
      assert_select "span", text: /Testing/
      assert_select "span", text: /5/
      assert_select "span", text: /Web Development/
      assert_select "span", text: /3/
      assert_select "span", text: /Background Jobs/
      assert_select "span", text: /2/
    end
  end

  # Test 7.3.5: Submission messages work for all new types
  test "submission messages display correctly for all new types" do
    # Test submission messages for types with 1-3 entries
    types_to_test = [
      { type: Blog, slug: "blogs", expected_singular: "blog" },
      { type: Video, slug: "videos", expected_singular: "video" },
      { type: Framework, slug: "frameworks", expected_singular: "framework" },
      { type: Product, slug: "products", expected_singular: "product" },
      { type: Job, slug: "jobs", expected_singular: "job" }
    ]

    types_to_test.each do |type_info|
      # Create exactly 2 entries (within 1-3 range)
      2.times do |i|
        entryable = type_info[:type].create!(
          name: "#{type_info[:expected_singular].capitalize} #{i + 1}"
        )
        Entry.create!(
          title: "#{type_info[:slug]} #{i + 1}",
          description: "Test entry",
          url: "https://example.com/#{type_info[:slug]}-#{i + 1}",
          entryable: entryable,
          status: :approved,
          published: true
        )
      end

      get root_path
      assert_response :success
      # Verify submission message includes the singular form
      assert_match /Know a great Ruby #{type_info[:expected_singular]}/i, response.body
      assert_select "a[href=?]", new_resource_submission_path, text: /Submit it here/i
    end
  end

  # Test 7.3.6: Grid view data attributes are present for Stimulus controller
  test "browse page includes data attributes for grid/list view toggle" do
    # Create a framework entry
    framework = Framework.create!(name: "Test Framework")
    Entry.create!(
      title: "Test Framework",
      description: "Test framework for grid/list toggle",
      url: "https://example.com/test-framework",
      entryable: framework,
      status: :approved,
      published: true
    )

    get resource_type_path("frameworks")
    assert_response :success

    # Verify Stimulus controller data attributes exist
    assert_select "[data-controller='view-toggle']"
    assert_select "[data-view-toggle-target='container']"
    assert_select "[data-view-mode='grid']"
  end

  # Test 7.3.7: Entry with multiple categories displays in stats panel correctly
  test "entry with multiple categories is counted correctly in stats panel" do
    testing_category = categories(:testing)
    web_dev_category = categories(:web_development)

    # Create a product with multiple categories
    product = Product.create!(name: "Test Product")
    entry = Entry.create!(
      title: "Multi-Category Product",
      description: "Product in multiple categories",
      url: "https://example.com/multi-category",
      entryable: product,
      status: :approved,
      published: true
    )
    entry.categories << testing_category
    entry.categories << web_dev_category

    # Create another product only in testing
    product2 = Product.create!(name: "Test Product")
    entry2 = Entry.create!(
      title: "Testing Only Product",
      description: "Product only in testing",
      url: "https://example.com/testing-only",
      entryable: product2,
      status: :approved,
      published: true
    )
    entry2.categories << testing_category

    get resource_type_path("products")
    assert_response :success

    # Stats panel should count each category association
    # Multi-category entry should appear in both category counts
    assert_select ".stats-panel" do
      assert_select "span", text: /Testing/
      assert_select "span", text: /2/ # Both entries are in testing
      assert_select "span", text: /Web Development/
      assert_select "span", text: /1/ # Only one entry in web dev
    end
  end

  # Test 7.3.8: Browse pages work correctly for all 11 new types
  test "browse pages return successful responses for all new types" do
    new_type_slugs = [
      "newsletters", "blogs", "videos", "channels", "documentations",
      "testing-resources", "development-environments", "jobs",
      "frameworks", "directories", "products"
    ]

    new_type_slugs.each do |slug|
      get resource_type_path(slug)
      assert_response :success, "Browse page for #{slug} should return success"
      # Verify page includes type-specific heading
      assert_select "h1"
    end
  end

  # Test 7.3.9: Featured entries section is hidden when no featured entries exist
  test "featured entries section does not appear when no entries are featured" do
    # Create regular (non-featured) job entry
    job = Job.create!(name: "Test Job")
    Entry.create!(
      title: "Regular Job",
      description: "Non-featured job",
      url: "https://example.com/regular-job",
      entryable: job,
      status: :approved,
      published: true,
      featured_at: nil
    )

    get resource_type_path("jobs")
    assert_response :success

    # Featured section should not appear
    assert_select ".featured-entries", count: 0
  end

  # Test 7.3.10: Type scopes work with pagination on browse pages
  test "browse page pagination maintains type filtering correctly" do
    # Create 30 development environment entries (more than 25 per page)
    30.times do |i|
      dev_env = DevelopmentEnvironment.create!(name: "Test Dev Environment")
      Entry.create!(
        title: "Dev Environment #{i + 1}",
        description: "Development environment setup",
        url: "https://example.com/dev-env-#{i + 1}",
        entryable: dev_env,
        status: :approved,
        published: true
      )
    end

    # Create a gem entry to verify type filtering works
    gem = RubyGem.create!(gem_name: "test-gem")
    Entry.create!(
      title: "Test Gem",
      description: "Should not appear on dev environments page",
      url: "https://example.com/test-gem",
      entryable: gem,
      status: :approved,
      published: true
    )

    # Check first page
    get resource_type_path("development-environments")
    assert_response :success
    assert_select "article.border-gray-200", count: 25
    # Verify gem doesn't appear
    assert_no_match "Test Gem", response.body

    # Check second page
    get resource_type_path("development-environments"), params: { page: 2 }
    assert_response :success
    assert_select "article.border-gray-200", count: 5
    # Verify gem doesn't appear on second page either
    assert_no_match "Test Gem", response.body
  end
end
