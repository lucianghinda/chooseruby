# frozen_string_literal: true

require "test_helper"

class ResourcesShowCategoriesTest < ActionDispatch::IntegrationTest
  test "should display all categories for entry" do
    entry = Entry.create!(
      title: "RSpec Testing Framework",
      url: "https://rspec.example.com",
      published: true,
      status: :approved
    )
    entry.description = "Behavior Driven Development for Ruby"
    entry.save!

    testing = categories(:testing)
    web_dev = categories(:web_development)
    learning = categories(:learning_resources)

    # Add multiple categories to entry
    entry.categories << testing
    entry.categories << web_dev
    entry.categories << learning

    get "/resources/#{entry.slug}"

    assert_response :success
    assert_select "a[href='#{category_path(testing.slug)}']", text: "Testing"
    assert_select "a[href='#{category_path(web_dev.slug)}']", text: "Web Development"
    assert_select "a[href='#{category_path(learning.slug)}']", text: "Learning Resources"
  end

  test "should display primary category first with rose-500 background and white text" do
    entry = Entry.create!(
      title: "RSpec Testing Framework",
      url: "https://rspec.example.com",
      published: true,
      status: :approved
    )
    entry.description = "Behavior Driven Development for Ruby"
    entry.save!

    testing = categories(:testing)
    web_dev = categories(:web_development)

    # Add categories - testing will be primary
    CategoriesEntry.create!(entry: entry, category: testing, is_primary: true)
    CategoriesEntry.create!(entry: entry, category: web_dev, is_primary: false)

    get "/resources/#{entry.slug}"

    assert_response :success

    # Check primary category has rose-500 background and white text
    assert_select ".category-badges a.bg-rose-500.text-white", text: "Testing"

    # Verify primary category appears first by checking order in rendered HTML
    category_links = css_select(".category-badges a")
    assert_equal "Testing", category_links.first.text.strip
  end

  test "should display remaining categories with slate-100 background style" do
    entry = Entry.create!(
      title: "RSpec Testing Framework",
      url: "https://rspec.example.com",
      published: true,
      status: :approved
    )
    entry.description = "Behavior Driven Development for Ruby"
    entry.save!

    testing = categories(:testing)
    web_dev = categories(:web_development)
    learning = categories(:learning_resources)

    # Add categories - testing is primary, others are not
    CategoriesEntry.create!(entry: entry, category: testing, is_primary: true)
    CategoriesEntry.create!(entry: entry, category: web_dev, is_primary: false)
    CategoriesEntry.create!(entry: entry, category: learning, is_primary: false)

    get "/resources/#{entry.slug}"

    assert_response :success

    # Check non-primary categories have slate-100 background
    assert_select ".category-badges a.bg-slate-100", text: "Web Development"
    assert_select ".category-badges a.bg-slate-100", text: "Learning Resources"
  end

  test "should display star icon on primary category badge" do
    entry = Entry.create!(
      title: "RSpec Testing Framework",
      url: "https://rspec.example.com",
      published: true,
      status: :approved
    )
    entry.description = "Behavior Driven Development for Ruby"
    entry.save!

    testing = categories(:testing)
    web_dev = categories(:web_development)

    # Add categories - testing will be primary
    CategoriesEntry.create!(entry: entry, category: testing, is_primary: true)
    CategoriesEntry.create!(entry: entry, category: web_dev, is_primary: false)

    get "/resources/#{entry.slug}"

    assert_response :success

    # Check primary category badge contains a star icon (SVG)
    primary_badge = css_select(".category-badges a.bg-rose-500").first
    assert_not_nil primary_badge

    # Star icon should be present within the primary badge
    star_icon = primary_badge.css("svg")
    assert_equal 1, star_icon.length, "Primary category badge should contain a star icon"
  end

  test "should maintain clickable links for all category badges" do
    entry = Entry.create!(
      title: "RSpec Testing Framework",
      url: "https://rspec.example.com",
      published: true,
      status: :approved
    )
    entry.description = "Behavior Driven Development for Ruby"
    entry.save!

    testing = categories(:testing)
    web_dev = categories(:web_development)

    # Add categories - testing will be primary
    CategoriesEntry.create!(entry: entry, category: testing, is_primary: true)
    CategoriesEntry.create!(entry: entry, category: web_dev, is_primary: false)

    get "/resources/#{entry.slug}"

    assert_response :success

    # All category badges should be clickable links with correct href
    assert_select ".category-badges a[href='#{category_path(testing.slug)}']", text: "Testing"
    assert_select ".category-badges a[href='#{category_path(web_dev.slug)}']", text: "Web Development"

    # Ensure they're actual anchor tags
    category_links = css_select(".category-badges a")
    assert category_links.length >= 2, "Should have at least 2 clickable category links"
  end
end
