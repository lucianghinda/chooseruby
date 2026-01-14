# frozen_string_literal: true

class AddNameToTestingResources < ActiveRecord::Migration[8.1]
  def change
    add_column :testing_resources, :name, :string
  end
end
