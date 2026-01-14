# frozen_string_literal: true

class AddPrimaryAndFeaturedToCategoriesEntries < ActiveRecord::Migration[8.1]
  def change
    # Add is_primary boolean column (default: false, not null)
    add_column :categories_entries, :is_primary, :boolean, default: false, null: false

    # Add is_featured boolean column (default: false, not null)
    add_column :categories_entries, :is_featured, :boolean, default: false, null: false

    # Add unique partial index on entry_id where is_primary = true
    # This ensures only one primary category per entry at the database level
    add_index :categories_entries, :entry_id, unique: true, where: "is_primary = 1", name: "index_categories_entries_on_entry_id_primary"
  end
end
