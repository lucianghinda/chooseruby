# frozen_string_literal: true

require "test_helper"

class Imports::Rubyandrailsinfo::HelpersTest < ActiveSupport::TestCase
  Helpers = Imports::Rubyandrailsinfo::Helpers

  teardown { Helpers.reset_lookups! }

  test "registers and finds entries, authors and categories by their old ids" do
    entry = Entry.new(title: "Book")
    author = Author.new(name: "Jane")
    category = Category.new(name: "Testing")

    Helpers.register_entry("Book", 1, entry)
    Helpers.register_author(2, author)
    Helpers.register_category(3, category)

    assert_equal entry, Helpers.find_entry("Book", "1")
    assert_equal author, Helpers.find_author("2")
    assert_equal category, Helpers.find_category("3")

    Helpers.reset_lookups!

    assert_nil Helpers.find_entry("Book", "1")
  end

  test "parse_time handles PostgreSQL nulls, blanks and invalid values" do
    assert_equal Time.zone.parse("2022-06-19 09:24:14"), Helpers.parse_time("2022-06-19 09:24:14")
    assert_nil Helpers.parse_time(nil)
    assert_nil Helpers.parse_time('\N')
    assert_nil Helpers.parse_time("")
    assert_nil Helpers.parse_time("not a date")
    assert_nil Helpers.parse_time("2022-13-45")
  end

  test "parse_bool and to_int convert PostgreSQL values" do
    assert Helpers.parse_bool("t")
    assert Helpers.parse_bool("true")
    assert_not Helpers.parse_bool("f")
    assert_equal 42, Helpers.to_int("42")
    assert_nil Helpers.to_int(nil)
    assert_nil Helpers.to_int('\N')
    assert_nil Helpers.to_int("")
  end

  test "progress prints the counter and ends the line when complete" do
    assert_output("\r  Books: 1/2") { Helpers.progress(1, 2, "Books") }
    assert_output("\r  Books: 2/2\n") { Helpers.progress(2, 2, "Books") }
  end
end
