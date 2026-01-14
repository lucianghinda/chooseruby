# frozen_string_literal: true

class CreateBans < ActiveRecord::Migration[8.1]
  def change
    create_table :bans do |t|
      t.references :user, null: true, foreign_key: { on_delete: :cascade }, index: true
      t.string :ip_address
      t.text :reason
      t.datetime :expires_at

      t.timestamps
    end

    add_index :bans, :ip_address
    add_index :bans, :expires_at
  end
end
