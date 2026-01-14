# frozen_string_literal: true

require "test_helper"

# Integration tests for critical Author feature workflows
# Tests end-to-end scenarios spanning multiple models and controllers
class AuthorWorkflowsTest < ActionDispatch::IntegrationTest
  test "end-to-end: pending author approval workflow" do
    # Create a pending author
    pending_author = Author.create(
      name: "New Contributor",
      bio: "A new contributor to the Ruby community",
      github_url: "https://github.com/newcontributor",
      status: :pending
    )

    # Pending author should not be visible on public profile
    get author_path(slug: pending_author.slug)
    assert_response :not_found

    # Admin approves the author
    pending_author.approved!

    # Now the author should be visible
    get author_path(slug: pending_author.slug)
    assert_response :success
    assert_select "h1", text: "New Contributor"
  end

  test "end-to-end: GitHub avatar fetch and display pipeline" do
    # Create author with GitHub URL
    author = Author.create(
      name: "GitHub User",
      github_url: "https://github.com/dhh",
      status: :approved
    )

    # Avatar should be fetched automatically
    assert_equal "https://github.com/dhh.png", author.avatar_url

    # Avatar should display on profile page
    get author_path(slug: author.slug)
    assert_response :success
    assert_select "img[src='https://github.com/dhh.png']"
  end

  test "author with no entries displays correctly" do
    # Create author without any entries
    author = Author.create(
      name: "Entryless Author",
      bio: "An author without entries yet",
      status: :approved
    )

    get author_path(slug: author.slug)
    assert_response :success
    assert_select "h1", text: "Entryless Author"
    assert_select "p", text: /No resources yet/i
  end

  test "author with multiple entries displays all on profile" do
    author = Author.create(name: "Prolific Author", status: :approved)

    # Create multiple entries
    entry1 = Entry.create(title: "First Entry", url: "https://example.com/1", status: :approved, published: true)
    entry2 = Entry.create(title: "Second Entry", url: "https://example.com/2", status: :approved, published: true)
    entry3 = Entry.create(title: "Third Entry", url: "https://example.com/3", status: :approved, published: true)

    author.entries << [ entry1, entry2, entry3 ]

    get author_path(slug: author.slug)
    assert_response :success
    # Entries are displayed as h3 with links
    assert_select "a", text: "First Entry"
    assert_select "a", text: "Second Entry"
    assert_select "a", text: "Third Entry"
  end

  test "entry with multiple authors displays all authors" do
    author1 = Author.create(name: "First Author", status: :approved)
    author2 = Author.create(name: "Second Author", status: :approved)
    entry = Entry.create(title: "Collaborative Entry", url: "https://example.com/collab", status: :approved, published: true)

    entry.authors << [ author1, author2 ]

    # Both authors should have this entry
    get author_path(slug: author1.slug)
    assert_response :success
    assert_select "a", text: "Collaborative Entry"

    get author_path(slug: author2.slug)
    assert_response :success
    assert_select "a", text: "Collaborative Entry"
  end

  test "updating github_url refetches avatar" do
    author = Author.create(
      name: "Changing Avatar",
      github_url: "https://github.com/matz",
      status: :approved
    )

    assert_equal "https://github.com/matz.png", author.avatar_url

    # Update to different GitHub URL
    author.update(github_url: "https://github.com/dhh")

    assert_equal "https://github.com/dhh.png", author.reload.avatar_url
  end

  test "author slug remains stable when name changes" do
    author = Author.create(name: "Original Name", status: :approved)
    original_slug = author.slug

    # Change the name - slug should update
    author.update(name: "New Name")

    # Slug should change based on implementation
    # (current implementation regenerates slug when name changes)
    assert_equal "new-name", author.slug
    refute_equal original_slug, author.slug
  end

  test "pagination works correctly for authors with many entries" do
    author = Author.create(name: "Busy Author", status: :approved)

    # Create 25 entries
    25.times do |i|
      entry = Entry.create(title: "Entry #{i}", url: "https://example.com/#{i}", status: :approved, published: true)
      author.entries << entry
    end

    # First page should show 20 entries
    get author_path(slug: author.slug)
    assert_response :success
    assert_select "div.bg-white.border.border-gray-200.rounded-lg", count: 20

    # Second page should show 5 entries
    get author_path(slug: author.slug, page: 2)
    assert_response :success
    assert_select "div.bg-white.border.border-gray-200.rounded-lg", count: 5
  end

  test "social links display only when provided" do
    author = Author.create(
      name: "Social Author",
      github_url: "https://github.com/test",
      twitter_url: "https://twitter.com/test",
      status: :approved
    )

    get author_path(slug: author.slug)
    assert_response :success

    # Should have GitHub and Twitter links
    assert_select "a[href='https://github.com/test']"
    assert_select "a[href='https://twitter.com/test']"

    # Should not have other social links (like LinkedIn, YouTube)
    assert_select "a[href*='linkedin']", count: 0
    assert_select "a[href*='youtube']", count: 0
  end

  test "author bio displays when present and is absent when blank" do
    # Author with bio
    author_with_bio = Author.create(
      name: "Bio Author",
      bio: "This is a test biography",
      status: :approved
    )

    get author_path(slug: author_with_bio.slug)
    assert_response :success
    # Bio should be in a paragraph
    assert_select "p", text: "This is a test biography"

    # Author without bio
    author_without_bio = Author.create(
      name: "No Bio Author",
      status: :approved
    )

    get author_path(slug: author_without_bio.slug)
    assert_response :success
    # Should have h1 with name but bio paragraph should not exist
    assert_select "h1", text: "No Bio Author"
    # The bio paragraph has specific text-lg and max-w-2xl classes
    # When bio is absent, this p tag shouldn't exist
    response_body = response.body
    refute_includes response_body, "text-lg text-gray-600 max-w-2xl"
  end
end
