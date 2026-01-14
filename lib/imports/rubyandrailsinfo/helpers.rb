# frozen_string_literal: true

module Rubyandrailsinfo
  # Helper methods for importing data from PostgreSQL dump
  # Provides ID mapping for polymorphic associations and data conversion utilities
  module Helpers
    # Module-level instance variables for ID mapping
    @entry_lookup = {}
    @author_lookup = {}
    @category_lookup = {}

    class << self
      # Entry registration and lookup (for polymorphic authorings/taggings)

      def register_entry(old_type, old_id, entry)
        key = "#{old_type}-#{old_id}"
        @entry_lookup[key] = entry
      end

      def find_entry(old_type, old_id)
        key = "#{old_type}-#{old_id}"
        @entry_lookup[key]
      end

      # Author registration and lookup

      def register_author(old_id, author)
        @author_lookup[old_id.to_s] = author
      end

      def find_author(old_id)
        @author_lookup[old_id.to_s]
      end

      # Category registration and lookup (old tag_id → Category)

      def register_category(old_tag_id, category)
        @category_lookup[old_tag_id.to_s] = category
      end

      def find_category(old_tag_id)
        @category_lookup[old_tag_id.to_s]
      end

      # Data conversion helpers

      def parse_time(str)
        return nil if str.nil? || str == '\N' || str.empty?
        Time.zone.parse(str)
      rescue ArgumentError
        nil
      end

      def parse_bool(str)
        str == "t" || str == "true"
      end

      def to_int(str)
        return nil if str.nil? || str == '\N' || str.empty?
        str.to_i
      end

      # Progress output helper

      def progress(current, total, label)
        print "\r  #{label}: #{current}/#{total}"
        puts "" if current == total
      end

      # Reset all lookups (useful for testing)

      def reset_lookups!
        @entry_lookup = {}
        @author_lookup = {}
        @category_lookup = {}
      end
    end
  end
end
