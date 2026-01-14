# frozen_string_literal: true

require "test_helper"

class ApplicationNavigationTest < ActionDispatch::IntegrationTest
  # Task 6.1: Test header navigation includes all 19 types in "Browse by Type" section

  test "navigation includes all 19 type links in desktop menu" do
    get root_path

    assert_response :success
    # Check that all 19 types are present in the navigation dropdown
    # Existing 8 types
    assert_select "a[href='#{resource_type_path('gems')}']", minimum: 1
    assert_select "a[href='#{resource_type_path('books')}']", minimum: 1
    assert_select "a[href='#{resource_type_path('courses')}']", minimum: 1
    assert_select "a[href='#{resource_type_path('tutorials')}']", minimum: 1
    assert_select "a[href='#{resource_type_path('articles')}']", minimum: 1
    assert_select "a[href='#{resource_type_path('tools')}']", minimum: 1
    assert_select "a[href='#{resource_type_path('podcasts')}']", minimum: 1
    assert_select "a[href='#{resource_type_path('communities')}']", minimum: 1

    # New 11 types
    assert_select "a[href='#{resource_type_path('newsletters')}']", minimum: 1
    assert_select "a[href='#{resource_type_path('blogs')}']", minimum: 1
    assert_select "a[href='#{resource_type_path('videos')}']", minimum: 1
    assert_select "a[href='#{resource_type_path('channels')}']", minimum: 1
    assert_select "a[href='#{resource_type_path('documentations')}']", minimum: 1
    assert_select "a[href='#{resource_type_path('testing-resources')}']", minimum: 1
    assert_select "a[href='#{resource_type_path('development-environments')}']", minimum: 1
    assert_select "a[href='#{resource_type_path('jobs')}']", minimum: 1
    assert_select "a[href='#{resource_type_path('frameworks')}']", minimum: 1
    assert_select "a[href='#{resource_type_path('directories')}']", minimum: 1
    assert_select "a[href='#{resource_type_path('products')}']", minimum: 1
  end

  test "navigation includes all 19 type names with emojis in desktop menu" do
    get root_path

    assert_response :success
    # Existing 8 types with emojis
    assert_match(/💎.*Gems/m, response.body)
    assert_match(/📚.*Books/m, response.body)
    assert_match(/🎓.*Courses/m, response.body)
    assert_match(/📝.*Tutorials/m, response.body)
    assert_match(/📰.*Articles/m, response.body)
    assert_match(/🛠️.*Tools/m, response.body)
    assert_match(/🎙️.*Podcasts/m, response.body)
    assert_match(/👥.*Communities/m, response.body)

    # New 11 types with emojis
    assert_match(/📧.*Newsletters/m, response.body)
    assert_match(/📝.*Blogs/m, response.body)
    assert_match(/🎥.*Videos/m, response.body)
    assert_match(/📺.*Channels/m, response.body)
    assert_match(/📚.*Documentation/m, response.body)
    assert_match(/🧪.*Testing Resources/m, response.body)
    assert_match(/💻.*Development Environments/m, response.body)
    assert_match(/💼.*Jobs/m, response.body)
    assert_match(/🏗️.*Frameworks/m, response.body)
    assert_match(/📂.*Directories/m, response.body)
    assert_match(/🚀.*Products/m, response.body)
  end

  test "mobile menu includes all 19 type links" do
    get root_path

    assert_response :success
    # Check that mobile menu contains all type links
    assert_select "div[data-mobile-nav-target='menu']" do
      # Existing 8 types
      assert_select "a[href='#{resource_type_path('gems')}']", minimum: 1
      assert_select "a[href='#{resource_type_path('books')}']", minimum: 1
      assert_select "a[href='#{resource_type_path('courses')}']", minimum: 1
      assert_select "a[href='#{resource_type_path('tutorials')}']", minimum: 1
      assert_select "a[href='#{resource_type_path('articles')}']", minimum: 1
      assert_select "a[href='#{resource_type_path('tools')}']", minimum: 1
      assert_select "a[href='#{resource_type_path('podcasts')}']", minimum: 1
      assert_select "a[href='#{resource_type_path('communities')}']", minimum: 1

      # New 11 types
      assert_select "a[href='#{resource_type_path('newsletters')}']", minimum: 1
      assert_select "a[href='#{resource_type_path('blogs')}']", minimum: 1
      assert_select "a[href='#{resource_type_path('videos')}']", minimum: 1
      assert_select "a[href='#{resource_type_path('channels')}']", minimum: 1
      assert_select "a[href='#{resource_type_path('documentations')}']", minimum: 1
      assert_select "a[href='#{resource_type_path('testing-resources')}']", minimum: 1
      assert_select "a[href='#{resource_type_path('development-environments')}']", minimum: 1
      assert_select "a[href='#{resource_type_path('jobs')}']", minimum: 1
      assert_select "a[href='#{resource_type_path('frameworks')}']", minimum: 1
      assert_select "a[href='#{resource_type_path('directories')}']", minimum: 1
      assert_select "a[href='#{resource_type_path('products')}']", minimum: 1
    end
  end

  test "navigation maintains existing links and styling" do
    get root_path

    assert_response :success
    # Verify existing navigation links are still present
    assert_select "nav[aria-label='Primary']" do
      assert_select "a", text: "Directory"
      assert_select "a", text: "Start Here"
      assert_select "a", text: "Collections"
      assert_select "a", text: "Why Ruby"
      assert_select "a", text: "Community"
    end
  end
end
