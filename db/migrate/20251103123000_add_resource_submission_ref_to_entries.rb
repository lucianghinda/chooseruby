# frozen_string_literal: true

class AddResourceSubmissionRefToEntries < ActiveRecord::Migration[7.1]
  def change
    add_reference :entries, :resource_submission, foreign_key: true
  end
end
