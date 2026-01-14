# frozen_string_literal: true

# == Schema Information
#
# Table name: entries_authors
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  author_id  :integer          not null
#  entry_id   :integer          not null
#
# Indexes
#
#  index_entries_authors_on_author_id               (author_id)
#  index_entries_authors_on_author_id_and_entry_id  (author_id,entry_id) UNIQUE
#  index_entries_authors_on_entry_id                (entry_id)
#
# Foreign Keys
#
#  author_id  (author_id => authors.id) ON DELETE => cascade
#  entry_id   (entry_id => entries.id) ON DELETE => cascade
#
require "test_helper"

class EntriesAuthorTest < ActiveSupport::TestCase
  test "author can have multiple entries" do
    author = Author.create(name: "Yukihiro Matsumoto")
    entry1 = Entry.create(title: "Ruby Programming", url: "https://example.com/ruby", status: :approved)
    entry2 = Entry.create(title: "Advanced Ruby", url: "https://example.com/advanced", status: :approved)

    author.entries << entry1
    author.entries << entry2

    assert_equal 2, author.entries.count
    assert_includes author.entries, entry1
    assert_includes author.entries, entry2
  end

  test "entry can have multiple authors" do
    author1 = Author.create(name: "Yukihiro Matsumoto")
    author2 = Author.create(name: "David Heinemeier Hansson")
    entry = Entry.create(title: "Ruby on Rails", url: "https://example.com/rails", status: :approved)

    entry.authors << author1
    entry.authors << author2

    assert_equal 2, entry.authors.count
    assert_includes entry.authors, author1
    assert_includes entry.authors, author2
  end

  test "should not allow duplicate author-entry associations" do
    author = Author.create(name: "Yukihiro Matsumoto")
    entry = Entry.create(title: "Ruby Programming", url: "https://example.com/ruby", status: :approved)

    EntriesAuthor.create(author: author, entry: entry)

    assert_raises ActiveRecord::RecordNotUnique do
      EntriesAuthor.create(author: author, entry: entry)
    end
  end

  test "deleting author should remove associations" do
    author = Author.create(name: "Yukihiro Matsumoto")
    entry = Entry.create(title: "Ruby Programming", url: "https://example.com/ruby", status: :approved)
    author.entries << entry

    assert_difference "EntriesAuthor.count", -1 do
      author.destroy
    end
  end
end
