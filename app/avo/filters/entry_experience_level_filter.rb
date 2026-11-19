# frozen_string_literal: true

# Limits the admin entry listing to a selected audience experience level.
class Avo::Filters::EntryExperienceLevelFilter < Avo::Filters::SelectFilter
  self.name = "Experience Level"

  def apply(_request, query, value)
    return query unless options.key?(value)
    query.where(experience_level: value)
  end

  def options
    {
      "all_levels" => "All Levels",
      "beginner" => "Beginner",
      "intermediate" => "Intermediate",
      "advanced" => "Advanced"
    }
  end
end
