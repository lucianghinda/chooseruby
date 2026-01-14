# frozen_string_literal: true

require "test_helper"

class DelegatedTypesTest < ActiveSupport::TestCase
  test "can create entry with RubyGem delegated type" do
    ruby_gem = RubyGem.create!(gem_name: "rspec")
    entry = Entry.create!(
      title: "RSpec",
      url: "https://rspec.info",
      entryable: ruby_gem,
      status: :approved
    )

    assert entry.persisted?
    assert entry.ruby_gem?
    assert_equal "rspec", entry.entryable.gem_name
  end

  test "can create entry with Book delegated type" do
    book = Book.create!(isbn: "1234567890", format: :ebook)
    entry = Entry.create!(
      title: "Test Book",
      url: "https://example.com",
      entryable: book,
      status: :approved
    )

    assert entry.book?
    assert_equal "1234567890", entry.entryable.isbn
  end

  test "can create entry with Course delegated type" do
    course = Course.create!(platform: "Udemy", is_free: true)
    entry = Entry.create!(
      title: "Test Course",
      url: "https://example.com",
      entryable: course,
      status: :approved
    )

    assert entry.course?
    assert entry.entryable.is_free
  end

  test "can create entry with Tutorial delegated type" do
    tutorial = Tutorial.create!(reading_time_minutes: 15)
    entry = Entry.create!(
      title: "Test Tutorial",
      url: "https://example.com",
      entryable: tutorial,
      status: :approved
    )

    assert entry.tutorial?
    assert_equal 15, entry.entryable.reading_time_minutes
  end

  test "can create entry with Article delegated type" do
    article = Article.create!(platform: "Dev.to")
    entry = Entry.create!(
      title: "Test Article",
      url: "https://example.com",
      entryable: article,
      status: :approved
    )

    assert entry.article?
    assert_equal "Dev.to", entry.entryable.platform
  end

  test "can create entry with Tool delegated type" do
    tool = Tool.create!(tool_type: "CLI", is_open_source: true)
    entry = Entry.create!(
      title: "Test Tool",
      url: "https://example.com",
      entryable: tool,
      status: :approved
    )

    assert entry.tool?
    assert entry.entryable.is_open_source
  end

  test "can create entry with Podcast delegated type" do
    podcast = Podcast.create!(host: "John Doe", episode_count: 50)
    entry = Entry.create!(
      title: "Test Podcast",
      url: "https://example.com",
      entryable: podcast,
      status: :approved
    )

    assert entry.podcast?
    assert_equal 50, entry.entryable.episode_count
  end

  test "can create entry with Community delegated type" do
    community = Community.create!(
      platform: "Discord",
      join_url: "https://discord.gg/example",
      is_official: true
    )
    entry = Entry.create!(
      title: "Test Community",
      url: "https://example.com",
      entryable: community,
      status: :approved
    )

    assert entry.community?
    assert_equal "Discord", entry.entryable.platform
    assert entry.entryable.is_official
  end

  test "deleting delegated type also deletes the entry" do
    ruby_gem = RubyGem.create!(gem_name: "test-gem")
    entry = Entry.create!(
      title: "Test Gem",
      url: "https://example.com",
      entryable: ruby_gem,
      status: :approved
    )

    entry_id = entry.id
    ruby_gem.destroy

    refute Entry.exists?(entry_id)
  end

  test "type checking helpers work correctly" do
    ruby_gem = RubyGem.create!(gem_name: "test-gem")
    entry = Entry.create!(
      title: "Test Gem",
      url: "https://example.com",
      entryable: ruby_gem,
      status: :approved
    )

    assert entry.ruby_gem?
    refute entry.book?
    refute entry.course?
    refute entry.tutorial?
    refute entry.article?
    refute entry.tool?
    refute entry.podcast?
    refute entry.community?
  end
end
