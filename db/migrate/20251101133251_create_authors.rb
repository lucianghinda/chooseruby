# frozen_string_literal: true

class CreateAuthors < ActiveRecord::Migration[8.1]
  def change
    create_table :authors do |t|
      t.string :name, null: false
      t.text :bio
      t.integer :status, default: 0, null: false
      t.string :slug, null: false
      t.string :avatar_url
      t.string :github_url
      t.string :gitlab_url
      t.string :website_url
      t.string :bluesky_url
      t.string :ruby_social_url
      t.string :twitter_url
      t.string :linkedin_url
      t.string :youtube_url
      t.string :twitch_url
      t.string :blog_url

      t.timestamps
    end

    add_index :authors, :slug, unique: true
    add_index :authors, :name
    add_index :authors, :status
  end
end
