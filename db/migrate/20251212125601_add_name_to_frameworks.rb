# frozen_string_literal: true

class AddNameToFrameworks < ActiveRecord::Migration[8.1]
  def change
    add_column :frameworks, :name, :string
  end
end
