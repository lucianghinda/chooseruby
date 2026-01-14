# frozen_string_literal: true

class CreateArticles < ActiveRecord::Migration[8.1]
  def change
    create_table :articles do |t|
      t.integer :reading_time_minutes
      t.date :publication_date
      t.string :author_name
      t.string :platform

      t.timestamps
    end
  end
end
