# frozen_string_literal: true

require "test_helper"

class EntriesHelperTest < ActionView::TestCase
  test "returns emerald-500 for beginner level" do
    assert_equal "bg-emerald-500", experience_level_badge_color("beginner")
  end

  test "returns amber-500 for intermediate level" do
    assert_equal "bg-amber-500", experience_level_badge_color("intermediate")
  end

  test "returns rose-500 for advanced level" do
    assert_equal "bg-rose-500", experience_level_badge_color("advanced")
  end

  test "returns slate-500 for all_levels" do
    assert_equal "bg-slate-500", experience_level_badge_color("all_levels")
  end

  test "returns slate-500 for unknown level" do
    assert_equal "bg-slate-500", experience_level_badge_color("unknown")
  end

  test "experience_level_options_for_select excludes all_levels but includes other levels" do
    html = experience_level_options_for_select

    assert_includes html, "Beginner"
    assert_includes html, "Intermediate"
    assert_includes html, "Advanced"
    assert_not_includes html, "All levels"
  end
end
