# frozen_string_literal: true

module Imports
  module Rubyandrailsinfo
    # Derives Entry fields and the legacy lesson URL conventions from source data.
    class EntryAttributes
      def initialize(table, source, entry)
        @table = table
        @source = source
        @entry = entry
      end

      def attributes
        common.merge(specific).merge(EntityAttributes.timestamps(@source))
      end

      private

      def common
        {
          title: @entry["title"], description: @entry["content"], slug: @entry["slug"],
          status: :approved, published: true, tags: []
        }
      end

      def specific
        return { url: lesson_url, experience_level: :all_levels } if @table == "lessons"

        { url: default_url, experience_level: :intermediate, featured_at: featured_at }
      end

      def default_url
        url = @entry["website_url"] || @source["website_url"] || @source["amazon_url"]
        url.presence || "https://example.com/#{@entry['slug']}"
      end

      def lesson_url
        url = @entry["url"]
        return @entry["website_url"] if url.blank?

        url.match?(/^[a-zA-Z0-9_-]{11}$/) ? "https://www.youtube.com/watch?v=#{url}" : url
      end

      def featured_at
        Values.parse_timestamp(@source["created_at"]) if Values.parse_bool(@source["featured"])
      end
    end
  end
end
