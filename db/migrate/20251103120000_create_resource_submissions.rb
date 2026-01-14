# frozen_string_literal: true

class CreateResourceSubmissions < ActiveRecord::Migration[7.1]
  def change
    create_table :resource_submissions do |t|
      t.string :title, null: false
      t.string :url, null: false
      t.string :resource_type, null: false
      t.integer :experience_level
      t.text :category_ids
      t.text :description
      t.string :contact_name, null: false
      t.string :contact_email, null: false
      t.text :notes
      t.integer :status, null: false, default: 0
      t.datetime :reviewed_at

      t.timestamps
    end

    add_index :resource_submissions, :status
  end
end
