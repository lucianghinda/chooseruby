# frozen_string_literal: true

class AddNameToBlogs < ActiveRecord::Migration[8.1]
  def change
    add_column :blogs, :name, :string
  end
end
