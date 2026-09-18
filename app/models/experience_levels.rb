# frozen_string_literal: true

# Display metadata shared by experience badges and directory filter options.
module ExperienceLevels
  BADGE_COLORS = {
    "beginner" => "bg-emerald-500",
    "intermediate" => "bg-amber-500",
    "advanced" => "bg-rose-500"
  }.freeze

  module_function

  def badge_color(level)
    BADGE_COLORS.fetch(level, "bg-slate-500")
  end

  def options
    Entry.experience_levels.except("all_levels").keys.map { |level| [ level.humanize, level ] }
  end
end
