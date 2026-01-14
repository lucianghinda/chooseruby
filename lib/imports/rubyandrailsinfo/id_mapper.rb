# frozen_string_literal: true

module Rubyandrailsinfo
  # Utility class to map old IDs (from YAML) to new records (in database)
  # This allows us to reconstruct relationships without enforcing original IDs as primary keys
  class IdMapper
    def initialize
      @mappings = {
        categories: {},
        authors: {},
        entries: {}
      }
    end

    # Register mappings
    def register_category(old_id, category)
      @mappings[:categories][old_id.to_s] = category
    end

    def register_author(old_id, author)
      @mappings[:authors][old_id.to_s] = author
    end

    def register_entry(old_type, old_id, entry)
      key = "#{old_type}-#{old_id}"
      @mappings[:entries][key] = entry
    end

    # Find mappings
    def find_category(old_id)
      @mappings[:categories][old_id.to_s]
    end

    def find_author(old_id)
      @mappings[:authors][old_id.to_s]
    end

    def find_entry(old_type, old_id)
      key = "#{old_type}-#{old_id}"
      @mappings[:entries][key]
    end

    # Stats
    def stats
      {
        categories: @mappings[:categories].size,
        authors: @mappings[:authors].size,
        entries: @mappings[:entries].size
      }
    end
  end
end
