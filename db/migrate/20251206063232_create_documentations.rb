# frozen_string_literal: true

class CreateDocumentations < ActiveRecord::Migration[8.1]
  def change
    create_table :documentations do |t|
      t.timestamps
    end
  end
end
