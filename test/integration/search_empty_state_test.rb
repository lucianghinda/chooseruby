# frozen_string_literal: true

require "test_helper"

class SearchEmptyStateTest < ActionDispatch::IntegrationTest
  test "entries search displays empty state when no results found" do
    # Search for something that won't match any entries
    get entries_path(q: "xyznonexistent123")

    assert_response :success
    assert_select "p", text: /No results found/i
    assert_select "a[href=?]", new_resource_submission_path, text: /Submit a resource/i
  end

  test "authors search displays empty state when no results found" do
    # Search for a name that won't match any authors
    get authors_path(q: "xyznonexistent123")

    assert_response :success
    assert_select "p", text: /No results found/i
    assert_select "a[href=?]", new_resource_submission_path, text: /Submit a resource/i
  end

  test "entries index without search query does not show empty state message" do
    # Visit entries without search query (all results or filtered by category/level)
    get entries_path

    assert_response :success
    # Should not show the "No results found" message when there's no search query
    # Only show it when actively searching
    assert_select "p", text: /No results found/i, count: 0
  end
end
