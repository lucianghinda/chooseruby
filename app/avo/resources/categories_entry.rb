# frozen_string_literal: true

class Avo::Resources::CategoriesEntry < Avo::BaseResource
  self.title = :id
  self.includes = [ :category, :entry ]

  def fields
    field :id, as: :id, link_to_record: true

    # Associations
    field :category, as: :belongs_to, required: true, searchable: true
    field :entry, as: :belongs_to, required: true, searchable: true

    # Primary category flag
    field :is_primary, as: :boolean,
          help: "Only one primary category per entry. This designates the main classification for the entry."

    # Featured flag
    field :is_featured, as: :boolean,
          help: "Mark this entry as featured in this category. Featured entries appear prominently at the top of the category page."

    # Timestamps
    field :created_at, as: :date_time, readonly: true, hide_on: [ :index ]
    field :updated_at, as: :date_time, readonly: true, hide_on: [ :index ]
  end
end
