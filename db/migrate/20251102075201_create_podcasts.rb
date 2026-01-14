# frozen_string_literal: true

class CreatePodcasts < ActiveRecord::Migration[8.1]
  def change
    create_table :podcasts do |t|
      t.string :host
      t.integer :episode_count
      t.string :frequency
      t.string :rss_feed_url
      t.string :spotify_url
      t.string :apple_podcasts_url

      t.timestamps
    end
  end
end
