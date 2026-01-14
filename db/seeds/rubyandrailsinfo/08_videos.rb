# frozen_string_literal: true

puts "Importing videos (from youtubes, screencasts, and lessons)..."

parser = Rubyandrailsinfo::SqlParser.new(Rails.root.join('tmp/latest.sql'))

success_count = 0
error_count = 0
total_count = 0

# Helper to create video and entry
def create_video_and_entry(video_data, type_name)
  return nil if video_data['title'].blank?

  # Step 1: Create Video record
  video = Video.create! do |v|
    v.name = video_data['title']
    v.created_at = Rubyandrailsinfo::Helpers.parse_time(video_data['created_at'])
    v.updated_at = Rubyandrailsinfo::Helpers.parse_time(video_data['updated_at'])
  end

  # Step 2: Create Entry record
  url = video_data['website_url'] || video_data['url']
  # For lessons with youtube_id, construct YouTube URL
  if video_data['youtube_id'].present? && url.blank?
    url = "https://www.youtube.com/watch?v=#{video_data['youtube_id']}"
  end

  entry = Entry.find_or_create_by!(entryable: video) do |e|
    e.title = video_data['title']
    e.description = video_data['content'] || video_data['description']
    e.url = url
    e.slug = video_data['slug']
    e.status = :approved
    e.published = true
    e.experience_level = :all_levels
    e.tags = []
    e.created_at = Rubyandrailsinfo::Helpers.parse_time(video_data['created_at'])
    e.updated_at = Rubyandrailsinfo::Helpers.parse_time(video_data['updated_at'])
  end

  # Step 3: Register for join table lookup
  Rubyandrailsinfo::Helpers.register_entry(type_name, video_data['id'], entry)

  { video: video, entry: entry }
end

# Import youtubes
youtubes_data = parser.extract_table('youtubes')
total_count += youtubes_data.count
youtubes_data.each_with_index do |youtube_data, index|
  begin
    create_video_and_entry(youtube_data, 'Youtube')
    success_count += 1
    Rubyandrailsinfo::Helpers.progress(index + 1, youtubes_data.count, "Youtubes")
  rescue StandardError => e
    puts "\n  ✗ ERROR importing youtube: #{e.message}"
    puts "    Data: #{youtube_data.inspect}"
    error_count += 1
  end
end

# Import screencasts
screencasts_data = parser.extract_table('screencasts')
total_count += screencasts_data.count
screencasts_data.each_with_index do |screencast_data, index|
  begin
    create_video_and_entry(screencast_data, 'Screencast')
    success_count += 1
    Rubyandrailsinfo::Helpers.progress(index + 1, screencasts_data.count, "Screencasts")
  rescue StandardError => e
    puts "\n  ✗ ERROR importing screencast: #{e.message}"
    puts "    Data: #{screencast_data.inspect}"
    error_count += 1
  end
end

# Import lessons
lessons_data = parser.extract_table('lessons')
total_count += lessons_data.count
lessons_data.each_with_index do |lesson_data, index|
  begin
    create_video_and_entry(lesson_data, 'Lesson')
    success_count += 1
    Rubyandrailsinfo::Helpers.progress(index + 1, lessons_data.count, "Lessons")
  rescue StandardError => e
    puts "\n  ✗ ERROR importing lesson: #{e.message}"
    puts "    Data: #{lesson_data.inspect}"
    error_count += 1
  end
end

puts "\n  ✓ Successfully imported: #{success_count} videos (from #{total_count} total records)"
puts "  ✗ Errors: #{error_count}" if error_count > 0
