# frozen_string_literal: true

class Avo::Filters::EntryTypeFilter < Avo::Filters::SelectFilter
  self.name = "Resource Type"

  def apply(request, query, value)
    return query if value.blank?
    query.where(entryable_type: value)
  end

  def options
    {
      "Article" => "Article",
      "Blog" => "Blog",
      "Book" => "Book",
      "Channel" => "Channel",
      "Community" => "Community",
      "Course" => "Course",
      "Development Environment" => "DevelopmentEnvironment",
      "Directory" => "Directory",
      "Documentation" => "Documentation",
      "Framework" => "Framework",
      "Job" => "Job",
      "Newsletter" => "Newsletter",
      "Podcast" => "Podcast",
      "Product" => "Product",
      "Ruby Gem" => "RubyGem",
      "Testing Resource" => "TestingResource",
      "Tool" => "Tool",
      "Tutorial" => "Tutorial",
      "Video" => "Video"
    }
  end
end
