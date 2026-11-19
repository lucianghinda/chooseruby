# frozen_string_literal: true

namespace :fts do
  desc "Create FTS5 virtual tables for Ruby schema format"
  task create: :environment do
    FtsSchema.new.create_tables
  end

  desc "Reindex all FTS5 tables (entries and authors)"
  task reindex_all: :environment do
    FtsReindexer.new.reindex_all
  end

  desc "Reindex entries FTS5 table"
  task reindex_entries: :environment do
    FtsReindexer.new.reindex_entries
  end

  desc "Reindex authors FTS5 table"
  task reindex_authors: :environment do
    FtsReindexer.new.reindex_authors
  end
end

# Enhance db:test:prepare to automatically create FTS5 tables
Rake::Task["db:test:prepare"].enhance do
  Rake::Task["fts:create"].invoke
end
