# frozen_string_literal: true

class Avo::Resources::Job < Avo::BaseResource
  self.title = :display_name
  self.includes = [ :entry ]
  self.description = "Create a Job first, then create an Entry and select this Job as the entryable"

  def fields
    field :id, as: :id, link_to_record: true

    # Job information
    field :name, as: :text, required: true, sortable: true,
          help: "Name of the job"

    # Association to base entry resource
    field :entry, as: :has_one,
          help: "After creating this Job, go to Entries → New and select this Job"

    # Timestamps
    field :created_at, as: :date_time, readonly: true, hide_on: [ :index ]
    field :updated_at, as: :date_time, readonly: true, hide_on: [ :index ]
  end
end
