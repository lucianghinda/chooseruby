# frozen_string_literal: true

puts "Importing taggings (category-entry associations)..."

parser = Rubyandrailsinfo::SqlParser.new(Rails.root.join('tmp/latest.sql'))
taggings_data = parser.extract_table('taggings')

success_count = 0
error_count = 0
skipped_count = 0

taggings_data.each_with_index do |tagging, index|
  begin
    # Find category (was tag) by old tag ID
    category = Rubyandrailsinfo::Helpers.find_category(tagging['tag_id'])
    if category.nil?
      skipped_count += 1
      next
    end

    # Find entry by old polymorphic reference
    entry = Rubyandrailsinfo::Helpers.find_entry(
      tagging['taggable_type'],
      tagging['taggable_id']
    )
    if entry.nil?
      skipped_count += 1
      next
    end

    # Determine if primary (first category for this entry)
    is_primary = CategoriesEntry.where(entry: entry).count == 0

    # Create association
    CategoriesEntry.find_or_create_by!(category: category, entry: entry) do |ce|
      ce.is_primary = is_primary
      ce.is_featured = false # Default
    end

    success_count += 1
    Rubyandrailsinfo::Helpers.progress(index + 1, taggings_data.count, "Taggings")
  rescue StandardError => e
    puts "\n  ✗ ERROR: #{e.message}"
    puts "    Data: #{tagging.inspect}"
    error_count += 1
  end
end

puts "\n  ✓ Successfully imported: #{success_count} taggings"
puts "  ⚠ Skipped (missing references): #{skipped_count}" if skipped_count > 0
puts "  ✗ Errors: #{error_count}" if error_count > 0
