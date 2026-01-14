# frozen_string_literal: true

class Avo::Filters::EntryExperienceLevelFilter < Avo::Filters::SelectFilter
  self.name = "Experience Level"

  def apply(request, query, value)
    return query if value.blank?
    query.where(experience_level: value)
  end

  def options
    {
      "All Levels" => "all_levels",
      "Beginner" => "beginner",
      "Intermediate" => "intermediate",
      "Advanced" => "advanced"
    }
  end
end
