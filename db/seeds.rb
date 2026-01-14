# frozen_string_literal: true

# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Create initial admin user in development
if Rails.env.development? && User.count.zero?
  puts "Creating initial admin user..."
  user = User.create!(
    email_address: "admin@chooseruby.com",
    password: "password",
    name: "Admin User",
    role: :admin
  )
  puts "Created admin: #{user.email_address} / password"
  puts ""
end

# Check if we should run the rubyandrailsinfo import
if ENV['IMPORT_RUBYANDRAILSINFO'] == 'true' && File.exist?(Rails.root.join('tmp/latest.sql'))
  puts "Starting data import from PostgreSQL dump..."
  puts ""

  # Execute rubyandrailsinfo imports in dependency order
  seed_files = %w[
    01_categories
    02_authors
    03_books
    04_courses
    05_newsletters
    06_podcasts
    07_communities
    08_videos
    09_authorings
    10_taggings
  ]

  seed_files.each do |seed_file|
    puts "\n" + "="*80
    puts "Running: seeds/rubyandrailsinfo/#{seed_file}.rb"
    puts "="*80
    load Rails.root.join('db', 'seeds', 'rubyandrailsinfo', "#{seed_file}.rb")
  end

  # Verification
  puts "\n" + "="*80
  puts "Import Complete - Verification Summary"
  puts "="*80
  puts "Categories: #{Category.count}"
  puts "Authors: #{Author.count}"
  puts "Books: #{Book.count}"
  puts "Courses: #{Course.count}"
  puts "Newsletters: #{Newsletter.count}"
  puts "Podcasts: #{Podcast.count}"
  puts "Communities: #{Community.count}"
  puts "Videos: #{Video.count}"
  puts "Entries: #{Entry.count}"
  puts "EntriesAuthors: #{EntriesAuthor.count}"
  puts "CategoriesEntries: #{CategoriesEntry.count}"

  exit 0
end

# Default seeds (existing sample data)
puts "Seeding database with sample data..."

# Create Categories
puts "Creating categories..."

categories_data = [
  { name: "Testing", description: "Testing frameworks, tools, and best practices for Ruby applications" },
  { name: "Authentication", description: "User authentication and authorization solutions" },
  { name: "Background Jobs", description: "Background job processing and task queues" },
  { name: "DevOps", description: "Deployment, infrastructure, and operations tools" },
  { name: "Web Development", description: "Web frameworks and web development tools" },
  { name: "API Development", description: "Building and consuming APIs" },
  { name: "Database", description: "Database tools, ORMs, and data persistence" },
  { name: "Security", description: "Security tools and best practices" },
  { name: "Performance", description: "Performance optimization and monitoring" },
  { name: "Learning Resources", description: "Educational materials for learning Ruby" },
  { name: "Data Processing", description: "Data manipulation, ETL, and analysis" },
  { name: "UI/Frontend", description: "Frontend tools and UI libraries" },
  { name: "Email", description: "Email sending and processing" },
  { name: "File Handling", description: "File uploads, processing, and storage" }
]

categories = categories_data.map do |cat_data|
  Category.find_or_create_by!(name: cat_data[:name]) do |category|
    category.description = cat_data[:description]
  end
end

puts "Created #{categories.count} categories"

# Helper to find categories by name
def find_categories(*names)
  Category.where(name: names)
end

# Create sample resources - Gems
puts "Creating gem resources..."

rspec_gem = RubyGem.find_or_create_by!(gem_name: "rspec") do |gem|
  gem.rubygems_url = "https://rubygems.org/gems/rspec"
  gem.github_url = "https://github.com/rspec/rspec"
  gem.documentation_url = "https://rspec.info/"
  gem.downloads_count = 500_000_000
  gem.current_version = "3.13.0"
end

Entry.find_or_create_by!(entryable: rspec_gem) do |resource|
  resource.title = "RSpec"
  resource.description = "Behaviour Driven Development for Ruby. Making TDD productive and fun."
  resource.url = "https://rspec.info/"
  resource.status = :approved
  resource.published = true
  resource.experience_level = :beginner
  resource.tags = [ "testing", "bdd", "tdd", "unit-testing" ]
  resource.categories = find_categories("Testing")
end

devise_gem = RubyGem.find_or_create_by!(gem_name: "devise") do |gem|
  gem.rubygems_url = "https://rubygems.org/gems/devise"
  gem.github_url = "https://github.com/heartcombo/devise"
  gem.documentation_url = "https://github.com/heartcombo/devise/wiki"
  gem.downloads_count = 250_000_000
  gem.current_version = "4.9.3"
end

