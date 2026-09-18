# frozen_string_literal: true

# Configures the admin form and listing for Course records.
class Avo::Resources::Course < Avo::BaseResource
  self.title = :display_name
  self.includes = [ :entry ]
  self.description = "Create a Course first, then create an Entry and select this Course as the entryable"

  def fields
    course_fields
    enrollment_fields
    entry_fields
    timestamp_fields
  end

  private

  def course_fields
    field :id, as: :id, link_to_record: true
    field :platform, as: :text, help: "Platform name (e.g., Udemy, Coursera)"
    field :instructor, as: :text, help: "Instructor name"
    field :duration_hours, as: :number, help: "Course duration in hours (can be decimal)"
  end

  def enrollment_fields
    field :price_cents, as: :number, help: "Price in cents (e.g., 9999 for $99.99)"
    field :currency, as: :text, help: "Currency code (e.g., USD, EUR)"
    field :is_free, as: :boolean, help: "Is this course free?"
    field :enrollment_url, as: :text, help: "Link to enroll in the course"
  end

  def entry_fields
    field :entry, as: :has_one,
          help: "After creating this Course, go to Entries → New and select this Course"
  end

  def timestamp_fields
    field :created_at, as: :date_time, readonly: true, hide_on: [ :index ]
    field :updated_at, as: :date_time, readonly: true, hide_on: [ :index ]
  end
end
