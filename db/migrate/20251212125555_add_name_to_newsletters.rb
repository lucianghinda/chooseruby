# frozen_string_literal: true

class AddNameToNewsletters < ActiveRecord::Migration[8.1]
  def change
    add_column :newsletters, :name, :string
  end
end
