# frozen_string_literal: true

require "test_helper"

class HomeDirectoryTest < ActiveSupport::TestCase
  test "recent entries select a type and preserve newest first ordering and limits" do
    5.times do |index|
      Entry.create!(title: "Recent Book #{index}", url: "https://example.com/book/#{index}",
        entryable: Book.new, published: true, status: :approved, updated_at: index.days.ago)
    end
    Entry.create!(title: "Hidden Book", url: "https://example.com/hidden", entryable: Book.new, status: :approved)

    assert_equal [ "Recent Book 0", "Recent Book 1", "Recent Book 2", "Recent Book 3" ], HomeDirectory.new.recent("books").pluck(:title)
  end

  test "statistics count visible resources and all categories and authors" do
    Entry.create!(title: "Visible", url: "https://example.com/visible", published: true, status: :approved)
    Entry.create!(title: "Hidden", url: "https://example.com/hidden", published: false, status: :approved)

    assert_equal({ resources: 1, categories: Category.count, authors: Author.count }, HomeDirectory.new.statistics)
  end

  test "the homepage entry scope honors its explicit limit and visible ordering" do
    older = Entry.create!(title: "Older", url: "https://example.com/older", published: true, status: :approved, updated_at: 2.days.ago)
    newest = Entry.create!(title: "Newest", url: "https://example.com/newest", published: true, status: :approved)
    Entry.create!(title: "Draft", url: "https://example.com/draft", published: false, status: :approved)

    assert_equal [ newest ], Entry.for_homepage(1).to_a
    assert_equal [ newest, older ], Entry.for_homepage.to_a
  end
end
