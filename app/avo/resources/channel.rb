# frozen_string_literal: true

class Avo::Resources::Channel < Avo::BaseResource
  self.title = :display_name
  self.includes = [ :entry ]
  self.description = "Create a Channel first, then create an Entry and select this Channel as the entryable"

  def fields
    field :id, as: :id, link_to_record: true

    # Channel information
    field :name, as: :text, required: true, sortable: true,
          help: "Name of the channel"

    # Association to base entry resource
    field :entry, as: :has_one,
          help: "After creating this Channel, go to Entries → New and select this Channel"

    # Timestamps
    field :created_at, as: :date_time, readonly: true, hide_on: [ :index ]
    field :updated_at, as: :date_time, readonly: true, hide_on: [ :index ]
  end
end
