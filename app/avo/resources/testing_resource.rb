# frozen_string_literal: true

class Avo::Resources::TestingResource < Avo::BaseResource
  self.title = :display_name
  self.includes = [ :entry ]
  self.description = "Create a TestingResource first, then create an Entry and select this TestingResource as the entryable"

  def fields
    field :id, as: :id, link_to_record: true

    # Testing Resource information
    field :name, as: :text, required: true, sortable: true,
          help: "Name of the testing resource"

    # Association to base entry resource
    field :entry, as: :has_one,
          help: "After creating this TestingResource, go to Entries → New and select this TestingResource"

    # Timestamps
    field :created_at, as: :date_time, readonly: true, hide_on: [ :index ]
    field :updated_at, as: :date_time, readonly: true, hide_on: [ :index ]
  end
end
