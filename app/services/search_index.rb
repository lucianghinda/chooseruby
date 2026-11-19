# frozen_string_literal: true

# Creates SQLite full-text tables and reports the progress of maintenance commands.
class SearchIndex
  TABLE_DEFINITIONS = {
    "entries_fts" => "CREATE VIRTUAL TABLE IF NOT EXISTS entries_fts USING fts5(entry_id UNINDEXED, title, description, tags, tokenize='porter ascii')",
    "authors_fts" => "CREATE VIRTUAL TABLE IF NOT EXISTS authors_fts USING fts5(author_id UNINDEXED, name, tokenize='porter ascii')"
  }.freeze

  def initialize(connection: ActiveRecord::Base.connection, output: $stdout)
    @connection = connection
    @output = output
    @reindexer = FtsReindexer.new
  end

  def create
    output.puts "Creating FTS5 virtual tables..."
    TABLE_DEFINITIONS.each { |name, definition| create_table(name, definition) }
    output.puts "FTS5 tables ready!"
  end

  def reindex_all
    output.puts "Reindexing all FTS5 tables..."
    reindexer.reindex_all
    output.puts "Reindexing completed successfully!"
  end

  def reindex_entries
    output.puts "Reindexing entries FTS5 table..."
    reindexer.reindex_entries
    output.puts "Entries reindexing completed!"
  end

  def reindex_authors
    output.puts "Reindexing authors FTS5 table..."
    reindexer.reindex_authors
    output.puts "Authors reindexing completed!"
  end

  private

  attr_reader :connection, :output, :reindexer

  def create_table(name, definition)
    if connection.virtual_tables.to_h.key?(name)
      output.puts "  - #{name} already exists"
      return
    end

    connection.execute(definition)
    output.puts "  ✓ Created #{name} table"
  end
end
