# frozen_string_literal: true

class CreateVideos < ActiveRecord::Migration[8.1]
  def change
    create_table :videos do |t|
      t.timestamps
    end
  end
end
