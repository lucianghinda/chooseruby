# frozen_string_literal: true

class CreateAuthorsFts < ActiveRecord::Migration[8.1]
  def change
    reversible do |dir|
      dir.up do
        # Create FTS5 virtual table for Author full-text search
        # author_id is UNINDEXED (not searchable, just stored for reference)
        # name is the searchable column
        # tokenize='porter ascii' uses Porter stemming for English text
        execute <<-SQL
          CREATE VIRTUAL TABLE authors_fts USING fts5(
            author_id UNINDEXED,
            name,
            tokenize='porter ascii'
          );
        SQL
      end

      dir.down do
        execute "DROP TABLE IF EXISTS authors_fts;"
      end
    end
  end
end
