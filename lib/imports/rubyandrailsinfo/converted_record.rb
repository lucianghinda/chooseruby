# frozen_string_literal: true

module Imports
  module Rubyandrailsinfo
    # Separates a source row into resource attributes and its nested Entry attributes.
    class ConvertedRecord
      SIMPLE_TABLES = %w[ tags authors authorings taggings ].freeze
      COMMON_FIELDS = %w[ id created_at updated_at ].freeze
      ENTITY_FIELDS = {
        "books" => %w[ isbn year page amazon_url website_url free featured ].freeze,
        "courses" => %w[ free ].freeze,
        "communities" => %w[ platform_type members ].freeze,
        "lessons" => %w[ youtube_id ].freeze
      }.freeze
      URL_FIELDS = { "lessons" => "url" }.freeze

      def initialize(table_name, record)
        @table_name = table_name
        @record = record
      end

      def attributes
        return @record.compact if SIMPLE_TABLES.include?(@table_name)

        entity_fields.merge("entry" => entry_fields)
      end

      private

      def entity_fields
        fields = COMMON_FIELDS + ENTITY_FIELDS.fetch(@table_name, [])
        @record.slice(*fields).compact
      end

      def entry_fields
        url_field = URL_FIELDS.fetch(@table_name, "website_url")
        @record.slice("title", "content", "slug", url_field).compact
      end
    end
  end
end
