# frozen_string_literal: true

# Limits the admin entry listing to a selected resource type.
class Avo::Filters::EntryTypeFilter < Avo::Filters::SelectFilter
  self.name = "Resource Type"

  def apply(_request, query, value)
    return query unless options.key?(value)
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
      "DevelopmentEnvironment" => "Development Environment",
      "Directory" => "Directory",
      "Documentation" => "Documentation",
      "Framework" => "Framework",
      "JobBoard" => "Job Board",
      "Newsletter" => "Newsletter",
      "Podcast" => "Podcast",
      "Product" => "Product",
      "RubyGem" => "Ruby Gem",
      "TestingResource" => "Testing Resource",
      "Tool" => "Tool",
      "Tutorial" => "Tutorial",
      "Video" => "Video"
    }
  end
end
