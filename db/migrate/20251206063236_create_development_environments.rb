# frozen_string_literal: true

class CreateDevelopmentEnvironments < ActiveRecord::Migration[8.1]
  def change
    create_table :development_environments do |t|
      t.timestamps
    end
  end
end
