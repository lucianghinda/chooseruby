# frozen_string_literal: true

require "test_helper"

class Imports::Rubyandrailsinfo::SqlParserTest < ActiveSupport::TestCase
  setup do
    @parser = Imports::Rubyandrailsinfo::SqlParser.new(file_fixture("rubyandrailsinfo/latest.sql"))
  end

  test "extract_table maps COPY rows to column hashes" do
    tags = @parser.extract_table("tags")

    assert_equal 2, tags.length
    assert_equal({ "id" => "1", "title" => "Ruby on Rails 7", "created_at" => "2022-06-19 09:25:01.836774",
                   "updated_at" => "2022-06-19 20:30:46.889638", "slug" => "ruby-on-rails-7" }, tags.first)
  end

  test "extract_table converts NULLs, empty strings and escapes" do
    jane, tabs = @parser.extract_table("authors")

    assert_nil jane["github_url"]
    assert_equal "", tabs["website_url"]
    assert_equal "Tabs\tAnd\nNewlines\\Backslash", tabs["name"]
  end

  test "extract_table drops rows whose column count does not match" do
    assert_equal %w[1 2], @parser.extract_table("authors").map { |row| row["id"] }
  end

  test "extract_table returns an empty list for a table that is not in the dump" do
    assert_empty @parser.extract_table("missing")
  end
end
