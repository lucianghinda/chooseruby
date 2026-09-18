# frozen_string_literal: true

module Imports
  module Rubyandrailsinfo
    # Reuses categories and authors by slug and registers their legacy identifiers.
    class ImportedCatalogRecord
      MODELS = { "tags" => Category, "authors" => Author }.freeze
      REGISTRARS = { "tags" => :register_category, "authors" => :register_author }.freeze

      def initialize(table, data, mapper)
        @table = table
        @data = data
        @mapper = mapper
      end

      def import
        @mapper.public_send(REGISTRARS.fetch(@table), @data["id"], record)
        :success
      end

      private

      def record
        MODELS.fetch(@table).strict_loading.find_or_create_by!(slug: @data["slug"]) do |record|
          record.assign_attributes(attributes.merge(EntityAttributes.timestamps(@data)))
        end
      end

      def attributes
        return { name: @data["title"] } if @table == "tags"

        @data.slice("name", "twitter_url", "github_url", "website_url").merge("status" => :approved)
      end
    end
  end
end
