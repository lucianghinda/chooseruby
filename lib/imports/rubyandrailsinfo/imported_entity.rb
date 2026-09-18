# frozen_string_literal: true

module Imports
  module Rubyandrailsinfo
    # Persists a resource and its Entry, then exposes the old identifier to joins.
    class ImportedEntity
      def initialize(table, data, mapper)
        @source = EntityData.new(table, data)
        @mapper = mapper
      end

      def import
        return :skipped unless @source.title.present?

        @mapper.register_entry(@source.type, @source.id, entry)
        :success
      end

      private

      def entry
        Entry.strict_loading.find_or_create_by!(entryable: @source.record) do |record|
          record.assign_attributes(@source.entry_attributes)
        end
      end
    end
  end
end
