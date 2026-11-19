# frozen_string_literal: true

require "test_helper"

# Covers the breadcrumb cases the main ApplicationHelper test does not exercise:
# blank input and a non-final item without a URL.
class ApplicationHelperEdgeCasesTest < ActionView::TestCase
  tests ApplicationHelper

  test "breadcrumbs renders nothing for an empty list" do
    assert_equal "", breadcrumbs([])
  end

  test "breadcrumbs renders nothing for nil" do
    assert_equal "", breadcrumbs(nil)
  end

  test "breadcrumbs renders a middle item without a url as plain text" do
    items = [
      { text: "Home", url: "/" },
      { text: "Unlinked Section", url: nil },
      { text: "Current Page", url: nil }
    ]

    result = breadcrumbs(items)

    assert_no_match(/<a[^>]*>Unlinked Section<\/a>/, result)
    assert_match(/<span[^>]*font-semibold[^>]*>Unlinked Section<\/span>/, result)
    # Still separated from the following crumb.
    assert_equal 2, result.scan(/›/).count
  end

  test "breadcrumbs renders a middle item with a blank url as plain text" do
    items = [
      { text: "Blank Url", url: "" },
      { text: "Current Page", url: nil }
    ]

    result = breadcrumbs(items)

    assert_no_match(/<a/, result)
    assert_match(/Blank Url/, result)
  end
end
