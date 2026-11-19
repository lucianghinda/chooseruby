# frozen_string_literal: true

require "test_helper"
require "tmpdir"

class RubyandrailsinfoSqlParserTest < ActiveSupport::TestCase
  # Pipes stand in for the tab delimiters of a COPY block.
  DUMP = <<~'SQL'
    COPY "public"."tags" ("id", "title", "slug") FROM stdin;
    1|Rails|rails
    2||\N
    3|a\tb|x\ny
    4|c\\d|e\rf
    5|too-few
    \.

    COPY "public"."authors" ("id", "name") FROM stdin;
    7|Matz
    \.
  SQL

  setup do
    @dir = Dir.mktmpdir
    path = File.join(@dir, "dump.sql")
    File.write(path, DUMP.gsub("|", "\t"))
    @parser = Imports::Rubyandrailsinfo::SqlParser.new(path)
  end

  teardown { FileUtils.remove_entry(@dir) }

  test "extracts the rows of a table as column-keyed hashes" do
    assert_equal({ "id" => "1", "title" => "Rails", "slug" => "rails" },
      @parser.extract_table("tags").first)
  end

  test "stops at the terminator instead of swallowing the next table" do
    assert_equal [ { "id" => "7", "name" => "Matz" } ], @parser.extract_table("authors")
  end

  test "returns no rows for a table the dump does not contain" do
    assert_empty @parser.extract_table("missing")
  end

  test "reads an empty field as a blank string and \\N as nil" do
    assert_equal({ "id" => "2", "title" => "", "slug" => nil },
      @parser.extract_table("tags").second)
  end

  test "unescapes tab, newline, carriage return and backslash" do
    rows = @parser.extract_table("tags")

    assert_equal({ "id" => "3", "title" => "a\tb", "slug" => "x\ny" }, rows.third)
    assert_equal({ "id" => "4", "title" => "c\\d", "slug" => "e\rf" }, rows.fourth)
  end

  test "drops a row whose field count does not match the column list" do
    ids = @parser.extract_table("tags").pluck("id")

    assert_equal %w[1 2 3 4], ids
  end

  test "returns no rows for a table with no data lines" do
    path = File.join(@dir, "empty.sql")
    File.write(path, %(COPY "public"."tags" ("id") FROM stdin;\n\\.\n))

    assert_empty Imports::Rubyandrailsinfo::SqlParser.new(path).extract_table("tags")
  end

  test "reads a COPY statement whose column list wraps over several lines" do
    path = File.join(@dir, "wrapped.sql")
    File.write(path, <<~'SQL'.gsub("|", "\t"))
      COPY "public"."tags" ("id", "title",
          "slug") FROM stdin;
      1|Rails|rails
      \.
    SQL

    assert_equal [ { "id" => "1", "title" => "Rails", "slug" => "rails" } ],
      Imports::Rubyandrailsinfo::SqlParser.new(path).extract_table("tags")
  end
end
