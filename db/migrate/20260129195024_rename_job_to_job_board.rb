# frozen_string_literal: true

class RenameJobToJobBoard < ActiveRecord::Migration[8.2]
  def change
    rename_table :jobs, :job_boards
    reversible do |dir|
      dir.up do
        execute <<-SQL.squish
          UPDATE entries
          SET entryable_type = 'JobBoard'
          WHERE entryable_type = 'Job'
        SQL
      end
      dir.down do
        execute <<-SQL.squish
          UPDATE entries
          SET entryable_type = 'Job'
          WHERE entryable_type = 'JobBoard'
        SQL
      end
    end
  end
end
