# frozen_string_literal: true

module EntriesHelper
  # Returns the Tailwind CSS color class for a given experience level
  #
  # @param level [String] The experience level (beginner, intermediate, advanced, all_levels)
  # @return [String] The Tailwind background color class
  def experience_level_badge_color(level)
    case level
    when "beginner"
      "bg-emerald-500"
    when "intermediate"
      "bg-amber-500"
    when "advanced"
      "bg-rose-500"
    when "all_levels"
      "bg-slate-500"
    else
      "bg-slate-500"
    end
  end

  # Formats experience level options with humanized labels.
  #
  # @param selected [String, nil] level to preselect
  # @return [String] HTML options for select
  def experience_level_options_for_select(selected = nil)
    options = Entry.experience_levels.keys
      .reject { |level| level == "all_levels" }
      .map { |level| [ level.to_s.humanize, level ] }
    options_for_select(options, selected)
  end
end
