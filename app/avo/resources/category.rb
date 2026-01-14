# frozen_string_literal: true

class Avo::Resources::Category < Avo::BaseResource
  self.title = :name
  self.includes = [ :entries ]

  # Enable fuzzy search on name field
  self.search = {
    query: -> {
      sanitized_query = ActiveRecord::Base.sanitize_sql_like(params[:q])
      query.where("name LIKE ?", "%#{sanitized_query}%")
    }
  }

  def fields
    field :id, as: :id, link_to_record: true

    # Basic information
    field :name, as: :text, required: true, sortable: true
    field :slug, as: :text, readonly: true, help: "Auto-generated from name"
    field :description, as: :textarea, rows: 3, help: "Max 500 characters"
    field :icon, as: :text, help: "Icon identifier for future use"
    field :display_order, as: :number, sortable: true, help: "Lower numbers appear first"

    # Computed fields
    field :entries_count, as: :number, readonly: true, help: "Total number of visible resources"

    # Associations
    field :entries, as: :has_many, through: :categories_entries

    # Timestamps
    field :created_at, as: :date_time, readonly: true, hide_on: [ :index ]
    field :updated_at, as: :date_time, readonly: true, hide_on: [ :index ]
  end
end
