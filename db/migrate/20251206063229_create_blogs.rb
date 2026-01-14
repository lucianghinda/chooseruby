# frozen_string_literal: true

class CreateBlogs < ActiveRecord::Migration[8.1]
  def change
    create_table :blogs do |t|
      t.timestamps
    end
  end
end
