# frozen_string_literal: true

puts "Importing books..."

parser = Rubyandrailsinfo::SqlParser.new(Rails.root.join('tmp/latest.sql'))
books_data = parser.extract_table('books')

success_count = 0
error_count = 0

books_data.each_with_index do |book_data, index|
  begin
    # Skip if no title
    if book_data['title'].blank?
      puts "  ⚠ Skipping book with no title (old ID: #{book_data['id']})"
      error_count += 1
      next
    end

    # Step 1: Create Book record
    # Use ISBN as unique key, fallback to slug-based temp ISBN if missing
    unique_key = book_data['isbn'].presence || "TEMP-#{book_data['slug']}"

    book = Book.find_or_create_by!(isbn: unique_key) do |b|
      b.publication_year = Rubyandrailsinfo::Helpers.to_int(book_data['year'])
      b.page_count = Rubyandrailsinfo::Helpers.to_int(book_data['page'])
      b.purchase_url = book_data['amazon_url'] || book_data['website_url']
      b.format = :both # Default, source data doesn't specify
      b.created_at = Rubyandrailsinfo::Helpers.parse_time(book_data['created_at'])
      b.updated_at = Rubyandrailsinfo::Helpers.parse_time(book_data['updated_at'])
    end

    # Step 2: Create Entry record
    entry = Entry.find_or_create_by!(entryable: book) do |e|
      e.title = book_data['title']
      e.description = book_data['content'] # ActionText handles HTML
      e.url = book_data['website_url'] || book_data['amazon_url']
      e.slug = book_data['slug']
      e.status = :approved
      e.published = true
      e.experience_level = :intermediate # Default
      e.tags = [] # Will be populated by taggings import
      e.featured_at = Rubyandrailsinfo::Helpers.parse_bool(book_data['featured']) ?
                      Rubyandrailsinfo::Helpers.parse_time(book_data['created_at']) : nil
      e.created_at = Rubyandrailsinfo::Helpers.parse_time(book_data['created_at'])
      e.updated_at = Rubyandrailsinfo::Helpers.parse_time(book_data['updated_at'])
    end

    # Step 3: Register for join table lookup
    Rubyandrailsinfo::Helpers.register_entry('Book', book_data['id'], entry)

    success_count += 1
    Rubyandrailsinfo::Helpers.progress(index + 1, books_data.count, "Books")
  rescue StandardError => e
    puts "\n  ✗ ERROR importing book: #{e.message}"
    puts "    Data: #{book_data.inspect}"
    error_count += 1
  end
end

puts "\n  ✓ Successfully imported: #{success_count} books"
puts "  ✗ Errors: #{error_count}" if error_count > 0
