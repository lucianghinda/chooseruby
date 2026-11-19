# frozen_string_literal: true

require "test_helper"

class RubyandrailsinfoHelpersTest < ActiveSupport::TestCase
  Helpers = Imports::Rubyandrailsinfo::Helpers

  setup { Helpers.reset_lookups! }
  teardown { Helpers.reset_lookups! }

  test "registers and finds an entry by old polymorphic reference" do
    entry = Object.new
    Helpers.register_entry("Book", 42, entry)

    assert_same entry, Helpers.find_entry("Book", 42)
    assert_same entry, Helpers.find_entry("Book", "42")
    assert_nil Helpers.find_entry("Course", 42)
  end

  test "registers and finds an author by old id" do
    author = Object.new
    Helpers.register_author(7, author)

    assert_same author, Helpers.find_author(7)
    assert_same author, Helpers.find_author("7")
    assert_nil Helpers.find_author(8)
  end

  test "registers and finds a category by old tag id" do
    category = Object.new
    Helpers.register_category(3, category)

    assert_same category, Helpers.find_category(3)
    assert_same category, Helpers.find_category("3")
    assert_nil Helpers.find_category(4)
  end

  test "reset_lookups! drops every registration" do
    Helpers.register_entry("Book", 1, Object.new)
    Helpers.register_author(1, Object.new)
    Helpers.register_category(1, Object.new)

    Helpers.reset_lookups!

    assert_nil Helpers.find_entry("Book", 1)
    assert_nil Helpers.find_author(1)
    assert_nil Helpers.find_category(1)
  end

  test "parse_time converts a timestamp string" do
    assert_equal Time.zone.parse("2024-01-02 03:04:05"),
      Helpers.parse_time("2024-01-02 03:04:05")
  end

  test "parse_time returns nil for missing values" do
    assert_nil Helpers.parse_time(nil)
    assert_nil Helpers.parse_time('\N')
    assert_nil Helpers.parse_time("")
  end

  test "parse_time returns nil for an out-of-range timestamp" do
    assert_raises(ArgumentError) { Time.zone.parse("99:99") }

    assert_nil Helpers.parse_time("99:99")
  end

  test "parse_bool only accepts the PostgreSQL true literals" do
    assert Helpers.parse_bool("t")
    assert Helpers.parse_bool("true")
    assert_not Helpers.parse_bool("f")
    assert_not Helpers.parse_bool(nil)
  end

  test "to_int converts digits and returns nil for missing values" do
    assert_equal 42, Helpers.to_int("42")
    assert_nil Helpers.to_int(nil)
    assert_nil Helpers.to_int('\N')
    assert_nil Helpers.to_int("")
  end

  test "progress rewrites the current line while work is running" do
    out, = capture_io { Helpers.progress(1, 3, "Authors") }

    assert_equal "\r  Authors: 1/3", out
  end

  test "progress ends the line on the last item" do
    out, = capture_io { Helpers.progress(3, 3, "Authors") }

    assert_equal "\r  Authors: 3/3\n", out
  end
end
