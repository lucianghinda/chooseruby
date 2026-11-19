# frozen_string_literal: true

# Formats resource experience levels for badges and filters.
module EntriesHelper
  # Returns the Tailwind CSS color class for a given experience level
  #
  # @param level [String] The experience level (beginner, intermediate, advanced, all_levels)
  # @return [String] The Tailwind background color class
  delegate :badge_color, to: :ExperienceLevels, prefix: :experience_level

  # Formats experience level options with humanized labels.
  #
  # @param selected [String, nil] level to preselect
  # @return [String] HTML options for select
  def experience_level_options_for_select(selected = nil)
    options_for_select(ExperienceLevels.options, selected)
  end
end
