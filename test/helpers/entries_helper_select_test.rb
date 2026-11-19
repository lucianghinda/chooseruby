# frozen_string_literal: true

require "test_helper"

# Covers the preselection argument of experience_level_options_for_select, which
# the main EntriesHelper test calls only without arguments.
class EntriesHelperSelectTest < ActionView::TestCase
  tests EntriesHelper

  test "experience_level_options_for_select marks the given level as selected" do
    html = experience_level_options_for_select("intermediate")

    assert_match(/<option selected="selected" value="intermediate">Intermediate<\/option>/, html)
    assert_match(/<option value="beginner">Beginner<\/option>/, html)
  end

  test "experience_level_options_for_select selects nothing when no level is given" do
    assert_not_includes experience_level_options_for_select, "selected"
  end

  test "experience_level_options_for_select ignores a level that is not offered" do
    assert_not_includes experience_level_options_for_select("all_levels"), "selected"
  end

  test "experience_level_options_for_select offers every level except all_levels" do
    html = experience_level_options_for_select

    assert_equal Entry.experience_levels.keys - [ "all_levels" ], html.scan(/value="([^"]+)"/).flatten
  end
end
