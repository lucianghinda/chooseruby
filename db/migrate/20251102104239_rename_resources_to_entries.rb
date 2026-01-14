# frozen_string_literal: true

class RenameResourcesToEntries < ActiveRecord::Migration[8.1]
  def change
    # Rename the main resources table to entries
    rename_table :resources, :entries

    # Rename the categories_resources join table to categories_entries
    rename_table :categories_resources, :categories_entries

    # Rename the resources_authors join table to entries_authors
    rename_table :resources_authors, :entries_authors

    # Update foreign key columns in join tables
    rename_column :categories_entries, :resource_id, :entry_id
    rename_column :entries_authors, :resource_id, :entry_id

    # Update polymorphic association columns in the entries table (parent table)
    rename_column :entries, :resourceable_type, :entryable_type
    rename_column :entries, :resourceable_id, :entryable_id
  end
end
