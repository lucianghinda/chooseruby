# frozen_string_literal: true

puts "Importing authorings (author-entry associations)..."

parser = Rubyandrailsinfo::SqlParser.new(Rails.root.join('tmp/latest.sql'))
authorings_data = parser.extract_table('authorings')

success_count = 0
error_count = 0
skipped_count = 0

authorings_data.each_with_index do |authoring, index|
  begin
    # Find author by old ID
    author = Rubyandrailsinfo::Helpers.find_author(authoring['author_id'])
    if author.nil?
      skipped_count += 1
      next
    end

    # Find entry by old polymorphic reference
    # Note: SQL has "authorabble_type" with double 'b'
    entry = Rubyandrailsinfo::Helpers.find_entry(
      authoring['authorabble_type'], # "Book", "Course", etc.
      authoring['authorabble_id']    # old ID
    )
    if entry.nil?
      skipped_count += 1
      next
    end

    # Create association
    EntriesAuthor.find_or_create_by!(author: author, entry: entry)

    success_count += 1
    Rubyandrailsinfo::Helpers.progress(index + 1, authorings_data.count, "Authorings")
  rescue StandardError => e
    puts "\n  ✗ ERROR: #{e.message}"
    puts "    Data: #{authoring.inspect}"
    error_count += 1
  end
end

puts "\n  ✓ Successfully imported: #{success_count} authorings"
puts "  ⚠ Skipped (missing references): #{skipped_count}" if skipped_count > 0
puts "  ✗ Errors: #{error_count}" if error_count > 0
