# frozen_string_literal: true

# A single record's row in one of the SQLite FTS5 virtual tables.
#
# FTS5 tables have no primary key and therefore no upsert, so keeping a row in
# sync always means deleting the old row and inserting a fresh one. This object
# owns that dance and the SQL that goes with it, so the models only have to say
# which columns they want indexed.
#
# Usage:
#   FtsIndex.new(table: "authors_fts", key_column: "author_id", key: id).replace(name: name)
#   FtsIndex.new(table: "authors_fts", key_column: "author_id", key: id).delete
class FtsIndex
  # @param table [String] name of the FTS5 virtual table
  # @param key_column [String] column holding the id of the indexed record
  # @param key [Integer] id of the indexed record
  def initialize(table:, key_column:, key:)
    @table = table
    @key_column = key_column
    @key = key
  end

  # Replaces the indexed row with the given column values
  #
  # @param columns [Hash{Symbol => String}] indexed column names and their text
  # @return [void]
  def replace(columns)
    delete
    insert_row(columns)
  end

  # Removes the indexed row
  #
  # @return [void]
  def delete
    ActiveRecord::Base.connection.execute(
      ActiveRecord::Base.sanitize_sql_array([
        "DELETE FROM #{@table} WHERE #{@key_column} = ?",
        @key
      ])
    )
  end

  private

  def insert_row(columns)
    column_names = [ @key_column, *columns.keys ].join(", ")
    placeholders = Array.new(columns.length + 1, "?").join(", ")

    ActiveRecord::Base.connection.execute(
      ActiveRecord::Base.sanitize_sql_array([
        "INSERT INTO #{@table} (#{column_names}) VALUES (#{placeholders})",
        @key,
        *columns.values
      ])
    )
  end
end
