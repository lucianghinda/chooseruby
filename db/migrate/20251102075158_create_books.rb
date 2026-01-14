# frozen_string_literal: true

class CreateBooks < ActiveRecord::Migration[8.1]
  def change
    create_table :books do |t|
      t.string :isbn
      t.string :publisher
      t.integer :publication_year
      t.integer :page_count
      t.integer :format
      t.string :purchase_url

      t.timestamps
    end
  end
end
