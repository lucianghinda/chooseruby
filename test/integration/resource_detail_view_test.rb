# frozen_string_literal: true

require "test_helper"

class ResourceDetailViewTest < ActionDispatch::IntegrationTest
  setup do
    # Use fixture categories
    @category1 = categories(:testing)
    @category2 = categories(:authentication)

    # Create unique authors for this test
    @author1 = Author.create!(
      name: "Jane Doe #{SecureRandom.hex(4)}",
      slug: "jane-doe-#{SecureRandom.hex(4)}",
      status: :approved
    )

    @author2 = Author.create!(
      name: "John Smith #{SecureRandom.hex(4)}",
      slug: "john-smith-#{SecureRandom.hex(4)}",
      status: :approved
    )

    @gem = RubyGem.create!(gem_name: "rspec-#{SecureRandom.hex(4)}")
    @entry = Entry.create!(
      title: "RSpec Testing Framework #{SecureRandom.hex(4)}",
      description: "Comprehensive testing framework for Ruby",
      url: "https://rspec.info",
      entryable: @gem,
      status: :approved,
      published: true,
      experience_level: :intermediate
    )
    @entry.categories << [ @category1, @category2 ]
    @entry.authors << [ @author1, @author2 ]

    # Create related resources for testing
    @related_gem1 = RubyGem.create!(gem_name: "minitest-#{SecureRandom.hex(4)}")
    @related_entry1 = Entry.create!(
      title: "Minitest #{SecureRandom.hex(4)}",
      description: "Simple testing framework",
      url: "https://minitest.org",
      entryable: @related_gem1,
      status: :approved,
      published: true,
      experience_level: :beginner
    )
    @related_entry1.categories << @category1

    @related_gem2 = RubyGem.create!(gem_name: "capybara-#{SecureRandom.hex(4)}")
    @related_entry2 = Entry.create!(
      title: "Capybara #{SecureRandom.hex(4)}",
      description: "Integration testing tool",
      url: "https://capybara.org",
      entryable: @related_gem2,
      status: :approved,
      published: true,
      experience_level: :intermediate
    )
    @related_entry2.categories << @category1
  end

  test "page renders with entry title, description, and categories" do
    get resource_path(@entry.slug)

    assert_response :success
    assert_select "h1 a", text: @entry.title
    assert_select "a[href=?]", category_path(@category1.slug), text: @category1.name
    assert_select "a[href=?]", category_path(@category2.slug), text: @category2.name
  end

  test "external link opens in new tab with security attributes" do
    get resource_path(@entry.slug)

    assert_response :success
    assert_select "h1 a[href=?][target='_blank'][rel='noopener noreferrer']", @entry.url
    assert_select "a[href=?][target='_blank'][rel='noopener noreferrer']", @entry.url, text: /Visit Resource/
  end

  test "author section displays with name link" do
    get resource_path(@entry.slug)

    assert_response :success
    assert_select "h2", text: /Author/
    assert_select "a[href=?]", author_path(@author1.slug)
    assert_select "a[href=?]", author_path(@author2.slug)
  end

  test "related resources section renders" do
    get resource_path(@entry.slug)

    assert_response :success
    # Check if related resources heading exists
    assert_select "h2", text: /Related Resources/
    # Should have resource cards in the grid
    assert_select "div.grid"
  end

  test "experience level badge displays correctly" do
    get resource_path(@entry.slug)

    assert_response :success
    assert_select "span", text: /Intermediate/
    assert_select "span.bg-emerald-500"
  end

  test "resource type badge displays" do
    get resource_path(@entry.slug)

    assert_response :success
    assert_select "span", text: /Ruby Gem/
  end

  test "created date displays in correct format" do
    get resource_path(@entry.slug)

    assert_response :success
    # Check for "Added on" text
    assert_select "span", text: /Added on/
  end

  test "hides author section when entry has no authors" do
    @entry.authors.clear

    get resource_path(@entry.slug)

    assert_response :success
    assert_select "h2", { text: /Author/, count: 0 }
  end
end
