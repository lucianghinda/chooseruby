# frozen_string_literal: true

# Job delegated type model for Ruby job listings
#
# Represents job opportunities for Ruby developers.
#
# Associations:
#   - has_one :entry (as: :entryable) - the base entry record
#
# Usage:
#   job = Job.create!
#   entry = Entry.create!(
#     title: "Senior Ruby Developer",
#     url: "https://example.com/jobs/senior-ruby",
#     entryable: job
#   )
# == Schema Information
#
# Table name: jobs
#
#  id         :integer          not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Job < ApplicationRecord
  has_one :entry, as: :entryable, touch: true, dependent: :destroy

  # Validations
  validates :name, presence: true, length: { minimum: 2, maximum: 200 }

  # Display name for Avo dropdown
  def display_name
    name.presence || entry&.title || "Job ##{id}"
  end
end
