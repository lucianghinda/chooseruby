# frozen_string_literal: true

class Avo::Resources::DevelopmentEnvironment < Avo::BaseResource
  self.title = :display_name
  self.includes = [ :entry ]
  self.description = "Create a DevelopmentEnvironment first, then create an Entry and select this DevelopmentEnvironment as the entryable"

  def fields
    field :id, as: :id, link_to_record: true

    # Development Environment information
    field :name, as: :text, required: true, sortable: true,
          help: "Name of the development environment"

    # Association to base entry resource
    field :entry, as: :has_one,
          help: "After creating this DevelopmentEnvironment, go to Entries → New and select this DevelopmentEnvironment"

    # Timestamps
    field :created_at, as: :date_time, readonly: true, hide_on: [ :index ]
    field :updated_at, as: :date_time, readonly: true, hide_on: [ :index ]
  end
end
