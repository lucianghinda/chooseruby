# frozen_string_literal: true

require "test_helper"

# Tests for Entry submission functionality supporting the Community Resource Submission Form
# These tests verify:
# - Entry creation with delegated types in single transaction
# - Atomic rollback when delegated type creation fails
# - Entry.pending scope functionality
# - Category associations (up to 3)
# - Author associations (dual input approach)
# - Slug generation from title
# - Default status: :pending and published: false
# - Image URL validation for external URLs
class EntrySubmissionTest < ActiveSupport::TestCase
  test "creates entry with RubyGem delegated type in single transaction" do
    assert_difference [ "Entry.count", "RubyGem.count" ], 1 do
      ruby_gem = RubyGem.create!(
        gem_name: "submission-gem",
        github_url: "https://github.com/example/gem"
      )
      Entry.create!(
        title: "Submission Gem",
        url: "https://example.com/gem",
        entryable: ruby_gem,
        submitter_name: "Jane Doe",
        submitter_email: "jane@example.com"
      )
    end
  end

  test "creates entry with Book delegated type in single transaction" do
    assert_difference [ "Entry.count", "Book.count" ], 1 do
      book = Book.create!(
        isbn: "9781234567890",
        publication_year: 2023
      )
      Entry.create!(
        title: "Ruby Book",
        url: "https://example.com/book",
        entryable: book,
        submitter_name: "John Smith",
        submitter_email: "john@example.com"
      )
    end
  end

  test "rollback when delegated type creation fails validation" do
    # This tests atomic behavior - if delegated type fails, entry should not be created
    assert_no_difference [ "Entry.count", "Community.count" ] do
      begin
        ActiveRecord::Base.transaction do
          # Community requires platform and join_url
          community = Community.create!(platform: "") # Missing required join_url - will fail
          Entry.create!(
            title: "Invalid Community",
            url: "https://example.com",
            entryable: community,
            submitter_email: "test@example.com"
          )
        end
      rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved
        # Expected to fail
      end
    end
  end

  test "Entry.pending scope returns only pending entries" do
    # Create pending entry
    pending_gem = RubyGem.create!(gem_name: "pending-submission")
    pending_entry = Entry.create!(
      title: "Pending Entry",
      url: "https://example.com/pending",
      entryable: pending_gem,
      status: :pending,
      published: false,
      submitter_email: "pending@example.com"
    )

    # Create approved entry
    approved_gem = RubyGem.create!(gem_name: "approved-submission")
    approved_entry = Entry.create!(
      title: "Approved Entry",
      url: "https://example.com/approved",
      entryable: approved_gem,
      status: :approved,
      published: true
    )

    pending_entries = Entry.pending
    assert_includes pending_entries, pending_entry
    assert_not_includes pending_entries, approved_entry
  end

  test "creates entry with up to 3 category associations" do
    category1 = Category.create!(name: "Testing Submit #{rand(10000)}", slug: "testing-submit-#{rand(10000)}")
    category2 = Category.create!(name: "Web Dev Submit #{rand(10000)}", slug: "web-dev-submit-#{rand(10000)}")
    category3 = Category.create!(name: "Tools Submit #{rand(10000)}", slug: "tools-submit-#{rand(10000)}")

    ruby_gem = RubyGem.create!(gem_name: "categories-gem")
    entry = Entry.create!(
      title: "Multi Category Entry",
      url: "https://example.com/categories",
      entryable: ruby_gem,
      submitter_email: "categories@example.com"
    )

    entry.categories << [ category1, category2, category3 ]
    assert_equal 3, entry.categories.count
    assert_includes entry.categories, category1
    assert_includes entry.categories, category2
    assert_includes entry.categories, category3
  end

  test "creates entry with author association from existing Author" do
    author = Author.create!(name: "Test Author Submit #{rand(10000)}", status: :approved)

    ruby_gem = RubyGem.create!(gem_name: "author-gem")
    entry = Entry.create!(
      title: "Entry with Author",
      url: "https://example.com/author",
      entryable: ruby_gem,
      submitter_email: "author@example.com"
    )

    entry.authors << author
    assert_equal 1, entry.authors.count
    assert_includes entry.authors, author
  end

  test "creates entry with manual author name in delegated type" do
    # For delegated types that support author_name field (Tutorial, Article)
    tutorial = Tutorial.create!(
      author_name: "Manual Author Name",
      reading_time_minutes: 10
    )
    entry = Entry.create!(
      title: "Tutorial with Manual Author",
      url: "https://example.com/tutorial",
      entryable: tutorial,
      submitter_email: "tutorial@example.com"
    )

    assert_equal "Manual Author Name", entry.entryable.author_name
  end

  test "generates slug from title automatically" do
    ruby_gem = RubyGem.create!(gem_name: "slug-gem")
    entry = Entry.create!(
      title: "Test Slug Generation",
      url: "https://example.com/slug",
      entryable: ruby_gem,
      submitter_email: "slug@example.com"
    )

    assert_equal "test-slug-generation", entry.slug
  end

  test "defaults status to pending and published to false" do
    ruby_gem = RubyGem.create!(gem_name: "defaults-gem")
    entry = Entry.create!(
      title: "Default Values Entry",
      url: "https://example.com/defaults",
      entryable: ruby_gem,
      submitter_email: "defaults@example.com"
    )

    assert_equal "pending", entry.status
    assert_equal false, entry.published
  end

  test "validates image_url format for external URLs" do
    ruby_gem = RubyGem.create!(gem_name: "image-validation-gem")

    # Valid external URL
    entry = Entry.new(
      title: "Valid Image URL",
      url: "https://example.com/valid",
      entryable: ruby_gem,
      image_url: "https://example.com/image.png",
      submitter_email: "valid@example.com"
    )
    assert entry.valid?

    # Invalid URL
    entry_invalid = Entry.new(
      title: "Invalid Image URL",
      url: "https://example.com/invalid",
      entryable: ruby_gem,
      image_url: "not-a-valid-url",
      submitter_email: "invalid@example.com"
    )
    assert_not entry_invalid.valid?
    assert entry_invalid.errors[:image_url].present?
  end

  test "validates submitter_email presence for pending entries" do
    ruby_gem = RubyGem.create!(gem_name: "email-validation-gem")

    # Pending entry without email should fail
    entry = Entry.new(
      title: "No Email Entry",
      url: "https://example.com/no-email",
      entryable: ruby_gem,
      status: :pending,
      submitter_email: nil
    )
    assert_not entry.valid?
    assert entry.errors[:submitter_email].present?
  end

  test "validates submitter_email format" do
    ruby_gem = RubyGem.create!(gem_name: "email-format-gem")

    # Invalid email format
    entry = Entry.new(
      title: "Invalid Email Format",
      url: "https://example.com/invalid-email",
      entryable: ruby_gem,
      submitter_email: "not-an-email",
      status: :pending
    )
    assert_not entry.valid?
    assert entry.errors[:submitter_email].present?

    # Valid email format
    entry_valid = Entry.new(
      title: "Valid Email Format",
      url: "https://example.com/valid-email",
      entryable: ruby_gem,
      submitter_email: "valid@example.com",
      status: :pending
    )
    assert entry_valid.valid?
  end

  test "submitter_email is optional for approved entries" do
    ruby_gem = RubyGem.create!(gem_name: "approved-no-email-gem")

    # Approved entry without email should pass
    entry = Entry.create!(
      title: "Approved No Email",
      url: "https://example.com/approved-no-email",
      entryable: ruby_gem,
      status: :approved,
      published: true,
      submitter_email: nil
    )
    assert entry.persisted?
    assert_nil entry.submitter_email
  end
end
