# frozen_string_literal: true

require "test_helper"

class AvoEntryAdminTest < ActionDispatch::IntegrationTest
  test "can create a ruby gem entry via Avo" do
    # Create the delegated type first
    ruby_gem = RubyGem.create!(gem_name: "test-gem", rubygems_url: "https://rubygems.org/gems/test-gem")

    # Create the entry
    entry = Entry.create!(
      title: "Test Gem",
      description: "A test gem for testing",
      url: "https://example.com",
      entryable: ruby_gem,
      status: :pending,
      published: false,
      submitter_email: "pending@example.com"
    )

    assert entry.persisted?
    assert_equal "RubyGem", entry.entryable_type
    assert entry.ruby_gem?
    assert_equal "test-gem", entry.entryable.gem_name
  end

  test "can create a book entry via Avo" do
    book = Book.create!(
      isbn: "9780134687960", # Valid 13-digit ISBN without hyphens
      publisher: "Test Publisher",
      publication_year: 2020,
      format: :both
    )

    entry = Entry.create!(
      title: "Test Book",
      description: "A test book for testing",
      url: "https://example.com",
      entryable: book,
      status: :approved
    )

    assert entry.persisted?
    assert entry.book?
    assert_equal "Test Publisher", entry.entryable.publisher
  end

  test "can assign multiple categories to an entry" do
    category1 = categories(:testing)
    category2 = categories(:web_development)

    ruby_gem = RubyGem.create!(gem_name: "test-gem")
    entry = Entry.create!(
      title: "Test Entry",
      description: "Test description",
      url: "https://example.com",
      entryable: ruby_gem,
      status: :approved
    )

    entry.categories << category1
    entry.categories << category2

    assert_equal 2, entry.categories.count
    assert_includes entry.categories, category1
    assert_includes entry.categories, category2
  end

  test "can update entry status" do
    ruby_gem = RubyGem.create!(gem_name: "test-gem")
    entry = Entry.create!(
      title: "Test Entry",
      description: "Test description",
      url: "https://example.com",
      entryable: ruby_gem,
      status: :pending,
      submitter_email: "pending@example.com"
    )

    assert_equal "pending", entry.status

    entry.update!(status: :approved)
    assert_equal "approved", entry.status
  end

  test "can filter entries by status" do
    ruby_gem1 = RubyGem.create!(gem_name: "pending-gem")
    ruby_gem2 = RubyGem.create!(gem_name: "approved-gem")

    pending_entry = Entry.create!(
      title: "Pending Entry",
      description: "Test",
      url: "https://example.com",
      entryable: ruby_gem1,
      status: :pending,
      submitter_email: "pending@example.com"
    )

    approved_entry = Entry.create!(
      title: "Approved Entry",
      description: "Test",
      url: "https://example.com",
      entryable: ruby_gem2,
      status: :approved
    )

    pending_results = Entry.pending
    approved_results = Entry.approved

    assert_includes pending_results, pending_entry
    assert_not_includes pending_results, approved_entry
    assert_includes approved_results, approved_entry
    assert_not_includes approved_results, pending_entry
  end

  test "can filter published entries" do
    ruby_gem1 = RubyGem.create!(gem_name: "published-gem")
    ruby_gem2 = RubyGem.create!(gem_name: "unpublished-gem")

    published_entry = Entry.create!(
      title: "Published Entry",
      description: "Test",
      url: "https://example.com",
      entryable: ruby_gem1,
      published: true,
      status: :approved
    )

    unpublished_entry = Entry.create!(
      title: "Unpublished Entry",
      description: "Test",
      url: "https://example.com",
      entryable: ruby_gem2,
      published: false,
      status: :approved
    )

    published_results = Entry.published

    assert_includes published_results, published_entry
    assert_not_includes published_results, unpublished_entry
  end

  test "can create all 8 delegated types" do
    # RubyGem
    ruby_gem = RubyGem.create!(gem_name: "test-gem")
    entry1 = Entry.create!(title: "RubyGem Test", description: "Test", url: "https://example.com", entryable: ruby_gem, status: :approved)
    assert entry1.ruby_gem?

    # Book
    book = Book.create!(format: :ebook)
    entry2 = Entry.create!(title: "Book Test", description: "Test", url: "https://example.com", entryable: book, status: :approved)
    assert entry2.book?

    # Course
    course = Course.create!(is_free: true)
    entry3 = Entry.create!(title: "Course Test", description: "Test", url: "https://example.com", entryable: course, status: :approved)
    assert entry3.course?

    # Tutorial
    tutorial = Tutorial.create!
    entry4 = Entry.create!(title: "Tutorial Test", description: "Test", url: "https://example.com", entryable: tutorial, status: :approved)
    assert entry4.tutorial?

    # Article
    article = Article.create!
    entry5 = Entry.create!(title: "Article Test", description: "Test", url: "https://example.com", entryable: article, status: :approved)
    assert entry5.article?

    # Tool
    tool = Tool.create!(is_open_source: true)
    entry6 = Entry.create!(title: "Tool Test", description: "Test", url: "https://example.com", entryable: tool, status: :approved)
    assert entry6.tool?

    # Podcast
    podcast = Podcast.create!
    entry7 = Entry.create!(title: "Podcast Test", description: "Test", url: "https://example.com", entryable: podcast, status: :approved)
    assert entry7.podcast?

    # Community
    community = Community.create!(platform: "Discord", join_url: "https://discord.gg/test")
    entry8 = Entry.create!(title: "Community Test", description: "Test", url: "https://example.com", entryable: community, status: :approved)
    assert entry8.community?
  end

  test "tags save and load correctly" do
    ruby_gem = RubyGem.create!(gem_name: "test-gem")
    entry = Entry.create!(
      title: "Test Entry",
      description: "Test",
      url: "https://example.com",
      entryable: ruby_gem,
      tags: [ "testing", "ruby", "gem" ],
      status: :approved
    )

    entry.reload
    assert_equal [ "testing", "ruby", "gem" ], entry.tags
  end
end
