# frozen_string_literal: true

class Avo::Resources::EntryReview < Avo::BaseResource
  self.model_class = ::EntryReview
  self.title = :id
  self.includes = [ :entry ]
  self.description = "Review history for entries (approved/rejected with optional comments)"

  def fields
    field :id, as: :id, link_to_record: true

    field :entry, as: :belongs_to,
          searchable: true,
          help: "Entry that was reviewed"

    field :status, as: :select,
          enum: ::EntryReview.statuses,
          required: true,
          help: "Review decision"

    field :comment, as: :textarea,
          help: "Feedback for the submitter"

    field :reviewer_id, as: :number,
          hide_on: [ :index ],
          help: "Admin reviewer id (future use)"

    field :created_at, as: :date_time, readonly: true, sortable: true
    field :updated_at, as: :date_time, readonly: true, hide_on: [ :index ]
  end
end
