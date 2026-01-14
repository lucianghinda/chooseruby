# frozen_string_literal: true

# Channel delegated type model for Ruby video channels
#
# Represents video channels (YouTube, etc.) about Ruby development.
#
# Associations:
#   - has_one :entry (as: :entryable) - the base entry record
#
# Usage:
#   channel = Channel.create!
#   entry = Entry.create!(
#     title: "Ruby Channel",
#     url: "https://youtube.com/channel/ruby",
#     entryable: channel
#   )
# == Schema Information
#
# Table name: channels
#
#  id         :integer          not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Channel < ApplicationRecord
  has_one :entry, as: :entryable, touch: true, dependent: :destroy

  # Validations
  validates :name, presence: true, length: { minimum: 2, maximum: 200 }

  # Display name for Avo dropdown
  def display_name
    name.presence || entry&.title || "Channel ##{id}"
  end
end
