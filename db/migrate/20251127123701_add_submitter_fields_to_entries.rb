# frozen_string_literal: true

class AddSubmitterFieldsToEntries < ActiveRecord::Migration[8.1]
  def change
    add_column :entries, :submitter_name, :string
    add_column :entries, :submitter_email, :string
  end
end
