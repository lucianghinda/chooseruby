# frozen_string_literal: true

class AddNameToVideos < ActiveRecord::Migration[8.1]
  def change
    add_column :videos, :name, :string
  end
end
