# frozen_string_literal: true

class CreateEntriesFts < ActiveRecord::Migration[8.1]
  def change
    reversible do |dir|
      dir.up do
        # Create FTS5 virtual table for Entry full-text search
        # entry_id is UNINDEXED (not searchable, just stored for reference)
        # title, description, tags are searchable columns
        # tokenize='porter ascii' uses Porter stemming for English text
        execute <<-SQL
          CREATE VIRTUAL TABLE entries_fts USING fts5(
            entry_id UNINDEXED,
            title,
            description,
            tags,
            tokenize='porter ascii'
          );
        SQL
      end

      dir.down do
        execute "DROP TABLE IF EXISTS entries_fts;"
      end
    end
  end
end
