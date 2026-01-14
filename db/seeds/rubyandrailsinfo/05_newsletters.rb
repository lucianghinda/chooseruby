# frozen_string_literal: true

puts "Importing newsletters..."

parser = Rubyandrailsinfo::SqlParser.new(Rails.root.join('tmp/latest.sql'))
newsletters_data = parser.extract_table('newsletters')

success_count = 0
error_count = 0

newsletters_data.each_with_index do |newsletter_data, index|
  begin
    # Skip if no title
    if newsletter_data['title'].blank?
      puts "  ⚠ Skipping newsletter with no title (old ID: #{newsletter_data['id']})"
      error_count += 1
      next
    end

    # Step 1: Create Newsletter record
    newsletter = Newsletter.create! do |n|
      n.name = newsletter_data['title']
      n.created_at = Rubyandrailsinfo::Helpers.parse_time(newsletter_data['created_at'])
      n.updated_at = Rubyandrailsinfo::Helpers.parse_time(newsletter_data['updated_at'])
    end

    # Step 2: Create Entry record
    entry = Entry.find_or_create_by!(entryable: newsletter) do |e|
      e.title = newsletter_data['title']
      e.description = newsletter_data['content']
      e.url = newsletter_data['website_url']
      e.slug = newsletter_data['slug']
      e.status = :approved
      e.published = true
      e.experience_level = :all_levels
      e.tags = []
      e.featured_at = Rubyandrailsinfo::Helpers.parse_bool(newsletter_data['featured']) ?
                      Rubyandrailsinfo::Helpers.parse_time(newsletter_data['created_at']) : nil
      e.created_at = Rubyandrailsinfo::Helpers.parse_time(newsletter_data['created_at'])
      e.updated_at = Rubyandrailsinfo::Helpers.parse_time(newsletter_data['updated_at'])
    end

    # Step 3: Register for join table lookup
    Rubyandrailsinfo::Helpers.register_entry('Newsletter', newsletter_data['id'], entry)

    success_count += 1
    Rubyandrailsinfo::Helpers.progress(index + 1, newsletters_data.count, "Newsletters")
  rescue StandardError => e
    puts "\n  ✗ ERROR importing newsletter: #{e.message}"
    puts "    Data: #{newsletter_data.inspect}"
    error_count += 1
  end
end

puts "\n  ✓ Successfully imported: #{success_count} newsletters"
puts "  ✗ Errors: #{error_count}" if error_count > 0
