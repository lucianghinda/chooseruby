# frozen_string_literal: true

class AddFieldsToResources < ActiveRecord::Migration[8.1]
  def change
    add_column :resources, :image_url, :string
    add_column :resources, :experience_level, :integer
    add_column :resources, :published, :boolean, default: false, null: false
    add_column :resources, :tags, :text
    add_column :resources, :slug, :string
    add_column :resources, :resourceable_type, :string
    add_column :resources, :resourceable_id, :integer

    # Update existing status column to have default
    change_column_default :resources, :status, from: nil, to: 0
    change_column_null :resources, :status, false, 0

    # Add indexes
    add_index :resources, :title
    add_index :resources, :slug, unique: true
    add_index :resources, :status
    add_index :resources, :published
    add_index :resources, :experience_level
    add_index :resources, [ :resourceable_type, :resourceable_id ]
  end
end
