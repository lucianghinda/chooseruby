# frozen_string_literal: true

class CreateGems < ActiveRecord::Migration[8.1]
  def change
    create_table :gems do |t|
      t.string :gem_name, null: false
      t.string :rubygems_url
      t.string :github_url
      t.string :documentation_url
      t.integer :downloads_count
      t.string :current_version

      t.timestamps
    end

    add_index :gems, :gem_name, unique: true
  end
end
