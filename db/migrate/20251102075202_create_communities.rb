# frozen_string_literal: true

class CreateCommunities < ActiveRecord::Migration[8.1]
  def change
    create_table :communities do |t|
      t.string :platform, null: false
      t.string :join_url, null: false
      t.integer :member_count
      t.boolean :is_official, default: false, null: false

      t.timestamps
    end
  end
end
