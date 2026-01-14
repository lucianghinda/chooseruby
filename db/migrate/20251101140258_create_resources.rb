# frozen_string_literal: true

class CreateResources < ActiveRecord::Migration[8.1]
  def change
    create_table :resources do |t|
      t.string :title
      t.text :description
      t.string :url
      t.integer :status

      t.timestamps
    end
  end
end
