# frozen_string_literal: true

class CreateFrameworks < ActiveRecord::Migration[8.1]
  def change
    create_table :frameworks do |t|
      t.timestamps
    end
  end
end
