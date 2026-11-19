# frozen_string_literal: true

require "test_helper"

# Covers the ResourceTypeHelper fallbacks and singularisation special cases that
# the main ResourceTypeHelper test does not exercise.
class ResourceTypeHelperFallbacksTest < ActionView::TestCase
  tests ResourceTypeHelper

  test "type_description falls back to a generated sentence for unknown types" do
    assert_equal "curated widgets for Ruby developers", type_description("widgets")
  end

  test "type_description uses the curated copy for known types" do
    assert_equal "curated gems for your Ruby projects", type_description("gems")
  end

  test "type_name uses the curated name for known types" do
    assert_equal "Ruby Gems", type_name("gems")
    assert_equal "Documentation", type_name("documentations")
  end

  test "type_emoji uses the curated emoji for known types" do
    assert_equal "💎", type_emoji("gems")
  end

  test "submission_message_for_type singularises documentation" do
    assert_equal "Know a great Ruby documentation? Submit it here", submission_message_for_type("documentations")
  end

  test "submission_message_for_type singularises hyphenated development environments" do
    assert_equal "Know a great Ruby development environment? Submit it here",
                 submission_message_for_type("development-environments")
  end

  test "submission_message_for_type singularises hyphenated job boards" do
    assert_equal "Know a great Ruby job board? Submit it here", submission_message_for_type("job-boards")
  end

  test "submission_message_for_type singularises a plain hyphenated type by removing the hyphen" do
    assert_equal "Know a great Ruby ruby gem? Submit it here", submission_message_for_type("ruby-gems")
  end

  test "submission_message_for_type singularises a single word type" do
    assert_equal "Know a great Ruby podcast? Submit it here", submission_message_for_type("podcasts")
  end
end
