# frozen_string_literal: true

class AddFeaturedAtToEntries < ActiveRecord::Migration[8.1]
  def change
    add_column :entries, :featured_at, :datetime
  end
end
