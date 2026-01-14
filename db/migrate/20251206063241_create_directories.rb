# frozen_string_literal: true

class CreateDirectories < ActiveRecord::Migration[8.1]
  def change
    create_table :directories do |t|
      t.timestamps
    end
  end
end
