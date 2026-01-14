# frozen_string_literal: true

require "application_system_test_case"

class ResourceDetailPagesTest < ApplicationSystemTestCase
  setup do
    # Create categories for testing
    @category1 = categories(:testing)
    @category2 = categories(:authentication)

    # Create author
    @author = Author.create!(
      name: "Test Author",
      slug: "test-author-#{SecureRandom.hex(4)}",
      status: :approved
    )

    # Create main entry
    @ruby_gem = RubyGem.create!(gem_name: "test-gem-#{SecureRandom.hex(4)}")
    @entry = Entry.create!(
      title: "Test Resource #{SecureRandom.hex(4)}",
      url: "https://example.com/test-resource",
      entryable: @ruby_gem,
      status: :approved,
      published: true,
      experience_level: :intermediate
    )
    @entry.description = "This is a comprehensive guide to testing in Ruby with detailed examples and best practices."
    @entry.categories << [ @category1, @category2 ]
    @entry.authors << @author

    # Create related resources
    3.times do |i|
      gem = RubyGem.create!(gem_name: "related-gem-#{i}-#{SecureRandom.hex(4)}")
      related = Entry.create!(
        title: "Related Resource #{i} #{SecureRandom.hex(4)}",
        url: "https://example.com/related-#{i}",
        entryable: gem,
        status: :approved,
        published: true,
        experience_level: :beginner,
        updated_at: i.hours.ago
      )
      related.description = "Related resource description #{i}"
      related.categories << @category1
    end
  end

  test "complete navigation flow from directory to detail to external URL" do
    # Start at directory listing
    visit entries_path

    # Click on entry title to go to detail page
    click_link @entry.title

    # Verify we're on the detail page
    assert_current_path resource_path(@entry.slug)
    assert_selector "h1", text: @entry.title

    # Verify "Visit Resource" button is present
    visit_resource_button = find("a", text: /Visit Resource/i)
    assert_equal @entry.url, visit_resource_button[:href]
    assert_equal "_blank", visit_resource_button[:target]
    assert_equal "noopener noreferrer", visit_resource_button[:rel]
  end

  test "user clicks category link from detail page and navigates to category browse" do
    visit resource_path(@entry.slug)

    # Click on a category link
    click_link @category1.name

    # Verify we're on the category page
    assert_current_path category_path(@category1.slug)
    assert_selector "h1", text: @category1.name
  end

  test "user clicks author link from detail page and navigates to author profile" do
    visit resource_path(@entry.slug)

    # Click on author link
    click_link @author.name

    # Verify we're on the author profile page
    assert_current_path author_path(@author.slug)
    assert_selector "h1", text: @author.name
  end

  test "user views related resources and clicks through to another detail page" do
    visit resource_path(@entry.slug)

    # Verify related resources section exists
    assert_selector "h2", text: /Related Resources/i

    # Find first related resource link and get its title
    related_link = all("h3 a").first
    related_title = related_link.text

    # Click the link
    related_link.click

    # Verify we navigated to another resource detail page
    assert_match %r{/resources/}, current_path
    # Verify the new page has loaded with the expected title
    assert_selector "h1", text: related_title
  end

  test "user sees breadcrumb navigation and uses it to navigate back" do
    visit resource_path(@entry.slug)

    # Verify breadcrumbs are present
    assert_selector "nav[aria-label='Breadcrumb']"

    within "nav[aria-label='Breadcrumb']" do
      assert_text "Home"
      assert_text "Resources"
      assert_text @entry.title

      # Click on "Resources" breadcrumb link
      click_link "Resources"
    end

    # Verify we're back at the directory listing
    assert_current_path entries_path
    # Check for page heading (the actual h1 text)
    assert_selector "h1", text: /Find the right Rails resource/i
  end

  test "entry with no categories or authors displays gracefully" do
    # Create entry with no associations
    gem = RubyGem.create!(gem_name: "minimal-gem-#{SecureRandom.hex(4)}")
    minimal_entry = Entry.create!(
      title: "Minimal Resource #{SecureRandom.hex(4)}",
      url: "https://example.com/minimal",
      entryable: gem,
      status: :approved,
      published: true
    )
    minimal_entry.description = "Simple description"

    visit resource_path(minimal_entry.slug)

    # Page should load successfully
    assert_selector "h1", text: minimal_entry.title

    # Author section should be hidden
    assert_no_selector "h2", text: /Author/i

    # Related resources section should not appear when no categories
    assert_no_selector "h2", text: /Related Resources/i
  end

  test "multiple authors display correctly with proper formatting" do
    # Add another author to the entry
    author2 = Author.create!(
      name: "Second Author",
      slug: "second-author-#{SecureRandom.hex(4)}",
      status: :approved
    )
    @entry.authors << author2

    visit resource_path(@entry.slug)

    # Both authors should be displayed
    assert_selector "a", text: @author.name
    assert_selector "a", text: author2.name

    # Verify both link to their respective profile pages - search within the authors section
    within "section", text: /Author/ do
      assert_selector "a[href='#{author_path(@author.slug)}']"
      assert_selector "a[href='#{author_path(author2.slug)}']"
    end
  end

  test "SEO meta tags are rendered correctly in page source" do
    visit resource_path(@entry.slug)

    # Check page title
    assert_title "#{@entry.title} | ChooseRuby Resources"

    # Verify meta tags are in the page source
    page_source = page.html

    # Open Graph tags
    assert_match(/meta property="og:title" content="#{Regexp.escape(@entry.title)}"/, page_source)
    assert_match(/meta property="og:type" content="article"/, page_source)
    assert_match(/meta property="og:site_name" content="ChooseRuby"/, page_source)

    # Twitter Card tags
    assert_match(/meta name="twitter:card" content="summary_large_image"/, page_source)
    assert_match(/meta name="twitter:title" content="#{Regexp.escape(@entry.title)}"/, page_source)
  end

  test "responsive design displays correctly with proper layout structure" do
    visit resource_path(@entry.slug)

    # Verify main content container exists with max-width
    assert_selector "div.max-w-4xl"

    # Verify related resources grid is responsive (only if related resources exist)
    if has_selector?("h2", text: /Related Resources/)
      within "section", text: /Related Resources/ do
        # Grid should exist with responsive classes
        assert_selector "div.grid"
      end
    end

    # Verify card styling follows design system
    assert_selector ".rounded-3xl"
  end

  test "resource type badge displays correctly based on entryable_type" do
    visit resource_path(@entry.slug)

    # Should display "Ruby Gem" badge
    assert_selector "span", text: /Ruby Gem/i
  end
end
