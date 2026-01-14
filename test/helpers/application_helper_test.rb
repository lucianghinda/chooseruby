# frozen_string_literal: true

require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "breadcrumbs renders navigation with chevron separators" do
    items = [
      { text: "Home", url: "/" },
      { text: "Resources", url: "/resources" },
      { text: "Current Page", url: nil }
    ]

    result = breadcrumbs(items)

    assert_match(/<nav[^>]*aria-label="Breadcrumb"/, result)
    assert_match(/Home/, result)
    assert_match(/Resources/, result)
    assert_match(/Current Page/, result)
    # Chevron separators
    assert_match(/›/, result)
  end

  test "breadcrumbs renders first and middle items as links" do
    items = [
      { text: "Home", url: "/" },
      { text: "Resources", url: "/resources" },
      { text: "Current Page", url: nil }
    ]

    result = breadcrumbs(items)

    assert_match(/<a[^>]*href="\/"[^>]*>Home<\/a>/, result)
    assert_match(/<a[^>]*href="\/resources"[^>]*>Resources<\/a>/, result)
  end

  test "breadcrumbs renders last item without link and in bold" do
    items = [
      { text: "Home", url: "/" },
      { text: "Resources", url: "/resources" },
      { text: "Current Page", url: nil }
    ]

    result = breadcrumbs(items)

    # Last item should NOT be a link
    refute_match(/<a[^>]*>Current Page<\/a>/, result)
    # Last item should be bold
    assert_match(/font-semibold.*Current Page/, result)
  end

  test "breadcrumbs renders semantic HTML with nav tag" do
    items = [
      { text: "Home", url: "/" },
      { text: "Resources", url: nil }
    ]

    result = breadcrumbs(items)

    assert_match(/^<nav[^>]*aria-label="Breadcrumb"/, result)
    assert_match(/<\/nav>$/, result)
  end

  test "breadcrumbs handles single item without separator" do
    items = [
      { text: "Home", url: nil }
    ]

    result = breadcrumbs(items)

    assert_match(/Home/, result)
    # Should not have chevron separator
    refute_match(/›/, result)
  end

  test "breadcrumbs handles two items with single separator" do
    items = [
      { text: "Home", url: "/" },
      { text: "Resources", url: nil }
    ]

    result = breadcrumbs(items)

    # Should have exactly one chevron
    assert_equal 1, result.scan(/›/).count
  end
end
