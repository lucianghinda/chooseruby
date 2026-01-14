# frozen_string_literal: true

class CreateCategoriesResources < ActiveRecord::Migration[8.1]
  def change
    create_table :categories_resources do |t|
      t.integer :category_id, null: false
      t.integer :resource_id, null: false

      t.timestamps
    end

    add_index :categories_resources, :category_id
    add_index :categories_resources, :resource_id
    add_index :categories_resources, [ :category_id, :resource_id ], unique: true

    add_foreign_key :categories_resources, :categories, on_delete: :cascade
    add_foreign_key :categories_resources, :resources, on_delete: :cascade
  end
end
