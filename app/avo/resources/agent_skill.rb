# frozen_string_literal: true

class Avo::Resources::AgentSkill < Avo::BaseResource
  self.title = :display_name
  self.includes = [ :entry ]
  self.description = "Create an Agent Skill first, then create an Entry and select this Agent Skill as entryable"

  def fields
    field :id, as: :id, link_to_record: true

    field :skill_file_url, as: :text, help: "URL to the .md skill file (HTTPS only)"
    field :name, as: :text, help: "Parsed from frontmatter"
    field :skill_description, as: :text, help: "Parsed description field"
    field :license, as: :text, help: "License information"
    field :compatibility, as: :text, help: "Ruby/compatibility version info"
    field :pattern, as: :text, help: "Pattern/trigger for the skill"

    field :metadata, as: :code, theme: "monokai", help: "JSON serialized metadata hash"

    field :allowed_tools, as: :code, theme: "monokai", help: "JSON serialized array of allowed tools"

    field :body, as: :textarea, help: "Markdown content after frontmatter"

    field :parse_status, as: :select,
          enum: ::AgentSkill.parse_statuses,
          help: "Parse status"

    field :parse_error, as: :textarea, readonly: true, help: "Error message if parsing failed"

    field :entry, as: :has_one,
          help: "After creating this Agent Skill, go to Entries → New and select this Agent Skill"

    field :created_at, as: :date_time, readonly: true, hide_on: [ :index ]
    field :updated_at, as: :date_time, readonly: true, hide_on: [ :index ]
  end
end
