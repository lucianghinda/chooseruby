# frozen_string_literal: true

require "test_helper"

class RubyandrailsinfoIdMapperTest < ActiveSupport::TestCase
  setup { @mapper = Imports::Rubyandrailsinfo::IdMapper.new }

  test "maps an old tag id to a category" do
    category = Object.new
    @mapper.register_category(3, category)

    assert_same category, @mapper.find_category(3)
    assert_same category, @mapper.find_category("3")
    assert_nil @mapper.find_category(4)
  end

  test "maps an old author id to an author" do
    author = Object.new
    @mapper.register_author(7, author)

    assert_same author, @mapper.find_author(7)
    assert_same author, @mapper.find_author("7")
    assert_nil @mapper.find_author(8)
  end

  test "maps an old polymorphic reference to an entry" do
    entry = Object.new
    @mapper.register_entry("Book", 42, entry)

    assert_same entry, @mapper.find_entry("Book", 42)
    assert_same entry, @mapper.find_entry("Book", "42")
    assert_nil @mapper.find_entry("Course", 42)
  end

  test "stats counts the registrations per kind" do
    assert_equal({ categories: 0, authors: 0, entries: 0 }, @mapper.stats)

    @mapper.register_category(1, Object.new)
    @mapper.register_author(1, Object.new)
    @mapper.register_entry("Book", 1, Object.new)
    @mapper.register_entry("Course", 1, Object.new)

    assert_equal({ categories: 1, authors: 1, entries: 2 }, @mapper.stats)
  end

  test "two mappers do not share state" do
    other = Imports::Rubyandrailsinfo::IdMapper.new
    @mapper.register_author(1, Object.new)

    assert_nil other.find_author(1)
  end
end
