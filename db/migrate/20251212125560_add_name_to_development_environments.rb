# frozen_string_literal: true

class AddNameToDevelopmentEnvironments < ActiveRecord::Migration[8.1]
  def change
    add_column :development_environments, :name, :string
  end
end
