# frozen_string_literal: true

class CreateEntryReviews < ActiveRecord::Migration[8.1]
  def change
    create_table :entry_reviews do |t|
      t.integer :entry_id, null: false
      t.integer :status, null: false, default: 0
      t.text :comment
      t.integer :reviewer_id

      t.timestamps
    end

    add_index :entry_reviews, :entry_id
    add_index :entry_reviews, :status
    add_foreign_key :entry_reviews, :entries
  end
end
