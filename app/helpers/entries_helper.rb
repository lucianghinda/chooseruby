# frozen_string_literal: true

module EntriesHelper
  # Tailwind background colour each experience level is badged with
  EXPERIENCE_LEVEL_BADGE_COLORS = {
    "beginner" => "bg-emerald-500",
    "intermediate" => "bg-amber-500",
    "advanced" => "bg-rose-500",
    "all_levels" => "bg-slate-500"
  }.freeze

  # Colour for levels we do not badge specifically
  DEFAULT_EXPERIENCE_LEVEL_BADGE_COLOR = "bg-slate-500"

  # Returns the Tailwind CSS color class for a given experience level
  #
  # @param level [String] The experience level (beginner, intermediate, advanced, all_levels)
  # @return [String] The Tailwind background color class
  def experience_level_badge_color(level)
    EXPERIENCE_LEVEL_BADGE_COLORS.fetch(level, DEFAULT_EXPERIENCE_LEVEL_BADGE_COLOR)
  end

  # Formats experience level options with humanized labels.
  #
  # @param selected [String, nil] level to preselect
  # @return [String] HTML options for select
  def experience_level_options_for_select(selected = nil)
    options_for_select(Entry.selectable_experience_levels, selected)
  end
end
