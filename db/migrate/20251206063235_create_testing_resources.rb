# frozen_string_literal: true

class CreateTestingResources < ActiveRecord::Migration[8.1]
  def change
    create_table :testing_resources do |t|
      t.timestamps
    end
  end
end
