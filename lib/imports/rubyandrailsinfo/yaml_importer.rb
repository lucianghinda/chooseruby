# frozen_string_literal: true

module Imports
  module Rubyandrailsinfo
    # Main importer class to load YAML files and create database records
    # Uses idempotent strategies (find_or_create_by) and ID mapping for relationships
    class YamlImporter
      # Every entity table imports the same way. A spec names the YAML file, the old
      # polymorphic type authorings/taggings refer to, and the experience level its
      # entries get.
      ENTITY_SPECS = [
        { file: "books.yml", type: "Book", level: :intermediate },
        { file: "courses.yml", type: "Course", level: :intermediate },
        { file: "newsletters.yml", type: "Newsletter", level: :intermediate },
        { file: "podcasts.yml", type: "Podcast", level: :intermediate },
        { file: "communities.yml", type: "Community", level: :intermediate },
        { file: "youtubes.yml", type: "Youtube", level: :intermediate },
        { file: "screencasts.yml", type: "Screencast", level: :intermediate },
        { file: "lessons.yml", type: "Lesson", level: :all_levels }
      ].freeze

      # A bare YouTube video id, which is what lessons store instead of a URL.
      YOUTUBE_ID = /\A[a-zA-Z0-9_-]{11}\z/

      def initialize(yaml_dir:)
        @yaml_dir = yaml_dir
        @id_mapper = IdMapper.new
        @stats = {}
      end

      def import_all
        puts "Importing YAML data from #{@yaml_dir}..."
        puts

        # Import in dependency order
        import_categories
        import_authors
        ENTITY_SPECS.each { |spec| import_entities(spec) }
        import_authorings
        import_taggings

        print_summary
      end

      private

      def import_categories
        import_rows(:categories, "tags.yml") do |row|
          category = Category.find_or_create_by!(slug: row["slug"]) do |c|
            c.name = row["title"]
            c.assign_attributes(timestamps(row))
          end

          @id_mapper.register_category(row["id"], category)
          category
        end
      end

      def import_authors
        import_rows(:authors, "authors.yml") do |row|
          author = Author.find_or_create_by!(slug: row["slug"]) do |a|
            a.assign_attributes(
              name: row["name"],
              twitter_url: row["twitter_url"],
              github_url: row["github_url"],
              website_url: row["website_url"],
              status: :approved,
              **timestamps(row)
            )
          end

          @id_mapper.register_author(row["id"], author)
          author
        end
      end

      def import_entities(spec)
        import_rows(spec[:file].chomp(".yml").to_sym, spec[:file]) do |row|
          entry_data = row["entry"]
          next if entry_data.blank? || entry_data["title"].blank?

          entry = Entry.find_by(slug: entry_data["slug"]) || create_entry(spec, row, entry_data)

          @id_mapper.register_entry(spec[:type], row["id"], entry)
          entry
        end
      end

      # The entryable is only built once the entry is known to be missing. Building it
      # first and letting `find_or_create_by!(entryable:)` decide meant a fresh
      # entryable never matched the entry that was already there, so every re-import
      # duplicated the entry and orphaned the one before it.
      def create_entry(spec, row, entry_data)
        Entry.create!(entryable: entryable_for(spec[:type], row, entry_data)) do |entry|
          set_entry_fields(entry, entry_data, row, spec[:level])
        end
      end

      def import_authorings
        import_rows(:authorings, "authorings.yml") do |row|
          author = @id_mapper.find_author(row["author_id"])
          entry = @id_mapper.find_entry(row["authorabble_type"], row["authorabble_id"])
          next unless author && entry

          EntriesAuthor.find_or_create_by!(entry: entry, author: author)
        end
      end

      def import_taggings
        import_rows(:taggings, "taggings.yml") do |row|
          category = @id_mapper.find_category(row["tag_id"])
          entry = @id_mapper.find_entry(row["taggable_type"], row["taggable_id"])
          next unless category && entry

          CategoriesEntry.find_or_create_by!(entry: entry, category: category) do |ce|
            # The first category an entry gets is its primary one.
            ce.is_primary = CategoriesEntry.where(entry: entry).none?
            ce.is_featured = false
          end
        end
      end

      # Runs the block once per row of the YAML file and counts the outcome: a record
      # is a success, nil is a skip, a raised error is an error.
      def import_rows(label, filename)
        counts = { success: 0, errors: 0, skipped: 0 }

        load_yaml(filename).each do |row|
          counts[yield(row) ? :success : :skipped] += 1
        rescue => e
          puts "  ✗ Error importing #{label} #{row['id']}: #{e.message}"
          counts[:errors] += 1
        end

        @stats[label] = counts
        puts "✓ Imported #{counts[:success]} #{label} (#{counts[:errors]} errors, #{counts[:skipped]} skipped)"
      end

      def entryable_for(type, row, entry_data)
        case type
        when "Book" then book_for(row)
        when "Course" then Course.create!(is_free: parse_bool(row["free"]), **timestamps(row))
        when "Newsletter" then Newsletter.create!(name: entry_data["title"], **timestamps(row))
        when "Podcast" then Podcast.create!(**timestamps(row))
        when "Community" then community_for(row, entry_data)
        else Video.create!(name: entry_data["title"], **timestamps(row))
        end
      end

      # Books are idempotent on their ISBN. Without one there is nothing to match on,
      # and the entry this book belongs to was already looked up by its slug.
      def book_for(row)
        return Book.find_or_create_by!(isbn: row["isbn"]) { |b| set_book_fields(b, row) } if row["isbn"].present?

        Book.create! { |b| set_book_fields(b, row) }
      end

      def community_for(row, entry_data)
        Community.create!(
          platform: "Other", # the YAML has no platform_type
          join_url: entry_data["website_url"].presence || placeholder_url(entry_data),
          **timestamps(row)
        )
      end

      def set_book_fields(book, row)
        book.publication_year = row["year"].to_i if row["year"]
        book.page_count = row["page"].to_i if row["page"]
        book.purchase_url = row["amazon_url"] || row["website_url"]
        book.format = :both
        book.assign_attributes(timestamps(row))
      end

      def set_entry_fields(entry, entry_data, row, level)
        entry.assign_attributes(
          slug: entry_data["slug"],
          title: entry_data["title"],
          description: entry_data["content"],
          url: entry_url(entry_data, row),
          status: :approved,
          published: true,
          experience_level: level,
          tags: [],
          featured_at: parse_bool(row["featured"]) ? parse_time(row["created_at"]) : nil,
          **timestamps(row)
        )
      end

      # Lessons carry their video in entry["url"]; every other type has a website_url
      # somewhere, and when it has none the slug stands in for one.
      def entry_url(entry_data, row)
        video = entry_data["url"].presence
        return youtube_url(video) if video

        entry_data["website_url"].presence || row["website_url"].presence ||
          row["amazon_url"].presence || placeholder_url(entry_data)
      end

      def youtube_url(video)
        video.match?(YOUTUBE_ID) ? "https://www.youtube.com/watch?v=#{video}" : video
      end

      def placeholder_url(entry_data)
        "https://example.com/#{entry_data['slug']}"
      end

      def load_yaml(filename)
        YAML.load_file(File.join(@yaml_dir, filename)) || []
      end

      def timestamps(row)
        { created_at: parse_time(row["created_at"]), updated_at: parse_time(row["updated_at"]) }
      end

      def parse_time(str)
        return nil if str.blank?

        Time.zone.parse(str)
      rescue ArgumentError
        nil
      end

      def parse_bool(str)
        str.to_s == "t" || str.to_s == "true"
      end

      def print_summary
        puts
        puts "=" * 60
        puts "Import Summary"
        puts "=" * 60
        @stats.each do |label, counts|
          puts "#{label.to_s.capitalize}: #{counts[:success]} success"
          puts "  Errors: #{counts[:errors]}" if counts[:errors] > 0
          puts "  Skipped: #{counts[:skipped]}" if counts[:skipped] > 0
        end
        puts
        puts "ID Mappings: #{@id_mapper.stats.inspect}"
      end
    end
  end
end
