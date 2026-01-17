# frozen_string_literal: true

# TestingResource delegated type model for Ruby testing resources
#
# Represents testing-related resources for Ruby development.
#
# Associations:
#   - has_one :entry (as: :entryable) - the base entry record
#
# Usage:
#   testing_resource = TestingResource.create!
#   entry = Entry.create!(
#     title: "RSpec Testing Guide",
#     url: "https://rspec.info",
#     entryable: testing_resource
#   )
# == Schema Information
#
# Table name: testing_resources
# Database name: primary
#
#  id         :integer          not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class TestingResource < ApplicationRecord
  has_one :entry, as: :entryable, touch: true, dependent: :destroy

  # Validations
  validates :name, presence: true, length: { minimum: 2, maximum: 200 }

  # Display name for Avo dropdown
  def display_name
    name.presence || entry&.title || "TestingResource ##{id}"
  end
end
