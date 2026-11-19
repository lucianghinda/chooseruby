# frozen_string_literal: true

namespace :fts do
  desc "Create FTS5 virtual tables for Ruby schema format"
  task create: :environment do
    SearchIndex.new.create
  end

  desc "Reindex all FTS5 tables (entries and authors)"
  task reindex_all: :environment do
    SearchIndex.new.reindex_all
  end

  desc "Reindex entries FTS5 table"
  task reindex_entries: :environment do
    SearchIndex.new.reindex_entries
  end

  desc "Reindex authors FTS5 table"
  task reindex_authors: :environment do
    SearchIndex.new.reindex_authors
  end
end

# Enhance db:test:prepare to automatically create FTS5 tables.
Rake::Task["db:test:prepare"].enhance do
  Rake::Task["fts:create"].invoke
end
