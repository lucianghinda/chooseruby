# frozen_string_literal: true

# DevelopmentEnvironment delegated type model for Ruby development environments
#
# Represents development environment resources for Ruby development.
#
# Associations:
#   - has_one :entry (as: :entryable) - the base entry record
#
# Usage:
#   dev_env = DevelopmentEnvironment.create!
#   entry = Entry.create!(
#     title: "Ruby Development Setup",
#     url: "https://example.com/setup",
#     entryable: dev_env
#   )
# == Schema Information
#
# Table name: development_environments
#
#  id         :integer          not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class DevelopmentEnvironment < ApplicationRecord
  has_one :entry, as: :entryable, touch: true, dependent: :destroy

  # Validations
  validates :name, presence: true, length: { minimum: 2, maximum: 200 }

  # Display name for Avo dropdown
  def display_name
    name.presence || entry&.title || "DevelopmentEnvironment ##{id}"
  end
end