Entry.find_or_create_by!(entryable: devise_gem) do |resource|
  resource.title = "Devise"
  resource.description = "Flexible authentication solution for Rails with Warden"
  resource.url = "https://github.com/heartcombo/devise"
  resource.status = :approved
  resource.published = true
  resource.experience_level = :intermediate
  resource.tags = [ "authentication", "security", "user-management" ]
  resource.categories = find_categories("Authentication", "Security")
end

sidekiq_gem = RubyGem.find_or_create_by!(gem_name: "sidekiq") do |gem|
  gem.rubygems_url = "https://rubygems.org/gems/sidekiq"
  gem.github_url = "https://github.com/sidekiq/sidekiq"
  gem.documentation_url = "https://github.com/sidekiq/sidekiq/wiki"
  gem.downloads_count = 180_000_000
  gem.current_version = "7.2.0"
end

Entry.find_or_create_by!(entryable: sidekiq_gem) do |resource|
  resource.title = "Sidekiq"
  resource.description = "Simple, efficient background processing for Ruby"
  resource.url = "https://sidekiq.org/"
  resource.status = :approved
  resource.published = true
  resource.experience_level = :intermediate
  resource.tags = [ "background-jobs", "async", "redis", "workers" ]
  resource.categories = find_categories("Background Jobs", "Performance")
end

puts "Created 3 gem resources"

# Create sample resources - Books
puts "Creating book resources..."

well_grounded_book = Book.find_or_create_by!(isbn: "1617295213") do |book|
  book.publisher = "Manning"
  book.publication_year = 2019
  book.page_count = 536
  book.format = :both
  book.purchase_url = "https://www.manning.com/books/the-well-grounded-rubyist-third-edition"
end

Entry.find_or_create_by!(entryable: well_grounded_book) do |resource|
  resource.title = "The Well-Grounded Rubyist, 3rd Edition"
  resource.description = "A comprehensive guide to Ruby programming from beginner to professional level"
  resource.url = "https://www.manning.com/books/the-well-grounded-rubyist-third-edition"
  resource.status = :approved
  resource.published = true
  resource.experience_level = :beginner
  resource.tags = [ "ruby", "programming", "fundamentals", "oop" ]
  resource.categories = find_categories("Learning Resources")
end

eloquent_ruby = Book.find_or_create_by!(isbn: "0321584104") do |book|
  book.publisher = "Addison-Wesley Professional"
  book.publication_year = 2011
  book.page_count = 448
  book.format = :physical
  book.purchase_url = "https://www.amazon.com/Eloquent-Ruby-Addison-Wesley-Professional/dp/0321584104"
end

Entry.find_or_create_by!(entryable: eloquent_ruby) do |resource|
  resource.title = "Eloquent Ruby"
  resource.description = "Learn to write Ruby like an expert by understanding the Ruby way of thinking and problem solving"
  resource.url = "https://www.amazon.com/Eloquent-Ruby-Addison-Wesley-Professional/dp/0321584104"
  resource.status = :approved
  resource.published = true
  resource.experience_level = :intermediate
  resource.tags = [ "ruby", "best-practices", "idiomatic", "style" ]
  resource.categories = find_categories("Learning Resources")
end

practical_ood = Book.find_or_create_by!(isbn: "0134456475") do |book|
  book.publisher = "Addison-Wesley Professional"
  book.publication_year = 2018
  book.page_count = 272
  book.format = :both
  book.purchase_url = "https://www.poodr.com/"
end

Entry.find_or_create_by!(entryable: practical_ood) do |resource|
  resource.title = "Practical Object-Oriented Design in Ruby"
  resource.description = "A guide to writing flexible, maintainable, and object-oriented Ruby code"
  resource.url = "https://www.poodr.com/"
  resource.status = :approved
  resource.published = true
  resource.experience_level = :advanced
  resource.tags = [ "oop", "design", "patterns", "architecture" ]
  resource.categories = find_categories("Learning Resources")
end

puts "Created 3 book resources"

puts "\nSeeding complete!"
puts "Total resources created: #{Entry.count}"
puts "Total categories created: #{Category.count}"

# Create sample resources - Courses (3 total, adding to reach 9)
puts "Creating course resources..."

rails_tutorial = Course.find_or_create_by!(platform: "Rails Tutorial", instructor: "Michael Hartl") do |course|
  course.duration_hours = 40.0
  course.price_cents = 2900
  course.is_free = false
  course.enrollment_url = "https://www.railstutorial.org/"
end

Entry.find_or_create_by!(entryable: rails_tutorial) do |resource|
  resource.title = "Ruby on Rails Tutorial"
  resource.description = "Learn web development with Rails"
  resource.url = "https://www.railstutorial.org/"
  resource.status = :approved
  resource.published = true
  resource.experience_level = :beginner
  resource.tags = [ "rails", "tutorial" ]
  resource.categories = find_categories("Learning Resources", "Web Development")
end

