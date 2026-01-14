# frozen_string_literal: true

require "test_helper"

class ResourceTypeHelperTest < ActionView::TestCase
  # Test 1: type_name returns correct names for new types
  test "type_name returns correct names for new resource types" do
    assert_equal "Newsletters", type_name("newsletters")
    assert_equal "Blogs", type_name("blogs")
    assert_equal "Videos", type_name("videos")
    assert_equal "Testing Resources", type_name("testing-resources")
    assert_equal "Development Environments", type_name("development-environments")
  end

  # Test 2: type_emoji returns correct emojis for new types
  test "type_emoji returns correct emojis for new resource types" do
    assert_equal "📧", type_emoji("newsletters")
    assert_equal "📝", type_emoji("blogs")
    assert_equal "🎥", type_emoji("videos")
    assert_equal "📺", type_emoji("channels")
    assert_equal "📚", type_emoji("documentations")
    assert_equal "🧪", type_emoji("testing-resources")
    assert_equal "💻", type_emoji("development-environments")
    assert_equal "💼", type_emoji("jobs")
    assert_equal "🏗️", type_emoji("frameworks")
    assert_equal "📂", type_emoji("directories")
    assert_equal "🚀", type_emoji("products")
  end

  # Test 3: type_description returns correct descriptions for new types
  test "type_description returns correct descriptions for new resource types" do
    assert_equal "curated newsletters for Ruby developers", type_description("newsletters")
    assert_equal "curated blogs for Ruby developers", type_description("blogs")
    assert_equal "curated videos for Ruby developers", type_description("videos")
    assert_equal "curated testing resources for Ruby developers", type_description("testing-resources")
    assert_equal "curated development environments for Ruby developers", type_description("development-environments")
  end

  # Test 4: submission_message_for_type returns correct message for newsletter (singular)
  test "submission_message_for_type returns correct message for newsletter" do
    message = submission_message_for_type("newsletters")
    assert_includes message, "Know a great Ruby newsletter?"
    assert_includes message, "Submit it here"
  end

  # Test 5: submission_message_for_type returns correct message for videos (plural)
  test "submission_message_for_type returns correct message for videos" do
    message = submission_message_for_type("videos")
    assert_includes message, "Know a great Ruby video?"
    assert_includes message, "Submit it here"
  end

  # Test 6: submission_message_for_type returns correct message for testing resources
  test "submission_message_for_type returns correct message for testing resources" do
    message = submission_message_for_type("testing-resources")
    assert_includes message, "Know a great Ruby testing resource?"
    assert_includes message, "Submit it here"
  end

  # Test 7: type_name falls back to titleize for unknown types
  test "type_name falls back to titleize for unknown types" do
    assert_equal "Unknown Type", type_name("unknown-type")
  end

  # Test 8: type_emoji falls back to default emoji for unknown types
  test "type_emoji falls back to default emoji for unknown types" do
    assert_equal "📦", type_emoji("unknown-type")
  end
end
