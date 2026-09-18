# frozen_string_literal: true

require "test_helper"

class Imports::Rubyandrailsinfo::IdMapperTest < ActiveSupport::TestCase
  test "maps old ids to records by type and reports stats" do
    mapper = Imports::Rubyandrailsinfo::IdMapper.new
    category = Category.new(name: "Testing")
    author = Author.new(name: "Jane")
    entry = Entry.new(title: "Book")

    mapper.register_category(1, category)
    mapper.register_author("2", author)
    mapper.register_entry("Book", 3, entry)

    assert_equal category, mapper.find_category("1")
    assert_equal author, mapper.find_author(2)
    assert_equal entry, mapper.find_entry("Book", "3")
    assert_nil mapper.find_entry("Course", 3)
    assert_equal({ categories: 1, authors: 1, entries: 1 }, mapper.stats)
  end
end
