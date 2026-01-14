# frozen_string_literal: true

class CreateChannels < ActiveRecord::Migration[8.1]
  def change
    create_table :channels do |t|
      t.timestamps
    end
  end
end
