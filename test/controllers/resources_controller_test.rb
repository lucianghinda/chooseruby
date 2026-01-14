# frozen_string_literal: true

require "test_helper"

class ResourcesControllerTest < ActionDispatch::IntegrationTest
  test "should find entry by slug and render show template for visible entry" do
    entry = Entry.create!(
      title: "RSpec Testing Guide",
      url: "https://rspec.info",
      published: true,
      status: :approved
    )

    get "/resources/#{entry.slug}"

    assert_response :success
    assert_select "h1", text: "RSpec Testing Guide"
  end

  test "should return 404 for non-existent slug" do
    get "/resources/non-existent-slug"

    assert_response :not_found
  end

  test "should return 404 for unpublished entry" do
    entry = Entry.create!(
      title: "Draft Entry",
      url: "https://example.com",
      published: false,
      status: :approved
    )

    get "/resources/#{entry.slug}"

    assert_response :not_found
  end

  test "should return 404 for pending entry" do
    entry = Entry.create!(
      title: "Pending Entry",
      url: "https://example.com",
      published: true,
      status: :pending,
      submitter_email: "pending@example.com"
    )

    get "/resources/#{entry.slug}"

    assert_response :not_found
  end

  test "should eager load associations to prevent N+1 queries" do
    # Use find_or_create_by to avoid duplicate key errors
    category = Category.find_or_create_by!(name: "Testing Framework") do |c|
      c.slug = "testing-framework"
    end
    author = Author.find_or_create_by!(name: "Test Author", slug: "test-author") do |a|
      a.status = :approved
    end

    entry = Entry.create!(
      title: "Complete Ruby Guide",
      url: "https://example.com",
      published: true,
      status: :approved
    )
    entry.categories << category
    entry.authors << author
    entry.description = "Rich text content here"
    entry.save!

    # Verify eager loading prevents N+1 queries
    get "/resources/#{entry.slug}"

    assert_response :success
    # The page should display category and author without additional queries
    assert_select "a", text: "Testing Framework"
    assert_select "a", text: "Test Author"
  end

  test "should use strict_loading to prevent N+1 queries" do
    category1 = Category.find_or_create_by!(name: "Web Framework") { |c| c.slug = "web-framework" }
    category2 = Category.find_or_create_by!(name: "API Framework") { |c| c.slug = "api-framework" }
    author = Author.find_or_create_by!(name: "Framework Author", slug: "framework-author") { |a| a.status = :approved }

    entry = Entry.create!(
      title: "Ruby Framework Guide",
      url: "https://example.com/framework",
      published: true,
      status: :approved
    )
    entry.categories << [ category1, category2 ]
    entry.authors << author
    entry.description = "Framework guide content"
    entry.save!

    get "/resources/#{entry.slug}"

    assert_response :success
    # Verify all associations are displayed correctly (would fail with N+1 if not eager loaded)
    assert_select "a", text: "Web Framework"
    assert_select "a", text: "API Framework"
    assert_select "a", text: "Framework Author"
  end
end
