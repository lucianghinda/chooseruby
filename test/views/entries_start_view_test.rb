# frozen_string_literal: true

require "test_helper"

class EntriesStartViewTest < ActionDispatch::IntegrationTest
  # Test 2.1.1: Test start.html.erb renders heading and introductory text
  test "start page renders custom heading and intro text" do
    get start_path

    assert_response :success
    # Check for the custom hero heading
    assert_select "h1", text: /Start Your Rails Journey/
    # Check for the introductory text
    assert_select "p", text: /Curated beginner-friendly resources/
  end

  # Test 2.1.2: Test page displays "Start Here" in page title
  test "start page displays correct page title" do
    get start_path

    assert_response :success
    assert_select "title", text: "Start Here | ChooseRuby"
  end

  # Test 2.1.3: Test search form includes hidden field with level=beginner
  test "start page search form includes beginner level hidden field" do
    get start_path

    assert_response :success
    assert_select "form[action='#{start_path}']" do
      assert_select "input[type='hidden'][name='level'][value='beginner']"
    end
  end

  # Test 2.1.4: Test category filter pills maintain level=beginner parameter
  test "start page category filter pills maintain beginner parameter" do
    category = categories(:testing)

    get start_path

    assert_response :success
    # Category links should point to start_path with category parameter
    assert_select "a[href='#{start_path(category: category.slug)}']", text: category.name
  end

  # Test 2.1.5: Test experience level filter buttons show "Beginner" as active
  test "start page shows Beginner filter button as active" do
    get start_path

    assert_response :success
    # The "All levels" button should have inactive styling (linking to entries_path)
    assert_select "a[href='#{entries_path}']", text: "All levels"
    # The "Beginner" button should have active styling (bg-rose-500)
    assert_select "a.bg-rose-500", text: "Beginner"
  end
end
