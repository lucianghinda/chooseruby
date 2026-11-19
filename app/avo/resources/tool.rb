# frozen_string_literal: true

# Configures the admin form and listing for Tool records.
class Avo::Resources::Tool < Avo::BaseResource
  self.title = :display_name
  self.includes = [ :entry ]
  self.description = "Create a Tool first, then create an Entry and select this Tool as the entryable"

  def fields
    tool_fields
    license_fields
    entry_fields
    timestamp_fields
  end

  private

  def tool_fields
    field :id, as: :id, link_to_record: true
    field :tool_type, as: :text, help: "Type of tool (e.g., CLI, Web App, Library, Editor Plugin)"
    field :github_url, as: :text, help: "Link to GitHub repository"
    field :documentation_url, as: :text, help: "Link to documentation"
  end

  def license_fields
    field :license, as: :text, help: "License (e.g., MIT, Apache 2.0)"
    field :is_open_source, as: :boolean, help: "Is this tool open source?"
  end

  def entry_fields
    field :entry, as: :has_one,
          help: "After creating this Tool, go to Entries → New and select this Tool"
  end

  def timestamp_fields
    field :created_at, as: :date_time, readonly: true, hide_on: [ :index ]
    field :updated_at, as: :date_time, readonly: true, hide_on: [ :index ]
  end
end
