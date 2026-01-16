# frozen_string_literal: true

# Documentation delegated type model for Ruby documentation resources
#
# Represents documentation sites and resources for Ruby development.
#
# Associations:
#   - has_one :entry (as: :entryable) - the base entry record
#
# Usage:
#   documentation = Documentation.create!
#   entry = Entry.create!(
#     title: "Ruby API Documentation",
#     url: "https://ruby-doc.org",
#     entryable: documentation
#   )
# == Schema Information
#
# Table name: documentations
# Database name: primary
#
#  id         :integer          not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Documentation < ApplicationRecord
  has_one :entry, as: :entryable, touch: true, dependent: :destroy

  # Validations
  validates :name, presence: true, length: { minimum: 2, maximum: 200 }

  # Display name for Avo dropdown
  def display_name
    name.presence || entry&.title || "Documentation ##{id}"
  end
end
