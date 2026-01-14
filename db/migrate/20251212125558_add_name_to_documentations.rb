# frozen_string_literal: true

class AddNameToDocumentations < ActiveRecord::Migration[8.1]
  def change
    add_column :documentations, :name, :string
  end
end
