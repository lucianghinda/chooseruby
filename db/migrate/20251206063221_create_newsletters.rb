# frozen_string_literal: true

class CreateNewsletters < ActiveRecord::Migration[8.1]
  def change
    create_table :newsletters do |t|
      t.timestamps
    end
  end
end
