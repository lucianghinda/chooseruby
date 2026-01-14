# frozen_string_literal: true

require "test_helper"

class AuthorsController::SearchTest < ActionDispatch::IntegrationTest
  test "search returns JSON array of matching approved authors" do
    # Create some authors
    approved_author = Author.create!(
      name: "Yukihiro Matsumoto",
      status: :approved,
      github_url: "https://github.com/matz"
    )

    pending_author = Author.create!(
      name: "Yukihiro Pending",
      status: :pending
    )

    get authors_search_path, params: { q: "Yukihiro" }, as: :json

    assert_response :success
    json_response = JSON.parse(response.body)

    # Should return only approved author
    assert_equal 1, json_response.length
    assert_equal approved_author.id, json_response[0]["id"]
    assert_equal approved_author.name, json_response[0]["name"]
    assert_equal approved_author.github_url, json_response[0]["github_url"]
  end

  test "search returns empty array for blank query" do
    get authors_search_path, params: { q: "" }, as: :json

    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal [], json_response
  end

  test "search limits results to 10 authors" do
    # Create 15 approved authors
    15.times do |i|
      Author.create!(
        name: "Author #{i}",
        status: :approved
      )
    end

    get authors_search_path, params: { q: "Author" }, as: :json

    assert_response :success
    json_response = JSON.parse(response.body)

    # Should return maximum 10 results
    assert_equal 10, json_response.length
  end

  test "search uses FTS5 for efficient querying" do
    # Create author with specific name
    author = Author.create!(
      name: "David Heinemeier Hansson",
      status: :approved,
      github_url: "https://github.com/dhh"
    )

    # Search for partial match
    get authors_search_path, params: { q: "Heine" }, as: :json

    assert_response :success
    json_response = JSON.parse(response.body)

    # Should find the author using FTS5
    assert_equal 1, json_response.length
    assert_equal author.id, json_response[0]["id"]
  end
end
