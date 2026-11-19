# frozen_string_literal: true

module Imports
  module Rubyandrailsinfo
    # Restores polymorphic authorings and tags while skipping unresolved references.
    class ImportedAssociation
      REFERENCES = {
        "authorings" => [ :find_author, "author_id", "authorabble_type", "authorabble_id" ].freeze,
        "taggings" => [ :find_category, "tag_id", "taggable_type", "taggable_id" ].freeze
      }.freeze

      def initialize(table, data, mapper)
        @table = table
        finder, related_id, type_key, entry_id = REFERENCES.fetch(table)
        @related = mapper.public_send(finder, data[related_id])
        @entry = mapper.find_entry(data[type_key], data[entry_id])
      end

      def import
        return :skipped unless @related && @entry

        create_link
        :success
      end

      private

      def create_link
        if @table == "authorings"
          EntriesAuthor.strict_loading.find_or_create_by!(entry: @entry, author: @related)
        else
          CategoriesEntry.strict_loading.find_or_create_by!(entry: @entry, category: @related) do |record|
            record.is_primary = !CategoriesEntry.exists?(entry: @entry)
            record.is_featured = false
          end
        end
      end
    end
  end
end
