# frozen_string_literal: true

require "test_helper"

class CollectionsControllerTest < ActionDispatch::IntegrationTest
  test "index lists curated collections and experience tracks" do
    get collections_path

    assert_response :success
    assert_select "h1", text: /Opinionated resource roadmaps/
    assert_select "a[href=?]", collection_path("hotwire-speed")
  end

  test "show applies the collection's filters" do
    gem = RubyGem.create!(gem_name: "hotwire-gem")
    entry = Entry.create!(title: "Hotwire Handbook", url: "https://example.com/hotwire", entryable: gem, status: :approved, published: true)
    other = Entry.create!(title: "Unrelated Guide", url: "https://example.com/other", status: :approved, published: true)

    get collection_path("hotwire-speed")

    assert_response :success
    assert_select "h1", text: "Build Faster with Hotwire"
    assert_select "h3", text: entry.title
    assert_select "h3", text: other.title, count: 0
  end

  test "show lets request params override the collection's filters" do
    beginner = Entry.create!(title: "Beginner Guide", url: "https://example.com/beginner", status: :approved, published: true, experience_level: :beginner)
    advanced = Entry.create!(title: "Advanced Guide", url: "https://example.com/advanced", status: :approved, published: true, experience_level: :advanced)

    get collection_path("career-switch", level: "advanced")

    assert_response :success
    assert_select "h3", text: advanced.title
    assert_select "h3", text: beginner.title, count: 0
  end

  test "show keeps the collection's filters when the override is blank" do
    beginner = Entry.create!(title: "Beginner Guide", url: "https://example.com/beginner", status: :approved, published: true, experience_level: :beginner)
    advanced = Entry.create!(title: "Advanced Guide", url: "https://example.com/advanced", status: :approved, published: true, experience_level: :advanced)

    get collection_path("career-switch", level: "")

    assert_response :success
    assert_select "h3", text: beginner.title
    assert_select "h3", text: advanced.title, count: 0
  end

  test "show returns 404 for an unknown collection" do
    get collection_path("does-not-exist")

    assert_response :not_found
  end
end
