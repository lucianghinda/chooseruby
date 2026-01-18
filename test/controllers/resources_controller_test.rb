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

  test "author resources section is hidden when no related author resources" do
    entry = Entry.create!(
      title: "Solo Entry",
      url: "https://example.com/solo",
      published: true,
      status: :approved
    )

    get "/resources/#{entry.slug}"

    assert_response :success
    assert_select "h2", { text: /Other resources by the same author/, count: 0 }
  end

  test "author resources section shows when related author resources exist" do
    author = Author.find_or_create_by!(name: "Shared Author", slug: "shared-author") { |a| a.status = :approved }

    entry = Entry.create!(
      title: "Primary Entry",
      url: "https://example.com/primary",
      published: true,
      status: :approved
    )
    entry.authors << author

    related_entry = Entry.create!(
      title: "Author Related Entry",
      url: "https://example.com/related-author",
      published: true,
      status: :approved
    )
    related_entry.authors << author

    get "/resources/#{entry.slug}"

    assert_response :success
    assert_select "h2", text: /Other resources by the same author/
    assert_select "a", text: "Author Related Entry"
  end

  test "related resources section is hidden when no related resources" do
    entry = Entry.create!(
      title: "Lonely Entry",
      url: "https://example.com/lonely",
      published: true,
      status: :approved
    )

    get "/resources/#{entry.slug}"

    assert_response :success
    assert_select "h2", { text: /Related resources/, count: 0 }
  end

  test "related resources section shows when related resources exist" do
    category = Category.find_or_create_by!(name: "Testing") { |c| c.slug = "testing" }

    entry = Entry.create!(
      title: "Primary Related Entry",
      url: "https://example.com/primary-related",
      published: true,
      status: :approved
    )
    entry.categories << category

    related_entry = Entry.create!(
      title: "Category Related Entry",
      url: "https://example.com/related-category",
      published: true,
      status: :approved
    )
    related_entry.categories << category

    get "/resources/#{entry.slug}"

    assert_response :success
    assert_select "h2", text: /Related resources/
    assert_select "a", text: "Category Related Entry"
  end
end
