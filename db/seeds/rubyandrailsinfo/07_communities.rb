# frozen_string_literal: true

puts "Importing communities..."

parser = Rubyandrailsinfo::SqlParser.new(Rails.root.join('tmp/latest.sql'))
communities_data = parser.extract_table('communities')

success_count = 0
error_count = 0

# Platform type mapping (if needed)
PLATFORM_MAP = {
  '1' => 'Forum',
  '2' => 'Reddit',
  '3' => 'Discord',
  '4' => 'Slack',
  '5' => 'Twitter'
}.freeze

communities_data.each_with_index do |community_data, index|
  begin
    # Skip if no title
    if community_data['title'].blank?
      puts "  ⚠ Skipping community with no title (old ID: #{community_data['id']})"
      error_count += 1
      next
    end

    # Skip if no website URL
    if community_data['website_url'].blank?
      puts "  ⚠ Skipping community with no URL (old ID: #{community_data['id']})"
      error_count += 1
      next
    end

    # Step 1: Create Community record
    community = Community.create! do |c|
      # Map platform_type (might be numeric in SQL) to platform name
      c.platform = PLATFORM_MAP[community_data['platform_type'].to_s] || 'Other'
      c.join_url = community_data['website_url']
      c.member_count = Rubyandrailsinfo::Helpers.to_int(community_data['members'])
      c.is_official = false # Default, not in source data
      c.created_at = Rubyandrailsinfo::Helpers.parse_time(community_data['created_at'])
      c.updated_at = Rubyandrailsinfo::Helpers.parse_time(community_data['updated_at'])
    end

    # Step 2: Create Entry record
    entry = Entry.find_or_create_by!(entryable: community) do |e|
      e.title = community_data['title']
      e.description = community_data['content']
      e.url = community_data['website_url']
      e.slug = community_data['slug']
      e.status = :approved
      e.published = true
      e.experience_level = :all_levels
      e.tags = []
      e.featured_at = Rubyandrailsinfo::Helpers.parse_bool(community_data['featured']) ?
                      Rubyandrailsinfo::Helpers.parse_time(community_data['created_at']) : nil
      e.created_at = Rubyandrailsinfo::Helpers.parse_time(community_data['created_at'])
      e.updated_at = Rubyandrailsinfo::Helpers.parse_time(community_data['updated_at'])
    end

    # Step 3: Register for join table lookup
    Rubyandrailsinfo::Helpers.register_entry('Community', community_data['id'], entry)

    success_count += 1
    Rubyandrailsinfo::Helpers.progress(index + 1, communities_data.count, "Communities")
  rescue StandardError => e
    puts "\n  ✗ ERROR importing community: #{e.message}"
    puts "    Data: #{community_data.inspect}"
    error_count += 1
  end
end

puts "\n  ✓ Successfully imported: #{success_count} communities"
puts "  ✗ Errors: #{error_count}" if error_count > 0
