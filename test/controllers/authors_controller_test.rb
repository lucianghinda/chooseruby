# frozen_string_literal: true

require "test_helper"

class AuthorsControllerTest < ActionDispatch::IntegrationTest
  test "index searches approved authors and preserves the normalized search value" do
    Author.create!(name: "Directoryneedle Approved", status: :approved)
    Author.create!(name: "Directoryneedle Pending", status: :pending)
    Author.create!(name: "Unrelated Approved", status: :approved)

    get authors_path, params: { q: "  Directoryneedle  " }

    assert_response :success
    assert_select "input[name=q][value=Directoryneedle]"
    assert_select "h3", text: "Directoryneedle Approved"
    assert_select "h3", text: "Directoryneedle Pending", count: 0
    assert_select "h3", text: "Unrelated Approved", count: 0
  end

  test "should show approved author profile" do
    author = Author.create(name: "Yukihiro Matsumoto", status: :approved)
    get author_path(slug: author.slug)

    assert_response :success
    assert_select "h1", text: "Yukihiro Matsumoto"
  end

  test "should return 404 for pending author" do
    author = Author.create(name: "Pending Author", status: :pending)
    get author_path(slug: author.slug)

    assert_response :not_found
  end

  test "should return 404 for non-existent slug" do
    get author_path(slug: "non-existent-slug")

    assert_response :not_found
  end

  test "should load author entries with pagination" do
    author = Author.create(name: "Test Author", status: :approved)
    25.times do |i|
      entry = Entry.create(title: "Entry #{i}", url: "https://example.com/#{i}", status: :approved, published: true)
      author.entries << entry
    end

    get author_path(slug: author.slug)

    assert_response :success
    # Check that entries are displayed (pagination will show max 20)
    assert_select "div.bg-white.border.border-gray-200.rounded-lg", count: 20
  end
end
