# frozen_string_literal: true

module Imports
  module Rubyandrailsinfo
    # Converts resource fields without mutating their source YAML hashes.
    module EntityAttributes
      BUILDERS = {
        "books" => :book, "courses" => :course, "newsletters" => :named,
        "podcasts" => :podcast, "communities" => :community, "youtubes" => :named,
        "screencasts" => :named, "lessons" => :named
      }.freeze

      module_function

      def build(table, data)
        public_send(BUILDERS.fetch(table), data).merge(timestamps(data))
      end

      def timestamps(data)
        { created_at: Values.parse_timestamp(data["created_at"]), updated_at: Values.parse_timestamp(data["updated_at"]) }
      end

      def book(data)
        {
          publication_year: data["year"]&.to_i, page_count: data["page"]&.to_i,
          purchase_url: data["amazon_url"] || data["website_url"], format: :both
        }
      end

      def course(data)
        { is_free: Values.parse_bool(data["free"]) }
      end

      def named(data)
        { name: data.dig("entry", "title") }
      end

      def podcast(_data)
        {}
      end

      def community(data)
        entry = data.fetch("entry")
        {
          platform: "Other", join_url: entry["website_url"].presence || "https://example.com/#{entry['slug']}",
          member_count: nil, is_official: false
        }
      end
    end
  end
end
