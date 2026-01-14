# frozen_string_literal: true

class CreateResourcesAuthors < ActiveRecord::Migration[8.1]
  def change
    create_table :resources_authors do |t|
      t.references :author, null: false, foreign_key: { on_delete: :cascade }
      t.references :resource, null: false, foreign_key: { on_delete: :cascade }

      t.timestamps
    end

    # Add composite unique index to prevent duplicate author-resource associations
    add_index :resources_authors, [ :author_id, :resource_id ], unique: true
  end
end
