# frozen_string_literal: true

# Directory delegated type model for Ruby directories
#
# Represents directory listings and resource collections for Ruby.
#
# Associations:
#   - has_one :entry (as: :entryable) - the base entry record
#
# Usage:
#   directory = Directory.create!
#   entry = Entry.create!(
#     title: "Ruby Resources Directory",
#     url: "https://example.com/directory",
#     entryable: directory
#   )
# == Schema Information
#
# Table name: directories
# Database name: primary
#
#  id         :integer          not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Directory < ApplicationRecord
  has_one :entry, as: :entryable, touch: true, dependent: :destroy

  # Validations
  validates :name, presence: true, length: { minimum: 2, maximum: 200 }

  # Display name for Avo dropdown
  def display_name
    name.presence || entry&.title || "Directory ##{id}"
  end
end
