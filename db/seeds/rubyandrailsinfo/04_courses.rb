# frozen_string_literal: true

puts "Importing courses..."

parser = Rubyandrailsinfo::SqlParser.new(Rails.root.join('tmp/latest.sql'))
courses_data = parser.extract_table('courses')

success_count = 0
error_count = 0

courses_data.each_with_index do |course_data, index|
  begin
    # Skip if no title
    if course_data['title'].blank?
      puts "  ⚠ Skipping course with no title (old ID: #{course_data['id']})"
      error_count += 1
      next
    end

    # Step 1: Create Course record
    # Use slug-based temp ID for uniqueness (Course model has no unique fields)
    course = Course.create! do |c|
      c.is_free = Rubyandrailsinfo::Helpers.parse_bool(course_data['free'])
      c.created_at = Rubyandrailsinfo::Helpers.parse_time(course_data['created_at'])
      c.updated_at = Rubyandrailsinfo::Helpers.parse_time(course_data['updated_at'])
    end

    # Step 2: Create Entry record
    entry = Entry.find_or_create_by!(entryable: course) do |e|
      e.title = course_data['title']
      e.description = course_data['content']
      e.url = course_data['website_url']
      e.slug = course_data['slug']
      e.status = :approved
      e.published = true
      e.experience_level = :intermediate
      e.tags = []
      e.featured_at = Rubyandrailsinfo::Helpers.parse_bool(course_data['featured']) ?
                      Rubyandrailsinfo::Helpers.parse_time(course_data['created_at']) : nil
      e.created_at = Rubyandrailsinfo::Helpers.parse_time(course_data['created_at'])
      e.updated_at = Rubyandrailsinfo::Helpers.parse_time(course_data['updated_at'])
    end

    # Step 3: Register for join table lookup
    Rubyandrailsinfo::Helpers.register_entry('Course', course_data['id'], entry)

    success_count += 1
    Rubyandrailsinfo::Helpers.progress(index + 1, courses_data.count, "Courses")
  rescue StandardError => e
    puts "\n  ✗ ERROR importing course: #{e.message}"
    puts "    Data: #{course_data.inspect}"
    error_count += 1
  end
end

puts "\n  ✓ Successfully imported: #{success_count} courses"
puts "  ✗ Errors: #{error_count}" if error_count > 0
