# frozen_string_literal: true

puts "Importing categories (from tags table)..."

parser = Rubyandrailsinfo::SqlParser.new(Rails.root.join('tmp/latest.sql'))
tags_data = parser.extract_table('tags')

success_count = 0
error_count = 0

tags_data.each_with_index do |tag_data, index|
  begin
    # Skip if no title
    if tag_data['title'].blank?
      puts "  ⚠ Skipping tag with no title (old ID: #{tag_data['id']})"
      error_count += 1
      next
    end

    # Create Category from tag
    category = Category.find_or_create_by!(slug: tag_data['slug']) do |c|
      c.name = tag_data['title']
      c.description = nil # Not in source data
      c.created_at = Rubyandrailsinfo::Helpers.parse_time(tag_data['created_at'])
      c.updated_at = Rubyandrailsinfo::Helpers.parse_time(tag_data['updated_at'])
    end

    # Register for taggings import
    Rubyandrailsinfo::Helpers.register_category(tag_data['id'], category)

    success_count += 1
    Rubyandrailsinfo::Helpers.progress(index + 1, tags_data.count, "Categories")
  rescue StandardError => e
    puts "\n  ✗ ERROR importing tag: #{e.message}"
    puts "    Data: #{tag_data.inspect}"
    error_count += 1
  end
end

puts "\n  ✓ Successfully imported: #{success_count} categories"
puts "  ✗ Errors: #{error_count}" if error_count > 0
