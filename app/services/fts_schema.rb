# frozen_string_literal: true

# Creates the SQLite FTS5 virtual tables the search queries read.
#
# `table_exists?` never reports virtual tables, so the statements carry their own
# IF NOT EXISTS guard rather than being wrapped in one.
class FtsSchema
  TABLES = {
    "entries_fts" => "entry_id UNINDEXED, title, description, tags",
    "authors_fts" => "author_id UNINDEXED, name"
  }.freeze

  def initialize(connection: ActiveRecord::Base.connection)
    @connection = connection
  end

  # @return [Array<String>] the tables that now exist
  def create_tables
    TABLES.each do |table, columns|
      @connection.execute(<<~SQL)
        CREATE VIRTUAL TABLE IF NOT EXISTS #{table} USING fts5(
          #{columns},
          tokenize='porter ascii'
        );
      SQL
    end

    TABLES.keys
  end
end
