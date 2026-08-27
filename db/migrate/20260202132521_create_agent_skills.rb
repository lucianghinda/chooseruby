# frozen_string_literal: true

class CreateAgentSkills < ActiveRecord::Migration[8.2]
  def change
    create_table :agent_skills do |t|
      t.string :skill_file_url, null: false
      t.string :name
      t.string :skill_description
      t.string :license
      t.string :compatibility
      t.string :pattern
      t.text :metadata
      t.text :allowed_tools
      t.text :body
      t.integer :parse_status, default: 0, null: false
      t.text :parse_error

      t.timestamps
    end
  end
end
