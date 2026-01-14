# frozen_string_literal: true

class RemoveResourceSubmissionFromEntries < ActiveRecord::Migration[8.0]
  def change
    remove_column :entries, :resource_submission_id, :integer, if_exists: true
    drop_table :resource_submissions, if_exists: true do |t|
      t.string :title, null: false
      t.string :url, null: false
      t.string :resource_type, null: false
      t.string :contact_name, null: false
      t.string :contact_email, null: false
      t.text :description
      t.text :category_ids
      t.text :notes
      t.integer :status, default: 0, null: false
      t.integer :experience_level
      t.datetime :reviewed_at
      t.timestamps

      t.index :status
    end
  end
end