gorails = Course.find_or_create_by!(platform: "GoRails", instructor: "Chris Oliver") do |course|
  course.duration_hours = 100.0
  course.is_free = false
  course.enrollment_url = "https://gorails.com/"
end

Entry.find_or_create_by!(entryable: gorails) do |resource|
  resource.title = "GoRails Screencasts"
  resource.description = "Premium Rails screencasts"
  resource.url = "https://gorails.com/"
  resource.status = :approved
  resource.published = true
  resource.experience_level = :intermediate
  resource.tags = [ "rails", "screencasts" ]
  resource.categories = find_categories("Learning Resources")
end

free_course = Course.find_or_create_by!(platform: "Codecademy") do |course|
  course.duration_hours = 15.0
  course.is_free = true
  course.enrollment_url = "https://www.codecademy.com/learn/learn-ruby"
end

Entry.find_or_create_by!(entryable: free_course) do |resource|
  resource.title = "Learn Ruby - Codecademy"
  resource.description = "Free Ruby course"
  resource.url = "https://www.codecademy.com/learn/learn-ruby"
  resource.status = :approved
  resource.published = true
  resource.experience_level = :beginner
  resource.tags = [ "ruby", "free" ]
  resource.categories = find_categories("Learning Resources")
end

puts "Created 3 course resources"

# Create Tutorials (3)
puts "Creating tutorial resources..."

tut1 = Tutorial.find_or_create_by!(reading_time_minutes: 20, platform: "Rails Guides") do |t|
  t.publication_date = Date.new(2024, 1, 15)
end

Entry.find_or_create_by!(entryable: tut1) do |r|
  r.title = "Getting Started with Rails"
  r.description = "Official Rails getting started guide"
  r.url = "https://guides.rubyonrails.org/getting_started.html"
  r.status = :approved
  r.published = true
  r.experience_level = :beginner
  r.tags = [ "rails", "tutorial" ]
  r.categories = find_categories("Learning Resources")
end

tut2 = Tutorial.find_or_create_by!(reading_time_minutes: 30) do |t|
  t.platform = "Better Specs"
end

Entry.find_or_create_by!(entryable: tut2) do |r|
  r.title = "Better Specs"
  r.description = "RSpec best practices"
  r.url = "https://www.betterspecs.org/"
  r.status = :approved
  r.published = true
  r.experience_level = :intermediate
  r.tags = [ "testing" ]
  r.categories = find_categories("Testing")
end

tut3 = Tutorial.find_or_create_by!(reading_time_minutes: 45) do |t|
  t.platform = "Dev.to"
end

Entry.find_or_create_by!(entryable: tut3) do |r|
  r.title = "Building APIs with Rails"
  r.description = "API development tutorial"
  r.url = "https://dev.to/api-tutorial"
  r.status = :approved
  r.published = false
  r.experience_level = :intermediate
  r.tags = [ "api" ]
  r.categories = find_categories("API Development")
end

puts "Created 3 tutorial resources"

# Create Articles (3)
puts "Creating article resources..."

art1 = Article.find_or_create_by!(reading_time_minutes: 15) do |a|
  a.publication_date = Date.new(2023, 12, 25)
  a.platform = "Ruby Weekly"
end

Entry.find_or_create_by!(entryable: art1) do |r|
  r.title = "What's New in Ruby 3.3"
  r.description = "Ruby 3.3 features"
  r.url = "https://www.ruby-lang.org/en/news/2023/12/25/ruby-3-3-0-released/"
  r.status = :approved
  r.published = true
  r.experience_level = :intermediate
  r.tags = [ "ruby" ]
  r.categories = find_categories("Learning Resources")
end

art2 = Article.find_or_create_by!(reading_time_minutes: 25, platform: "Medium")

Entry.find_or_create_by!(entryable: art2) do |r|
  r.title = "Rails Performance Tips"
  r.description = "Optimization techniques"
  r.url = "https://medium.com/performance"
  r.status = :approved
  r.published = true
  r.experience_level = :advanced
  r.tags = [ "performance" ]
  r.categories = find_categories("Performance")
end

art3 = Article.find_or_create_by!(reading_time_minutes: 20, platform: "Dev.to")

Entry.find_or_create_by!(entryable: art3) do |r|
  r.title = "Rails Security Best Practices"
  r.description = "Security essentials"
  r.url = "https://dev.to/security"
  r.status = :approved
  r.published = true
  r.experience_level = :intermediate
  r.tags = [ "security" ]
  r.categories = find_categories("Security")
end

puts "Created 3 article resources"

# Create Tools (3)
puts "Creating tool resources..."

tool1 = Tool.find_or_create_by!(tool_type: "CLI", is_open_source: true) do |t|
  t.github_url = "https://github.com/rubocop/rubocop"
  t.license = "MIT"
end

