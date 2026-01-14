# frozen_string_literal: true

# Community delegated type model for Ruby communities
#
# Represents Ruby communities like Ruby on Rails Link Slack,
# Reddit r/ruby, official Ruby Discord, forums, etc.
#
# Attributes:
#   - platform: Community platform (required, e.g., "Discord", "Slack", "Forum", "Reddit")
#   - join_url: Direct link to join the community (required)
#   - member_count: Number of community members (optional)
#   - is_official: Whether this is an official Ruby community (default: false)
#
# Associations:
#   - has_one :resource (as: :resourceable) - the base resource record
# == Schema Information
#
# Table name: communities
#
#  id           :integer          not null, primary key
#  is_official  :boolean          default(FALSE), not null
#  join_url     :string           not null
#  member_count :integer
#  platform     :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
class Community < ApplicationRecord
  has_one :entry, as: :entryable, touch: true, dependent: :destroy

  # Display name for Avo dropdown
  def display_name
    entry&.title || "Community ##{id}"
  end

  # Validations
  validates :platform, presence: true
  validates :join_url, presence: true,
                       format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]),
                                message: "must be a valid URL starting with http:// or https://" }
  validates :member_count, numericality: { greater_than: 0 }, allow_blank: true
end
