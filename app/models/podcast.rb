# frozen_string_literal: true

# Podcast delegated type model for Ruby podcasts
#
# Represents Ruby-related podcasts like "Ruby on Rails Podcast",
# "Ruby Rogues", etc.
#
# Attributes:
#   - host: Podcast host name(s) (optional)
#   - episode_count: Total number of episodes (optional)
#   - frequency: Publishing frequency (e.g., "Weekly", "Monthly")
#   - rss_feed_url: RSS feed link (optional)
#   - spotify_url: Spotify link (optional)
#   - apple_podcasts_url: Apple Podcasts link (optional)
#
# Associations:
#   - has_one :resource (as: :resourceable) - the base resource record
# == Schema Information
#
# Table name: podcasts
# Database name: primary
#
#  id                 :integer          not null, primary key
#  apple_podcasts_url :string
#  episode_count      :integer
#  frequency          :string
#  host               :string
#  rss_feed_url       :string
#  spotify_url        :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
class Podcast < ApplicationRecord
  has_one :entry, as: :entryable, touch: true, dependent: :destroy

  # Display name for Avo dropdown
  def display_name
    entry&.title || "Podcast ##{id}"
  end

  # Validations
  validates :episode_count, numericality: { greater_than: 0 }, allow_blank: true
  validates :rss_feed_url, :spotify_url, :apple_podcasts_url,
            format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]),
                     message: "must be a valid URL starting with http:// or https://" },
            allow_blank: true
end
