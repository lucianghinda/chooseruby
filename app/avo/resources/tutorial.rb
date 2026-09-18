# frozen_string_literal: true

# Configures the admin form and listing for Tutorial records.
class Avo::Resources::Tutorial < Avo::BaseResource
  self.title = :display_name
  self.includes = [ :entry ]
  self.description = "Create a Tutorial first, then create an Entry and select this Tutorial as the entryable"

  def fields
    tutorial_fields
    entry_fields
    timestamp_fields
  end

  private

  def tutorial_fields
    field :id, as: :id, link_to_record: true
    field :reading_time_minutes, as: :number, help: "Estimated reading time in minutes"
    field :publication_date, as: :date, help: "Date of publication"
    field :author_name, as: :text, help: "Author name (if not using Author model)"
    field :platform, as: :text, help: "Platform (e.g., Dev.to, Medium, Personal Blog)"
  end

  def entry_fields
    field :entry, as: :has_one,
          help: "After creating this Tutorial, go to Entries → New and select this Tutorial"
  end

  def timestamp_fields
    field :created_at, as: :date_time, readonly: true, hide_on: [ :index ]
    field :updated_at, as: :date_time, readonly: true, hide_on: [ :index ]
  end
end
