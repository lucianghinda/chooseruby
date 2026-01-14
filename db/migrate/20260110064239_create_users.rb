# frozen_string_literal: true

class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :email_address, null: false
      t.string :password_digest, null: false
      t.string :name, null: false
      t.integer :status, default: 0, null: false
      t.integer :role, default: 0, null: false

      t.timestamps
    end
    add_index :users, :email_address, unique: true
    add_index :users, :status
  end
end
