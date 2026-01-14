# frozen_string_literal: true

class AddNameToDirectories < ActiveRecord::Migration[8.1]
  def change
    add_column :directories, :name, :string
  end
end
