# frozen_string_literal: true

class CreateJobs < ActiveRecord::Migration[8.1]
  def change
    create_table :jobs do |t|
      t.timestamps
    end
  end
end
