# frozen_string_literal: true

namespace :fts do
  desc "Create FTS5 virtual tables for Ruby schema format"
  task create: :environment do
    puts "Creating FTS5 virtual tables..."

    # Create entries_fts
    if ActiveRecord::Base.connection.table_exists?("entries_fts")
      puts "  - entries_fts already exists"
    else
      ActiveRecord::Base.connection.execute(<<-SQL)
        CREATE VIRTUAL TABLE IF NOT EXISTS entries_fts USING fts5(
          entry_id UNINDEXED,
          title,
          description,
          tags,
          tokenize='porter ascii'
        );
      SQL
      puts "  ✓ Created entries_fts table"
    end

    # Create authors_fts
    if ActiveRecord::Base.connection.table_exists?("authors_fts")
      puts "  - authors_fts already exists"
    else
      ActiveRecord::Base.connection.execute(<<-SQL)
        CREATE VIRTUAL TABLE IF NOT EXISTS authors_fts USING fts5(
          author_id UNINDEXED,
          name,
          tokenize='porter ascii'
        );
      SQL
      puts "  ✓ Created authors_fts table"
    end

    puts "FTS5 tables ready!"
  end

  desc "Reindex all FTS5 tables (entries and authors)"
  task reindex_all: :environment do
    puts "Reindexing all FTS5 tables..."
    FtsReindexer.reindex_all
    puts "Reindexing completed successfully!"
  end

  desc "Reindex entries FTS5 table"
  task reindex_entries: :environment do
    puts "Reindexing entries FTS5 table..."
    FtsReindexer.reindex_entries
    puts "Entries reindexing completed!"
  end

  desc "Reindex authors FTS5 table"
  task reindex_authors: :environment do
    puts "Reindexing authors FTS5 table..."
    FtsReindexer.reindex_authors
    puts "Authors reindexing completed!"
  end
end

# Enhance db:test:prepare to automatically create FTS5 tables
Rake::Task["db:test:prepare"].enhance do
  Rake::Task["fts:create"].invoke
end
