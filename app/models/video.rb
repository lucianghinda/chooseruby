# frozen_string_literal: true

# Video delegated type model for Ruby videos
#
# Represents individual videos about Ruby development.
#
# Associations:
#   - has_one :entry (as: :entryable) - the base entry record
#
# Usage:
#   video = Video.create!
#   entry = Entry.create!(
#     title: "Ruby Tutorial Video",
#     url: "https://example.com/video",
#     entryable: video
#   )
# == Schema Information
#
# Table name: videos
#
#  id         :integer          not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Video < ApplicationRecord
  has_one :entry, as: :entryable, touch: true, dependent: :destroy

  # Validations
  validates :name, presence: true, length: { minimum: 2, maximum: 200 }

  # Display name for Avo dropdown
  def display_name
    name.presence || entry&.title || "Video ##{id}"
  end
end
