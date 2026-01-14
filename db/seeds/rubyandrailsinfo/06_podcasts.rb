# frozen_string_literal: true

puts "Importing podcasts..."

parser = Rubyandrailsinfo::SqlParser.new(Rails.root.join('tmp/latest.sql'))
podcasts_data = parser.extract_table('podcasts')

success_count = 0
error_count = 0

podcasts_data.each_with_index do |podcast_data, index|
  begin
    # Skip if no title
    if podcast_data['title'].blank?
      puts "  ⚠ Skipping podcast with no title (old ID: #{podcast_data['id']})"
      error_count += 1
      next
    end

    # Step 1: Create Podcast record
    podcast = Podcast.create! do |p|
      p.created_at = Rubyandrailsinfo::Helpers.parse_time(podcast_data['created_at'])
      p.updated_at = Rubyandrailsinfo::Helpers.parse_time(podcast_data['updated_at'])
    end

    # Step 2: Create Entry record
    entry = Entry.find_or_create_by!(entryable: podcast) do |e|
      e.title = podcast_data['title']
      e.description = podcast_data['content']
      e.url = podcast_data['website_url']
      e.slug = podcast_data['slug']
      e.status = :approved
      e.published = true
      e.experience_level = :all_levels
      e.tags = []
      e.featured_at = Rubyandrailsinfo::Helpers.parse_bool(podcast_data['featured']) ?
                      Rubyandrailsinfo::Helpers.parse_time(podcast_data['created_at']) : nil
      e.created_at = Rubyandrailsinfo::Helpers.parse_time(podcast_data['created_at'])
      e.updated_at = Rubyandrailsinfo::Helpers.parse_time(podcast_data['updated_at'])
    end

    # Step 3: Register for join table lookup
    Rubyandrailsinfo::Helpers.register_entry('Podcast', podcast_data['id'], entry)

    success_count += 1
    Rubyandrailsinfo::Helpers.progress(index + 1, podcasts_data.count, "Podcasts")
  rescue StandardError => e
    puts "\n  ✗ ERROR importing podcast: #{e.message}"
    puts "    Data: #{podcast_data.inspect}"
    error_count += 1
  end
end

puts "\n  ✓ Successfully imported: #{success_count} podcasts"
puts "  ✗ Errors: #{error_count}" if error_count > 0
