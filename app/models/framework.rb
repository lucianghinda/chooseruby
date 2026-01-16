# frozen_string_literal: true

# Framework delegated type model for Ruby frameworks
#
# Represents Ruby frameworks like Rails, Sinatra, Hanami, etc.
#
# Associations:
#   - has_one :entry (as: :entryable) - the base entry record
#
# Usage:
#   framework = Framework.create!
#   entry = Entry.create!(
#     title: "Ruby on Rails",
#     url: "https://rubyonrails.org",
#     entryable: framework
#   )
# == Schema Information
#
# Table name: frameworks
# Database name: primary
#
#  id         :integer          not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Framework < ApplicationRecord
  has_one :entry, as: :entryable, touch: true, dependent: :destroy

  # Validations
  validates :name, presence: true, length: { minimum: 2, maximum: 200 }

  # Display name for Avo dropdown
  def display_name
    name.presence || entry&.title || "Framework ##{id}"
  end
end
