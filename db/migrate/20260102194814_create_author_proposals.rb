# frozen_string_literal: true

class CreateAuthorProposals < ActiveRecord::Migration[8.1]
  def change
    create_table :author_proposals do |t|
      # Foreign key associations
      t.references :author, foreign_key: { on_delete: :cascade }, null: true, index: true
      t.references :matched_entry, foreign_key: { to_table: :entries, on_delete: :nullify }, null: true, index: true

      # Resource URL fields
      t.text :resource_url, null: true
      t.text :original_resource_url, null: true

      # Proposed changes fields
      t.text :link_updates, null: true  # JSON serialized hash of link fields
      t.text :bio_text, null: true
      t.text :description_text, null: true

      # New author proposal fields
      t.string :author_name, null: true

      # Submitter information
      t.string :submitter_name, null: true
      t.string :submitter_email, null: false
      t.text :submission_notes, null: true

      # Review workflow fields
      t.integer :status, default: 0, null: false  # enum: pending=0, approved=1, rejected=2
      t.integer :reviewer_id, null: true
      t.text :admin_comment, null: true
      t.datetime :reviewed_at, null: true

      t.timestamps
    end

    # Additional indexes for common queries
    add_index :author_proposals, :status
    add_index :author_proposals, :submitter_email
    add_index :author_proposals, :created_at
  end
end
