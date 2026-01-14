# frozen_string_literal: true

class Avo::Resources::Course < Avo::BaseResource
  self.title = :display_name
  self.includes = [ :entry ]
  self.description = "Create a Course first, then create an Entry and select this Course as the entryable"

  def fields
    field :id, as: :id, link_to_record: true

    # Course-specific information
    field :platform, as: :text, help: "Platform name (e.g., Udemy, Coursera)"
    field :instructor, as: :text, help: "Instructor name"
    field :duration_hours, as: :number, help: "Course duration in hours (can be decimal)"
    field :price_cents, as: :number, help: "Price in cents (e.g., 9999 for $99.99)"
    field :currency, as: :text, help: "Currency code (e.g., USD, EUR)"
    field :is_free, as: :boolean, help: "Is this course free?"
    field :enrollment_url, as: :text, help: "Link to enroll in the course"

    # Association to base resource
    field :entry, as: :has_one,
          help: "After creating this Course, go to Entries → New and select this Course"

    # Timestamps
    field :created_at, as: :date_time, readonly: true, hide_on: [ :index ]
    field :updated_at, as: :date_time, readonly: true, hide_on: [ :index ]
  end
end
