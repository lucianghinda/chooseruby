# frozen_string_literal: true

require "test_helper"

class EntriesControllerLevelFilterTest < ActionDispatch::IntegrationTest
  def setup
    Entry.destroy_all

    @beginner = Entry.create!(
      title: "Beginner Guide",
      url: "https://example.com/beginner",
      description: "Basics",
      experience_level: :beginner,
      status: :approved,
      published: true
    )

    @advanced = Entry.create!(
      title: "Advanced Guide",
      url: "https://example.com/advanced",
      description: "Deep dive",
      experience_level: :advanced,
      status: :approved,
      published: true
    )

    @all_levels = Entry.create!(
      title: "For Everyone",
      url: "https://example.com/all",
      description: "Applies to all",
      experience_level: :all_levels,
      status: :approved,
      published: true
    )
  end

  def teardown
    Entry.destroy_all
  end

  test "index with beginner level shows beginner and all_levels" do
    get entries_path(level: "beginner")

    assert_response :success
    assert_select "body", /Beginner Guide/
    assert_select "body", /For Everyone/
    assert_select "body", { text: /Advanced Guide/, count: 0 }
  end

  test "index with advanced level shows advanced and all_levels" do
    get entries_path(level: "advanced")

    assert_response :success
    assert_select "body", /Advanced Guide/
    assert_select "body", /For Everyone/
    assert_select "body", { text: /Beginner Guide/, count: 0 }
  end

  test "index with no level shows everything" do
    get entries_path

    assert_response :success
    assert_select "body", /Beginner Guide/
    assert_select "body", /Advanced Guide/
    assert_select "body", /For Everyone/
  end
end
