# frozen_string_literal: true

require "test_helper"

class CollectionsControllerTest < ActionDispatch::IntegrationTest
  test "GET index lists every curated collection" do
    get collections_path

    assert_response :success
    assert_select "h3", text: "Build Faster with Hotwire"
    assert_select "h3", text: "Production-Ready Rails 8"
    assert_select "h3", text: "Level Up Your Testing"
    assert_select "h3", text: "Ruby for Career Switchers"
  end

  test "GET index lists the experience tracks" do
    get collections_path

    assert_response :success
    assert_select "span", text: /Beginner/
    assert_select "span", text: /Intermediate/
    assert_select "span", text: /Advanced/
  end

  test "GET index links each collection card to its show page" do
    get collections_path

    assert_response :success
    assert_select "a[href=?]", collection_path("hotwire-speed")
  end

  test "GET show renders the collection title and description" do
    get collection_path("hotwire-speed")

    assert_response :success
    assert_select "h1", text: /Build Faster with Hotwire/
  end

  test "GET show applies the collection's own filters when no overrides are given" do
    get collection_path("hotwire-speed")

    assert_response :success
    assert_select "input[name=q][value=?]", "hotwire"
  end

  test "GET show lets a request parameter override the collection filter" do
    get collection_path("hotwire-speed"), params: { q: "rails" }

    assert_response :success
    assert_select "input[name=q][value=?]", "rails"
  end

  test "GET show keeps the collection filter when the override is blank" do
    get collection_path("hotwire-speed"), params: { q: "" }

    assert_response :success
    assert_select "input[name=q][value=?]", "hotwire"
  end

  test "GET show merges an override for one filter and keeps the others" do
    # rails-8-production ships q: "rails 8" and level: "intermediate".
    get collection_path("rails-8-production"), params: { level: "beginner" }

    assert_response :success
    assert_select "input[name=q][value=?]", "rails 8"
    assert_select "select[name=level] option[selected=selected][value=?]", "beginner"
  end

  test "GET show adds a filter the collection does not define" do
    # career-switch only defines level, so q arrives without a collision.
    get collection_path("career-switch"), params: { q: "tutorial" }

    assert_response :success
    assert_select "input[name=q][value=?]", "tutorial"
  end

  test "GET show offers the categories as filters" do
    get collection_path("hotwire-speed")

    assert_response :success
    assert_select "a", text: /#{Regexp.escape(Category.order(:display_order, :name).first.name)}/
  end

  test "GET show lists the entries matching the collection filters" do
    entry = Entry.create!(
      title: "Hotwire Handbook",
      url: "https://example.com/hotwire-handbook",
      description: "Turbo and Stimulus patterns",
      entryable_type: "Book",
      status: :approved,
      published: true,
      submitter_email: "test@example.com"
    )

    get collection_path("hotwire-speed")

    assert_response :success
    assert_select "h3", text: entry.title
  end

  test "GET show does not list entries outside the collection filters" do
    Entry.create!(
      title: "Unrelated Sidekiq Guide",
      url: "https://example.com/sidekiq-guide",
      description: "Background jobs",
      entryable_type: "Book",
      status: :approved,
      published: true,
      submitter_email: "test@example.com"
    )

    get collection_path("hotwire-speed")

    assert_response :success
    assert_select "h3", text: "Unrelated Sidekiq Guide", count: 0
  end

  test "GET show responds with not found for an unknown collection" do
    get collection_path("does-not-exist")

    assert_response :not_found
  end
end
