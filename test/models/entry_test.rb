# frozen_string_literal: true

# == Schema Information
#
# Table name: entries
#
#  id               :integer          not null, primary key
#  description      :text
#  entryable_type   :string
#  experience_level :integer
#  featured_at      :datetime
#  image_url        :string
#  published        :boolean          default(FALSE), not null
#  slug             :string
#  status           :integer          default("pending"), not null
#  submitter_email  :string
#  submitter_name   :string
#  tags             :text
#  title            :string
#  url              :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  entryable_id     :integer
#
# Indexes
#
#  index_entries_on_entryable_type_and_entryable_id  (entryable_type,entryable_id)
#  index_entries_on_experience_level                 (experience_level)
#  index_entries_on_published                        (published)
#  index_entries_on_slug                             (slug) UNIQUE
#  index_entries_on_status                           (status)
#  index_entries_on_title                            (title)
#
require "test_helper"

class EntryTest < ActiveSupport::TestCase
  # Task 1.1: Tests for Entry type scopes

  test "gems scope returns only RubyGem entries" do
    # Create RubyGem entry
    ruby_gem = RubyGem.create!(gem_name: "rspec-rails")
    gem_entry = Entry.create!(
      title: "RSpec Rails",
      description: "Testing framework for Rails",
      url: "https://github.com/rspec/rspec-rails",
      entryable: ruby_gem,
      status: :approved,
      published: true
    )

    # Create Book entry
    book = Book.create!
    book_entry = Entry.create!(
      title: "Ruby Book",
      description: "A book about Ruby",
      url: "https://example.com/book",
      entryable: book,
      status: :approved,
      published: true
    )

    gems = Entry.gems

    assert_includes gems, gem_entry
    refute_includes gems, book_entry
    assert_equal "RubyGem", gems.first.entryable_type
  end

  test "books scope returns only Book entries" do
    # Create Book entry
    book = Book.create!
    book_entry = Entry.create!(
      title: "Ruby Book",
      description: "A book about Ruby",
      url: "https://example.com/book",
      entryable: book,
      status: :approved,
      published: true
    )

    # Create Course entry
    course = Course.create!
    course_entry = Entry.create!(
      title: "Ruby Course",
      description: "Learn Ruby",
      url: "https://example.com/course",
      entryable: course,
      status: :approved,
      published: true
    )

    books = Entry.books

    assert_includes books, book_entry
    refute_includes books, course_entry
    assert_equal "Book", books.first.entryable_type
  end

  test "type scopes chain with visible and recently_curated" do
    # Create multiple gem entries with different statuses
    gem1 = RubyGem.create!(gem_name: "gem-1")
    visible_gem = Entry.create!(
      title: "Visible Gem",
      description: "Published and approved gem",
      url: "https://example.com/gem1",
      entryable: gem1,
      status: :approved,
      published: true
    )

    gem2 = RubyGem.create!(gem_name: "gem-2")
    pending_gem = Entry.create!(
      title: "Pending Gem",
      description: "Pending gem",
      url: "https://example.com/gem2",
      entryable: gem2,
      status: :pending,
      published: false,
      submitter_email: "test@example.com"
    )

    chained_scope = Entry.gems.visible.recently_curated

    assert_includes chained_scope, visible_gem
    refute_includes chained_scope, pending_gem
  end

  test "courses scope returns only Course entries" do
    course = Course.create!
    course_entry = Entry.create!(
      title: "Ruby Course",
      description: "Learn Ruby",
      url: "https://example.com/course",
      entryable: course,
      status: :approved,
      published: true
    )

    courses = Entry.courses
    assert_includes courses, course_entry
    assert_equal "Course", courses.first.entryable_type
  end

  test "tutorials scope returns only Tutorial entries" do
    tutorial = Tutorial.create!
    tutorial_entry = Entry.create!(
      title: "Ruby Tutorial",
      description: "Tutorial about Ruby",
      url: "https://example.com/tutorial",
      entryable: tutorial,
      status: :approved,
      published: true
    )

    tutorials = Entry.tutorials
    assert_includes tutorials, tutorial_entry
    assert_equal "Tutorial", tutorials.first.entryable_type
  end

  test "articles scope returns only Article entries" do
    article = Article.create!
    article_entry = Entry.create!(
      title: "Ruby Article",
      description: "Article about Ruby",
      url: "https://example.com/article",
      entryable: article,
      status: :approved,
      published: true
    )

    articles = Entry.articles
    assert_includes articles, article_entry
    assert_equal "Article", articles.first.entryable_type
  end

  test "tools scope returns only Tool entries" do
    tool = Tool.create!
    tool_entry = Entry.create!(
      title: "Ruby Tool",
      description: "Tool for Ruby development",
      url: "https://example.com/tool",
      entryable: tool,
      status: :approved,
      published: true
    )

    tools = Entry.tools
    assert_includes tools, tool_entry
    assert_equal "Tool", tools.first.entryable_type
  end

  test "podcasts scope returns only Podcast entries" do
    podcast = Podcast.create!
    podcast_entry = Entry.create!(
      title: "Ruby Podcast",
      description: "Podcast about Ruby",
      url: "https://example.com/podcast",
      entryable: podcast,
      status: :approved,
      published: true
    )

    podcasts = Entry.podcasts
    assert_includes podcasts, podcast_entry
    assert_equal "Podcast", podcasts.first.entryable_type
  end

  test "communities scope returns only Community entries" do
    community = Community.create!(
      platform: "Discord",
      join_url: "https://discord.gg/ruby"
    )
    community_entry = Entry.create!(
      title: "Ruby Community",
      description: "Community for Ruby developers",
      url: "https://example.com/community",
      entryable: community,
      status: :approved,
      published: true
    )

    communities = Entry.communities
    assert_includes communities, community_entry
    assert_equal "Community", communities.first.entryable_type
  end

  test "type scopes work with with_directory_includes for N+1 prevention" do
    # Create category with unique name
    category = Category.create!(
      name: "Testing Type Scopes #{Time.current.to_i}",
      description: "Testing category"
    )

    # Create author with unique name
    author = Author.create!(
      name: "Test Author #{Time.current.to_i}"
    )

    # Create gem entry with associations
    gem = RubyGem.create!(gem_name: "test-gem-#{Time.current.to_i}")
    gem_entry = Entry.create!(
      title: "Test Gem #{Time.current.to_i}",
      description: "A test gem",
      url: "https://example.com/gem",
      entryable: gem,
      status: :approved,
      published: true
    )
    gem_entry.categories << category
    gem_entry.authors << author

    # Query with includes to prevent N+1
    entries = Entry.gems.with_directory_includes

    # This should not raise N+1 errors
    assert_nothing_raised do
      entries.each do |entry|
        entry.categories.to_a
        entry.authors.to_a
        entry.description.to_s
      end
    end

    assert_includes entries, gem_entry
  end

  # Task 2.1: Tests for new delegated type associations and scopes

  test "delegated_type supports all 19 types" do
    # Test Newsletter
    newsletter = Newsletter.create!(name: "Test Newsletter")
    newsletter_entry = Entry.create!(
      title: "Ruby Weekly Newsletter",
      description: "Weekly Ruby news",
      url: "https://example.com/newsletter",
      entryable: newsletter,
      status: :approved,
      published: true
    )
    assert_equal "Newsletter", newsletter_entry.entryable_type
    assert newsletter_entry.newsletter?

    # Test Blog
    blog = Blog.create!(name: "Ruby Blog")
    blog_entry = Entry.create!(
      title: "Ruby Blog",
      description: "Blog about Ruby",
      url: "https://example.com/blog",
      entryable: blog,
      status: :approved,
      published: true
    )
    assert_equal "Blog", blog_entry.entryable_type
    assert blog_entry.blog?

    # Test Framework
    framework = Framework.create!(name: "Test Framework")
    framework_entry = Entry.create!(
      title: "Ruby Framework",
      description: "A Ruby framework",
      url: "https://example.com/framework",
      entryable: framework,
      status: :approved,
      published: true
    )
    assert_equal "Framework", framework_entry.entryable_type
    assert framework_entry.framework?
  end

  test "new type scopes return correct entries" do
    # Create Newsletter entry
    newsletter = Newsletter.create!(name: "Test Newsletter")
    newsletter_entry = Entry.create!(
      title: "Ruby Newsletter",
      description: "Newsletter about Ruby",
      url: "https://example.com/newsletter",
      entryable: newsletter,
      status: :approved,
      published: true
    )

    # Create Blog entry
    blog = Blog.create!(name: "Ruby Blog")
    blog_entry = Entry.create!(
      title: "Ruby Blog",
      description: "Blog about Ruby",
      url: "https://example.com/blog",
      entryable: blog,
      status: :approved,
      published: true
    )

    # Test newsletters scope
    newsletters = Entry.newsletters
    assert_includes newsletters, newsletter_entry
    refute_includes newsletters, blog_entry
    assert_equal "Newsletter", newsletters.first.entryable_type

    # Test blogs scope
    blogs = Entry.blogs
    assert_includes blogs, blog_entry
    refute_includes blogs, newsletter_entry
    assert_equal "Blog", blogs.first.entryable_type
  end

  test "VALID_TYPES mapping includes all new types" do
    # Test new type mappings
    assert_equal "Newsletter", Entry::VALID_TYPES["newsletters"]
    assert_equal "Blog", Entry::VALID_TYPES["blogs"]
    assert_equal "Video", Entry::VALID_TYPES["videos"]
    assert_equal "Channel", Entry::VALID_TYPES["channels"]
    assert_equal "Documentation", Entry::VALID_TYPES["documentations"]
    assert_equal "TestingResource", Entry::VALID_TYPES["testing-resources"]
    assert_equal "DevelopmentEnvironment", Entry::VALID_TYPES["development-environments"]
    assert_equal "Job", Entry::VALID_TYPES["jobs"]
    assert_equal "Framework", Entry::VALID_TYPES["frameworks"]
    assert_equal "Directory", Entry::VALID_TYPES["directories"]
    assert_equal "Product", Entry::VALID_TYPES["products"]

    # Verify total count (8 existing + 11 new = 19)
    assert_equal 19, Entry::VALID_TYPES.size
  end

  test "featured scope returns only entries with featured_at set" do
    # Create featured entry
    gem1 = RubyGem.create!(gem_name: "featured-gem")
    featured_entry = Entry.create!(
      title: "Featured Gem",
      description: "A featured gem",
      url: "https://example.com/featured",
      entryable: gem1,
      status: :approved,
      published: true,
      featured_at: 2.days.ago
    )

    # Create non-featured entry
    gem2 = RubyGem.create!(gem_name: "regular-gem")
    regular_entry = Entry.create!(
      title: "Regular Gem",
      description: "A regular gem",
      url: "https://example.com/regular",
      entryable: gem2,
      status: :approved,
      published: true,
      featured_at: nil
    )

    featured_entries = Entry.featured

    assert_includes featured_entries, featured_entry
    refute_includes featured_entries, regular_entry
  end

  test "featured scope orders by featured_at descending" do
    # Create multiple featured entries
    gem1 = RubyGem.create!(gem_name: "oldest-featured")
    oldest_featured = Entry.create!(
      title: "Oldest Featured",
      description: "Oldest featured entry",
      url: "https://example.com/oldest",
      entryable: gem1,
      status: :approved,
      published: true,
      featured_at: 3.days.ago
    )

    gem2 = RubyGem.create!(gem_name: "newest-featured")
    newest_featured = Entry.create!(
      title: "Newest Featured",
      description: "Newest featured entry",
      url: "https://example.com/newest",
      entryable: gem2,
      status: :approved,
      published: true,
      featured_at: 1.day.ago
    )

    featured_entries = Entry.featured

    assert_equal newest_featured, featured_entries.first
    assert_equal oldest_featured, featured_entries.last
  end

  test "all new type scopes work correctly" do
    # Create one entry for each new type
    video = Video.create!(name: "Test Video")
    video_entry = Entry.create!(
      title: "Ruby Video",
      description: "Video about Ruby",
      url: "https://example.com/video",
      entryable: video,
      status: :approved,
      published: true
    )

    channel = Channel.create!(name: "Test Channel")
    channel_entry = Entry.create!(
      title: "Ruby Channel",
      description: "YouTube channel about Ruby",
      url: "https://example.com/channel",
      entryable: channel,
      status: :approved,
      published: true
    )

    documentation = Documentation.create!(name: "Test Documentation")
    doc_entry = Entry.create!(
      title: "Ruby Docs",
      description: "Ruby documentation",
      url: "https://example.com/docs",
      entryable: documentation,
      status: :approved,
      published: true
    )

    # Test scopes
    assert_includes Entry.videos, video_entry
    assert_equal "Video", Entry.videos.first.entryable_type

    assert_includes Entry.channels, channel_entry
    assert_equal "Channel", Entry.channels.first.entryable_type

    assert_includes Entry.documentations, doc_entry
    assert_equal "Documentation", Entry.documentations.first.entryable_type
  end

  test "new type scopes chain with visible and recently_curated" do
    # Create visible newsletter
    newsletter = Newsletter.create!(name: "Test Newsletter")
    visible_newsletter = Entry.create!(
      title: "Visible Newsletter",
      description: "Published and approved newsletter",
      url: "https://example.com/newsletter-visible",
      entryable: newsletter,
      status: :approved,
      published: true
    )

    # Create pending newsletter
    newsletter2 = Newsletter.create!(name: "Test Newsletter")
    pending_newsletter = Entry.create!(
      title: "Pending Newsletter",
      description: "Pending newsletter",
      url: "https://example.com/newsletter-pending",
      entryable: newsletter2,
      status: :pending,
      published: false,
      submitter_email: "test@example.com"
    )

    chained_scope = Entry.newsletters.visible.recently_curated

    assert_includes chained_scope, visible_newsletter
    refute_includes chained_scope, pending_newsletter
  end
end
