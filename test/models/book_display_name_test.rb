# frozen_string_literal: true

require "test_helper"

class BookDisplayNameTest < ActiveSupport::TestCase
  test "display_name returns entry title when entry exists" do
    book = Book.create!(publisher: "Test Publisher")
    entry = Entry.create!(
      title: "The Ruby Programming Language",
      url: "https://example.com/book",
      entryable: book,
      status: :approved
    )

    assert_equal "The Ruby Programming Language", book.display_name
  end

  test "display_name returns fallback when entry does not exist" do
    book = Book.create!(publisher: "Test Publisher")

    assert_equal "Book ##{book.id}", book.display_name
  end
end
