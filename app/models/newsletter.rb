# frozen_string_literal: true

# Newsletter delegated type model for Ruby newsletters
#
# Represents newsletters like Ruby Weekly, Short Ruby News, etc.
#
# Associations:
#   - has_one :entry (as: :entryable) - the base entry record
#
# Usage:
#   newsletter = Newsletter.create!
#   entry = Entry.create!(
#     title: "Ruby Weekly",
#     url: "https://rubyweekly.com",
#     entryable: newsletter
#   )
# == Schema Information
#
# Table name: newsletters
# Database name: primary
#
#  id         :integer          not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Newsletter < ApplicationRecord
  has_one :entry, as: :entryable, touch: true, dependent: :destroy

  # Validations
  validates :name, presence: true, length: { minimum: 2, maximum: 200 }

  # Display name for Avo dropdown
  def display_name
    name.presence || entry&.title || "Newsletter ##{id}"
  end
end
