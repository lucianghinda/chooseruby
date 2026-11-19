# frozen_string_literal: true

module Imports
  module Rubyandrailsinfo
    # A normalized source resource with its legacy type and persistence identity.
    class EntityData
      TYPES = {
        "books" => "Book", "courses" => "Course", "newsletters" => "Newsletter",
        "podcasts" => "Podcast", "communities" => "Community", "youtubes" => "Youtube",
        "screencasts" => "Screencast", "lessons" => "Lesson"
      }.freeze
      MODELS = {
        "courses" => Course, "newsletters" => Newsletter, "podcasts" => Podcast,
        "communities" => Community, "youtubes" => Video, "screencasts" => Video, "lessons" => Video
      }.freeze

      def initialize(table, data)
        @table = table
        @data = data
        @entry = data["entry"] || {}
      end

      def id
        @data["id"]
      end

      def title
        @entry["title"]
      end

      def type
        TYPES.fetch(@table)
      end

      def record
        return book if @table == "books"

        MODELS.fetch(@table).strict_loading.create!(attributes)
      end

      def entry_attributes
        EntryAttributes.new(@table, @data, @entry).attributes
      end

      private

      def attributes
        EntityAttributes.build(@table, @data)
      end

      def book
        isbn = @data["isbn"]
        books = Book.strict_loading
        if isbn.present?
          books.find_or_create_by!(isbn: isbn) { |record| record.assign_attributes(attributes) }
        else
          books.joins(:entry).find_by(entries: { slug: @entry["slug"] }) || books.create!(attributes)
        end
      end
    end
  end
end
