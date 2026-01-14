# frozen_string_literal: true

class CreateTools < ActiveRecord::Migration[8.1]
  def change
    create_table :tools do |t|
      t.string :tool_type
      t.string :github_url
      t.string :documentation_url
      t.string :license
      t.boolean :is_open_source, default: true, null: false

      t.timestamps
    end
  end
end
