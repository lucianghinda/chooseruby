# frozen_string_literal: true

class CreateCourses < ActiveRecord::Migration[8.1]
  def change
    create_table :courses do |t|
      t.string :platform
      t.string :instructor
      t.decimal :duration_hours, precision: 5, scale: 2
      t.integer :price_cents
      t.string :currency, default: "USD"
      t.boolean :is_free, default: false, null: false
      t.string :enrollment_url

      t.timestamps
    end
  end
end