Entry.find_or_create_by!(entryable: tool1) do |r|
  r.title = "RuboCop"
  r.description = "Ruby static code analyzer"
  r.url = "https://rubocop.org/"
  r.status = :approved
  r.published = true
  r.experience_level = :beginner
  r.tags = [ "linter" ]
  r.categories = find_categories("DevOps")
end

tool2 = Tool.find_or_create_by!(tool_type: "CLI", is_open_source: true) do |t|
  t.license = "MIT"
end

Entry.find_or_create_by!(entryable: tool2) do |r|
  r.title = "Bundler"
  r.description = "Ruby dependency manager"
  r.url = "https://bundler.io/"
  r.status = :approved
  r.published = true
  r.experience_level = :beginner
  r.tags = [ "dependencies" ]
  r.categories = find_categories("DevOps")
end

tool3 = Tool.find_or_create_by!(tool_type: "CLI", is_open_source: true) do |t|
  t.github_url = "https://github.com/pry/pry"
  t.license = "MIT"
end

Entry.find_or_create_by!(entryable: tool3) do |r|
  r.title = "Pry"
  r.description = "Ruby debugger"
  r.url = "https://pry.github.io/"
  r.status = :approved
  r.published = true
  r.experience_level = :intermediate
  r.tags = [ "debugging" ]
  r.categories = find_categories("DevOps")
end

puts "Created 3 tool resources"

# Create Podcasts (3)
puts "Creating podcast resources..."

pod1 = Podcast.find_or_create_by!(host: "Brittany & Brian", episode_count: 500, frequency: "Weekly")

Entry.find_or_create_by!(entryable: pod1) do |r|
  r.title = "Ruby on Rails Podcast"
  r.description = "Weekly Rails conversations"
  r.url = "https://www.therubyonrailspodcast.com/"
  r.status = :approved
  r.published = true
  r.experience_level = :beginner
  r.tags = [ "podcast" ]
  r.categories = find_categories("Learning Resources")
end

pod2 = Podcast.find_or_create_by!(host: "Charles Max Wood", episode_count: 600, frequency: "Weekly")

Entry.find_or_create_by!(entryable: pod2) do |r|
  r.title = "Ruby Rogues"
  r.description = "Ruby discussions"
  r.url = "https://topenddevs.com/podcasts/ruby-rogues"
  r.status = :approved
  r.published = true
  r.experience_level = :intermediate
  r.tags = [ "podcast" ]
  r.categories = find_categories("Learning Resources")
end

pod3 = Podcast.find_or_create_by!(host: "Chris, Jason, Andrew", episode_count: 250, frequency: "Weekly")

Entry.find_or_create_by!(entryable: pod3) do |r|
  r.title = "Remote Ruby"
  r.description = "Ruby interviews"
  r.url = "https://remoteruby.com/"
  r.status = :approved
  r.published = true
  r.experience_level = :intermediate
  r.tags = [ "podcast" ]
  r.categories = find_categories("Learning Resources")
end

puts "Created 3 podcast resources"

# Create Communities (3)
puts "Creating community resources..."

comm1 = Community.find_or_create_by!(platform: "Slack", join_url: "https://www.rubyonrails.link/", is_official: false) do |c|
  c.member_count = 10000
end

Entry.find_or_create_by!(entryable: comm1) do |r|
  r.title = "Ruby on Rails Link"
  r.description = "Rails Slack community"
  r.url = "https://www.rubyonrails.link/"
  r.status = :approved
  r.published = true
  r.experience_level = :beginner
  r.tags = [ "community" ]
  r.categories = find_categories("Learning Resources")
end

comm2 = Community.find_or_create_by!(platform: "Discord", join_url: "https://discord.gg/ruby", is_official: true) do |c|
  c.member_count = 5000
end

Entry.find_or_create_by!(entryable: comm2) do |r|
  r.title = "Ruby Discord"
  r.description = "Official Ruby Discord"
  r.url = "https://discord.gg/ruby"
  r.status = :approved
  r.published = true
  r.experience_level = :beginner
  r.tags = [ "community" ]
  r.categories = find_categories("Learning Resources")
end

comm3 = Community.find_or_create_by!(platform: "Reddit", join_url: "https://www.reddit.com/r/ruby/", is_official: false) do |c|
  c.member_count = 100000
end

Entry.find_or_create_by!(entryable: comm3) do |r|
  r.title = "r/ruby"
  r.description = "Ruby subreddit"
  r.url = "https://www.reddit.com/r/ruby/"
  r.status = :approved
  r.published = true
  r.experience_level = :beginner
  r.tags = [ "community" ]
  r.categories = find_categories("Learning Resources")
end

puts "Created 3 community resources"

puts "\nAll seeds complete!"
puts "Total resources: #{Entry.count}"
puts "Total categories: #{Category.count}"
puts "Published resources: #{Entry.published.count}"
puts "Approved resources: #{Entry.approved.count}"
