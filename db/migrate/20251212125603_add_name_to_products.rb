# frozen_string_literal: true

class AddNameToProducts < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :name, :string
  end
end
