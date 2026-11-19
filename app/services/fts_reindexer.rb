# frozen_string_literal: true

# Rebuilds full-text indexes from the authoritative records.
class FtsReindexer
  DEFAULT_BATCH_SIZE = 1000

  def initialize(entries: Entry.all, authors: Author.all)
    @entries = entries
    @authors = authors
  end

  def reindex_all
    reindex_entries
    reindex_authors
  end

  def reindex_entries(batch_size: DEFAULT_BATCH_SIZE)
    entries.find_each(batch_size: batch_size) do |entry|
      entry.send(:sync_to_fts)
    end
  end

  def reindex_authors(batch_size: DEFAULT_BATCH_SIZE)
    authors.find_each(batch_size: batch_size) do |author|
      author.send(:sync_to_fts)
    end
  end

  private

  attr_reader :entries, :authors
end
