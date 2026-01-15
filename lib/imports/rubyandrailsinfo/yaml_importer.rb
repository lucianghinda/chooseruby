# frozen_string_literal: true

module Imports
  module Rubyandrailsinfo
    # Main importer class to load YAML files and create database records
    # Uses idempotent strategies (find_or_create_by) and ID mapping for relationships
    class YamlImporter
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

        # Import entities + entries
        import_books
        import_courses
        import_newsletters
        import_podcasts
        import_communities
        import_youtubes
        import_screencasts
        import_lessons

        # Import relationships
        import_authorings
        import_taggings

        print_summary
      end

      private

      def import_categories
        data = load_yaml("tags.yml")
        success = 0
        errors = 0

        data.each do |tag_yaml|
          old_id = tag_yaml["id"]

          # Use slug for idempotency
          category = Category.find_or_create_by!(slug: tag_yaml["slug"]) do |c|
            c.name = tag_yaml["title"]
            c.created_at = parse_time(tag_yaml["created_at"])
            c.updated_at = parse_time(tag_yaml["updated_at"])
          end

          @id_mapper.register_category(old_id, category)
          success += 1
        rescue => e
          puts "  ✗ Error importing category #{old_id}: #{e.message}"
          errors += 1
        end

        @stats[:categories] = { success: success, errors: errors }
        puts "✓ Imported #{success} categories (#{errors} errors)"
      end

      def import_authors
        data = load_yaml("authors.yml")
        success = 0
        errors = 0

        data.each do |author_yaml|
          old_id = author_yaml["id"]

          # Use slug for idempotency
          author = Author.find_or_create_by!(slug: author_yaml["slug"]) do |a|
            a.name = author_yaml["name"]
            a.twitter_url = author_yaml["twitter_url"]
            a.github_url = author_yaml["github_url"]
            a.website_url = author_yaml["website_url"]
            a.status = :approved
            a.created_at = parse_time(author_yaml["created_at"])
            a.updated_at = parse_time(author_yaml["updated_at"])
          end

          @id_mapper.register_author(old_id, author)
          success += 1
        rescue => e
          puts "  ✗ Error importing author #{old_id}: #{e.message}"
          errors += 1
        end

        @stats[:authors] = { success: success, errors: errors }
        puts "✓ Imported #{success} authors (#{errors} errors)"
      end

      def import_books
        data = load_yaml("books.yml")
        success = 0
        errors = 0
        skipped = 0

        data.each do |book_yaml|
          old_id = book_yaml["id"]
          entry_data = book_yaml["entry"]

          # Skip if no entry title
          unless entry_data && entry_data["title"].present?
            skipped += 1
            next
          end

          # Strategy for idempotency:
          # 1. If ISBN present: find_or_create_by(isbn)
          # 2. If no ISBN: look for existing Entry by slug, use its book if found
          book = if book_yaml["isbn"].present?
            Book.find_or_create_by!(isbn: book_yaml["isbn"]) do |b|
              set_book_fields(b, book_yaml)
            end
          else
            # No ISBN - try to find existing entry by slug
            existing_entry = Entry.find_by(slug: entry_data["slug"], entryable_type: "Book")
            if existing_entry&.entryable
              # Found existing book via entry slug
              existing_entry.entryable
            else
              # Create new book
              Book.create! do |b|
                set_book_fields(b, book_yaml)
              end
            end
          end

          # Create or update entry
          entry = Entry.find_or_create_by!(entryable: book) do |e|
            set_entry_fields(e, entry_data, book_yaml)
          end

          @id_mapper.register_entry("Book", old_id, entry)
          success += 1
        rescue => e
          puts "  ✗ Error importing book #{old_id}: #{e.message}"
          errors += 1
        end

        @stats[:books] = { success: success, errors: errors, skipped: skipped }
        puts "✓ Imported #{success} books (#{errors} errors, #{skipped} skipped)"
      end

      def import_courses
        data = load_yaml("courses.yml")
        success = 0
        errors = 0
        skipped = 0

        data.each do |course_yaml|
          old_id = course_yaml["id"]
          entry_data = course_yaml["entry"]

          # Skip if no entry title
          unless entry_data && entry_data["title"].present?
            skipped += 1
            next
          end

          # Create course (no unique field besides Entry relationship)
          course = Course.create! do |c|
            c.is_free = parse_bool(course_yaml["free"])
            c.created_at = parse_time(course_yaml["created_at"])
            c.updated_at = parse_time(course_yaml["updated_at"])
          end

          # Create entry
          entry = Entry.find_or_create_by!(entryable: course) do |e|
            set_entry_fields(e, entry_data, course_yaml)
          end

          @id_mapper.register_entry("Course", old_id, entry)
          success += 1
        rescue => e
          puts "  ✗ Error importing course #{old_id}: #{e.message}"
          errors += 1
        end

        @stats[:courses] = { success: success, errors: errors, skipped: skipped }
        puts "✓ Imported #{success} courses (#{errors} errors, #{skipped} skipped)"
      end

      def import_newsletters
        data = load_yaml("newsletters.yml")
        success = 0
        errors = 0
        skipped = 0

        data.each do |newsletter_yaml|
          old_id = newsletter_yaml["id"]
          entry_data = newsletter_yaml["entry"]

          # Skip if no entry title
          unless entry_data && entry_data["title"].present?
            skipped += 1
            next
          end

          # Create newsletter
          newsletter = Newsletter.create! do |n|
            n.name = entry_data["title"]
            n.created_at = parse_time(newsletter_yaml["created_at"])
            n.updated_at = parse_time(newsletter_yaml["updated_at"])
          end

          # Create entry
          entry = Entry.find_or_create_by!(entryable: newsletter) do |e|
            set_entry_fields(e, entry_data, newsletter_yaml)
          end

          @id_mapper.register_entry("Newsletter", old_id, entry)
          success += 1
        rescue => e
          puts "  ✗ Error importing newsletter #{old_id}: #{e.message}"
          errors += 1
        end

        @stats[:newsletters] = { success: success, errors: errors, skipped: skipped }
        puts "✓ Imported #{success} newsletters (#{errors} errors, #{skipped} skipped)"
      end

      def import_podcasts
        data = load_yaml("podcasts.yml")
        success = 0
        errors = 0
        skipped = 0

        data.each do |podcast_yaml|
          old_id = podcast_yaml["id"]
          entry_data = podcast_yaml["entry"]

          # Skip if no entry title
          unless entry_data && entry_data["title"].present?
            skipped += 1
            next
          end

          # Create podcast
          podcast = Podcast.create! do |p|
            p.created_at = parse_time(podcast_yaml["created_at"])
            p.updated_at = parse_time(podcast_yaml["updated_at"])
          end

          # Create entry
          entry = Entry.find_or_create_by!(entryable: podcast) do |e|
            set_entry_fields(e, entry_data, podcast_yaml)
          end

          @id_mapper.register_entry("Podcast", old_id, entry)
          success += 1
        rescue => e
          puts "  ✗ Error importing podcast #{old_id}: #{e.message}"
          errors += 1
        end

        @stats[:podcasts] = { success: success, errors: errors, skipped: skipped }
        puts "✓ Imported #{success} podcasts (#{errors} errors, #{skipped} skipped)"
      end

      def import_communities
        data = load_yaml("communities.yml")
        success = 0
        errors = 0
        skipped = 0

        data.each do |community_yaml|
          old_id = community_yaml["id"]
          entry_data = community_yaml["entry"]

          # Skip if no entry title
          unless entry_data && entry_data["title"].present?
            skipped += 1
            next
          end

          # Get join_url or generate placeholder
          join_url = entry_data["website_url"].presence || "https://example.com/#{entry_data['slug']}"

          # Create community
          community = Community.create! do |c|
            c.platform = "Other" # Default since YAML doesn't have platform_type
            c.join_url = join_url
            c.member_count = nil # Not in YAML
            c.is_official = false # Default
            c.created_at = parse_time(community_yaml["created_at"])
            c.updated_at = parse_time(community_yaml["updated_at"])
          end

          # Create entry
          entry = Entry.find_or_create_by!(entryable: community) do |e|
            set_entry_fields(e, entry_data, community_yaml)
          end

          @id_mapper.register_entry("Community", old_id, entry)
          success += 1
        rescue => e
          puts "  ✗ Error importing community #{old_id}: #{e.message}"
          errors += 1
        end

        @stats[:communities] = { success: success, errors: errors, skipped: skipped }
        puts "✓ Imported #{success} communities (#{errors} errors, #{skipped} skipped)"
      end

      def import_youtubes
        data = load_yaml("youtubes.yml")
        success = 0
        errors = 0
        skipped = 0

        data.each do |youtube_yaml|
          old_id = youtube_yaml["id"]
          entry_data = youtube_yaml["entry"]

          # Skip if no entry title
          unless entry_data && entry_data["title"].present?
            skipped += 1
            next
          end

          # Create video
          video = Video.create! do |v|
            v.name = entry_data["title"]
            v.created_at = parse_time(youtube_yaml["created_at"])
            v.updated_at = parse_time(youtube_yaml["updated_at"])
          end

          # Create entry
          entry = Entry.find_or_create_by!(entryable: video) do |e|
            set_entry_fields(e, entry_data, youtube_yaml)
          end

          @id_mapper.register_entry("Youtube", old_id, entry)
          success += 1
        rescue => e
          puts "  ✗ Error importing youtube #{old_id}: #{e.message}"
          errors += 1
        end

        @stats[:youtubes] = { success: success, errors: errors, skipped: skipped }
        puts "✓ Imported #{success} youtubes (#{errors} errors, #{skipped} skipped)"
      end

      def import_screencasts
        data = load_yaml("screencasts.yml")
        success = 0
        errors = 0
        skipped = 0

        data.each do |screencast_yaml|
          old_id = screencast_yaml["id"]
          entry_data = screencast_yaml["entry"]

          # Skip if no entry title
          unless entry_data && entry_data["title"].present?
            skipped += 1
            next
          end

          # Create video
          video = Video.create! do |v|
            v.name = entry_data["title"]
            v.created_at = parse_time(screencast_yaml["created_at"])
            v.updated_at = parse_time(screencast_yaml["updated_at"])
          end

          # Create entry
          entry = Entry.find_or_create_by!(entryable: video) do |e|
            set_entry_fields(e, entry_data, screencast_yaml)
          end

          @id_mapper.register_entry("Screencast", old_id, entry)
          success += 1
        rescue => e
          puts "  ✗ Error importing screencast #{old_id}: #{e.message}"
          errors += 1
        end

        @stats[:screencasts] = { success: success, errors: errors, skipped: skipped }
        puts "✓ Imported #{success} screencasts (#{errors} errors, #{skipped} skipped)"
      end

      def import_lessons
        data = load_yaml("lessons.yml")
        success = 0
        errors = 0
        skipped = 0

        data.each do |lesson_yaml|
          old_id = lesson_yaml["id"]
          entry_data = lesson_yaml["entry"]

          # Skip if no entry title
          unless entry_data && entry_data["title"].present?
            skipped += 1
            next
          end

          # Create video
          video = Video.create! do |v|
            v.name = entry_data["title"]
            v.created_at = parse_time(lesson_yaml["created_at"])
            v.updated_at = parse_time(lesson_yaml["updated_at"])
          end

          # Create entry - construct full YouTube URL from video ID if needed
          entry = Entry.find_or_create_by!(entryable: video) do |e|
            # Lessons have URL in entry_data['url'] which is the YouTube video ID
            url = if entry_data["url"].present?
              # If it looks like a video ID (not a full URL), construct YouTube URL
              if entry_data["url"].match?(/^[a-zA-Z0-9_-]{11}$/)
                "https://www.youtube.com/watch?v=#{entry_data['url']}"
              else
                entry_data["url"]
              end
            else
              entry_data["website_url"]
            end

            e.title = entry_data["title"]
            e.description = entry_data["content"]
            e.url = url
            e.slug = entry_data["slug"]
            e.status = :approved
            e.published = true
            e.experience_level = :all_levels
            e.tags = []
            e.created_at = parse_time(lesson_yaml["created_at"])
            e.updated_at = parse_time(lesson_yaml["updated_at"])
          end

          @id_mapper.register_entry("Lesson", old_id, entry)
          success += 1
        rescue => e
          puts "  ✗ Error importing lesson #{old_id}: #{e.message}"
          errors += 1
        end

        @stats[:lessons] = { success: success, errors: errors, skipped: skipped }
        puts "✓ Imported #{success} lessons (#{errors} errors, #{skipped} skipped)"
      end

      def import_authorings
        data = load_yaml("authorings.yml")
        success = 0
        errors = 0
        skipped = 0

        data.each do |authoring_yaml|
          # Find new author by old ID
          author = @id_mapper.find_author(authoring_yaml["author_id"])
          unless author
            skipped += 1
            next
          end

          # Find new entry by old polymorphic reference
          entry = @id_mapper.find_entry(
            authoring_yaml["authorabble_type"],
            authoring_yaml["authorabble_id"]
          )
          unless entry
            skipped += 1
            next
          end

          # Use composite key for idempotency
          EntriesAuthor.find_or_create_by!(entry: entry, author: author)
          success += 1
        rescue => e
          puts "  ✗ Error importing authoring: #{e.message}"
          errors += 1
        end

        @stats[:authorings] = { success: success, errors: errors, skipped: skipped }
        puts "✓ Imported #{success} authorings (#{errors} errors, #{skipped} skipped)"
      end

      def import_taggings
        data = load_yaml("taggings.yml")
        success = 0
        errors = 0
        skipped = 0

        data.each do |tagging_yaml|
          # Find new category by old tag ID
          category = @id_mapper.find_category(tagging_yaml["tag_id"])
          unless category
            skipped += 1
            next
          end

          # Find new entry by old polymorphic reference
          entry = @id_mapper.find_entry(
            tagging_yaml["taggable_type"],
            tagging_yaml["taggable_id"]
          )
          unless entry
            skipped += 1
            next
          end

          # Determine if primary (first category for this entry)
          is_primary = CategoriesEntry.where(entry: entry).count == 0

          # Use composite key for idempotency
          CategoriesEntry.find_or_create_by!(entry: entry, category: category) do |ce|
            ce.is_primary = is_primary
            ce.is_featured = false
          end

          success += 1
        rescue => e
          puts "  ✗ Error importing tagging: #{e.message}"
          errors += 1
        end

        @stats[:taggings] = { success: success, errors: errors, skipped: skipped }
        puts "✓ Imported #{success} taggings (#{errors} errors, #{skipped} skipped)"
      end

      # Helper methods
      def load_yaml(filename)
        file_path = File.join(@yaml_dir, filename)
        YAML.load_file(file_path) || []
      end

      def parse_time(str)
        return nil if str.blank?
        Time.parse(str)
      rescue
        nil
      end

      def parse_bool(str)
        return false if str.blank?
        str.to_s == "t" || str.to_s == "true"
      end

      def set_book_fields(book, book_yaml)
        book.publication_year = book_yaml["year"].to_i if book_yaml["year"]
        book.page_count = book_yaml["page"].to_i if book_yaml["page"]
        book.purchase_url = book_yaml["amazon_url"] || book_yaml["website_url"]
        book.format = :both
        book.created_at = parse_time(book_yaml["created_at"])
        book.updated_at = parse_time(book_yaml["updated_at"])
      end

      def set_entry_fields(entry, entry_data, entity_yaml)
        entry.title = entry_data["title"]
        entry.description = entry_data["content"]

        # Try to find a URL, or generate placeholder based on slug
        url = entry_data["website_url"] || entity_yaml["website_url"] || entity_yaml["amazon_url"]
        if url.blank?
          # Generate placeholder URL based on slug
          slug = entry_data["slug"]
          url = "https://example.com/#{slug}"
        end
        entry.url = url

        entry.slug = entry_data["slug"]
        entry.status = :approved
        entry.published = true
        entry.experience_level = :intermediate
        entry.tags = []
        entry.featured_at = parse_bool(entity_yaml["featured"]) ? parse_time(entity_yaml["created_at"]) : nil
        entry.created_at = parse_time(entity_yaml["created_at"])
        entry.updated_at = parse_time(entity_yaml["updated_at"])
      end

      def print_summary
        puts
        puts "="*60
        puts "Import Summary"
        puts "="*60
        @stats.each do |type, counts|
          puts "#{type.to_s.capitalize}: #{counts[:success]} success"
          puts "  Errors: #{counts[:errors]}" if counts[:errors] > 0
          puts "  Skipped: #{counts[:skipped]}" if counts[:skipped] && counts[:skipped] > 0
        end
        puts
        puts "ID Mappings: #{@id_mapper.stats.inspect}"
      end
    end
  end
end
