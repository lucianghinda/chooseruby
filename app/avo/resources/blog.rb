# frozen_string_literal: true

class Avo::Resources::Blog < Avo::BaseResource
  self.title = :display_name
  self.includes = [ :entry ]
  self.description = "Create a Blog first, then create an Entry and select this Blog as the entryable"

  def fields
    field :id, as: :id, link_to_record: true

    # Blog information
    field :name, as: :text, required: true, sortable: true,
          help: "Name of the blog (e.g., 'Ruby on Rails Blog', 'Riding Rails')"

    # Association to base entry resource
    field :entry, as: :has_one,
          help: "After creating this Blog, go to Entries → New and select this Blog"

    # Timestamps
    field :created_at, as: :date_time, readonly: true, hide_on: [ :index ]
    field :updated_at, as: :date_time, readonly: true, hide_on: [ :index ]
  end
end
