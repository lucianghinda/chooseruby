# frozen_string_literal: true

# Configures the admin form and listing for Podcast records.
class Avo::Resources::Podcast < Avo::BaseResource
  self.title = :display_name
  self.includes = [ :entry ]
  self.description = "Create a Podcast first, then create an Entry and select this Podcast as the entryable"

  def fields
    episode_fields
    subscription_fields
    entry_fields
    timestamp_fields
  end

  private

  def episode_fields
    field :id, as: :id, link_to_record: true
    field :host, as: :text, help: "Podcast host name(s)"
    field :episode_count, as: :number, help: "Number of episodes"
    field :frequency, as: :text, help: "Release frequency (e.g., Weekly, Monthly)"
  end

  def subscription_fields
    field :rss_feed_url, as: :text, help: "RSS feed URL"
    field :spotify_url, as: :text, help: "Spotify link"
    field :apple_podcasts_url, as: :text, help: "Apple Podcasts link"
  end

  def entry_fields
    field :entry, as: :has_one,
          help: "After creating this Podcast, go to Entries → New and select this Podcast"
  end

  def timestamp_fields
    field :created_at, as: :date_time, readonly: true, hide_on: [ :index ]
    field :updated_at, as: :date_time, readonly: true, hide_on: [ :index ]
  end
end
