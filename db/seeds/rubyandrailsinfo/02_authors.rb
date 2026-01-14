# frozen_string_literal: true

puts "Importing authors..."

parser = Rubyandrailsinfo::SqlParser.new(Rails.root.join('tmp/latest.sql'))
authors_data = parser.extract_table('authors')

success_count = 0
error_count = 0

authors_data.each_with_index do |author_data, index|
  begin
    # Skip if no name
    if author_data['name'].blank?
      puts "  ⚠ Skipping author with no name (old ID: #{author_data['id']})"
      error_count += 1
      next
    end

    # Create Author
    author = Author.find_or_create_by!(slug: author_data['slug']) do |a|
      a.name = author_data['name']
      a.twitter_url = author_data['twitter_url']
      a.github_url = author_data['github_url']
      a.website_url = author_data['website_url']
      a.status = :approved # All imported authors are approved
      a.created_at = Rubyandrailsinfo::Helpers.parse_time(author_data['created_at'])
      a.updated_at = Rubyandrailsinfo::Helpers.parse_time(author_data['updated_at'])
    end

    # Register for authorings import
    Rubyandrailsinfo::Helpers.register_author(author_data['id'], author)

    success_count += 1
    Rubyandrailsinfo::Helpers.progress(index + 1, authors_data.count, "Authors")
  rescue StandardError => e
    puts "\n  ✗ ERROR importing author: #{e.message}"
    puts "    Data: #{author_data.inspect}"
    error_count += 1
  end
end

puts "\n  ✓ Successfully imported: #{success_count} authors"
puts "  ✗ Errors: #{error_count}" if error_count > 0
