# frozen_string_literal: true

require "test_helper"

class EntryWorkflowTest < ActionDispatch::IntegrationTest
  test "creating entry with delegated type in single transaction" do
    assert_difference [ "Entry.count", "RubyGem.count" ], 1 do
      ruby_gem = RubyGem.create!(gem_name: "transaction-gem")
      Entry.create!(
        title: "Transaction Test",
        description: "Testing transaction",
        url: "https://example.com",
        entryable: ruby_gem,
        status: :approved # Skip submitter_email validation
      )
    end
  end

  test "deleting entry does not delete delegated type (orphan)" do
    ruby_gem = RubyGem.create!(gem_name: "orphan-gem")
    entry = Entry.create!(
      title: "Orphan Test",
      description: "Test",
      url: "https://example.com",
      entryable: ruby_gem,
      status: :approved # Skip submitter_email validation
    )

    # Deleting entry leaves the delegated type (orphan)
    assert_difference "Entry.count", -1 do
      assert_no_difference "RubyGem.count" do
        entry.destroy
      end
    end
  end

  test "deleting entry cascades to join table records" do
    category = categories(:testing)
    ruby_gem = RubyGem.create!(gem_name: "join-cascade-gem")
    entry = Entry.create!(
      title: "Join Cascade Test",
      description: "Test",
      url: "https://example.com",
      entryable: ruby_gem,
      status: :approved # Skip submitter_email validation
    )
    entry.categories << category

    assert_difference "CategoriesEntry.count", -1 do
      entry.destroy
    end
  end

  test "ActionText description persists and retrieves" do
    ruby_gem = RubyGem.create!(gem_name: "actiontext-gem")
    entry = Entry.create!(
      title: "ActionText Test",
      description: "<h1>Rich Text</h1><p>With formatting</p>",
      url: "https://example.com",
      entryable: ruby_gem,
      status: :approved # Skip submitter_email validation
    )

    entry.reload
    assert_not_nil entry.description
    assert entry.description.to_s.include?("Rich Text")
  end

  test "image URL can be set as string" do
    ruby_gem = RubyGem.create!(gem_name: "image-url-gem")
    entry = Entry.create!(
      title: "Image URL Test",
      description: "Test",
      url: "https://example.com",
      entryable: ruby_gem,
      image_url: "https://example.com/image.png",
      status: :approved # Skip submitter_email validation
    )

    assert_equal "https://example.com/image.png", entry.image_url
  end

  test "scopes return correct filtered results" do
    # Create pending entry
    pending_gem = RubyGem.create!(gem_name: "pending-scope-gem")
    pending_entry = Entry.create!(
      title: "Pending",
      description: "Test",
      url: "https://example.com",
      entryable: pending_gem,
      status: :pending,
      published: false,
      submitter_email: "pending@example.com" # Required for pending status
    )

    # Create approved and published entry
    approved_gem = RubyGem.create!(gem_name: "approved-scope-gem")
    approved_entry = Entry.create!(
      title: "Approved",
      description: "Test",
      url: "https://example.com",
      entryable: approved_gem,
      status: :approved,
      published: true
    )

    # Test scopes
    assert_includes Entry.pending, pending_entry
    assert_not_includes Entry.approved, pending_entry

    assert_includes Entry.approved, approved_entry
    assert_not_includes Entry.pending, approved_entry

    assert_includes Entry.published, approved_entry
    assert_not_includes Entry.published, pending_entry
  end

  test "URL validations reject invalid URLs" do
    ruby_gem = RubyGem.create!(gem_name: "url-validation-gem")

    # Invalid URL should fail validation
    entry = Entry.new(
      title: "Invalid URL Test",
      description: "Test",
      url: "not-a-valid-url",
      entryable: ruby_gem
    )

    assert_not entry.valid?
    assert entry.errors[:url].present?
  end

  test "entry can have multiple categories and authors" do
    category1 = categories(:testing)
    category2 = categories(:web_development)
    author1 = Author.create!(name: "Multi Test Author 1")
    author2 = Author.create!(name: "Multi Test Author 2")

    ruby_gem = RubyGem.create!(gem_name: "multi-relation-gem")
    entry = Entry.create!(
      title: "Multi Relation Test",
      description: "Test",
      url: "https://example.com",
      entryable: ruby_gem,
      status: :approved # Skip submitter_email validation
    )

    entry.categories << [ category1, category2 ]
    entry.authors << [ author1, author2 ]

    assert_equal 2, entry.categories.count
    assert_equal 2, entry.authors.count
    assert_includes entry.categories, category1
    assert_includes entry.categories, category2
    assert_includes entry.authors, author1
    assert_includes entry.authors, author2
  end

  test "changing entry type updates polymorphic association" do
    ruby_gem = RubyGem.create!(gem_name: "type-change-gem")
    entry = Entry.create!(
      title: "Type Change Test",
      description: "Test",
      url: "https://example.com",
      entryable: ruby_gem,
      status: :approved # Skip submitter_email validation
    )

    assert entry.ruby_gem?

    # Change to a book
    book = Book.create!(format: :ebook)
    entry.update!(entryable: book)

    assert entry.book?
    assert_not entry.ruby_gem?
    assert_equal "Book", entry.entryable_type
  end

  test "deleting delegated type removes entry due to dependent destroy" do
    ruby_gem = RubyGem.create!(gem_name: "delegate-delete-gem")
    entry = Entry.create!(
      title: "Delegate Delete Test",
      description: "Test",
      url: "https://example.com",
      entryable: ruby_gem,
      status: :approved # Skip submitter_email validation
    )

    # Deleting the delegated type deletes the entry (dependent: :destroy)
    assert_difference "Entry.count", -1 do
      ruby_gem.destroy
    end
  end
end
