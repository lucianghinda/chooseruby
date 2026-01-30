# frozen_string_literal: true

# JobBoard delegated type model for Ruby job boards
#
# Represents job board platforms where Ruby developers can find opportunities.
#
# Associations:
#   - has_one :entry (as: :entryable) - the base entry record
#
# Usage:
#   job_board = JobBoard.create!(name: "Ruby on Rails Jobs")
#   entry = Entry.create!(
#     title: "Ruby on Rails Jobs",
#     url: "https://example.com/ruby-jobs",
#     entryable: job_board
#   )
# == Schema Information
#
# Table name: job_boards
# Database name: primary
#
#  id         :integer          not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class JobBoard < ApplicationRecord
  has_one :entry, as: :entryable, touch: true, dependent: :destroy

  # Validations
  validates :name, presence: true, length: { minimum: 2, maximum: 200 }

  # Display name for Avo dropdown
  def display_name
    name.presence || entry&.title || "JobBoard ##{id}"
  end
end
