# frozen_string_literal: true

class FtsReindexer
  DEFAULT_BATCH_SIZE = 1000

  def reindex_all
    reindex_entries
    reindex_authors
  end

  def reindex_entries(batch_size: DEFAULT_BATCH_SIZE)
    Entry.find_each(batch_size: batch_size) do |entry|
      entry.send(:sync_to_fts)
    end
  end

  def reindex_authors(batch_size: DEFAULT_BATCH_SIZE)
    Author.find_each(batch_size: batch_size) do |author|
      author.send(:sync_to_fts)
    end
  end
end
