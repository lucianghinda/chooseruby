# frozen_string_literal: true

require "test_helper"
require "tmpdir"

class ImportsRubyandrailsinfoSqlPipelineTest < Minitest::Test
  def setup
    @directory = Dir.mktmpdir("rubyandrailsinfo-sql")
    @sql_path = File.join(@directory, "dump.sql")
  end

  def teardown
    FileUtils.remove_entry(@directory)
  end

  def test_copy_parser_preserves_null_empty_and_escaped_fields_and_skips_malformed_rows
    File.write(@sql_path, <<~'SQL'.gsub("<empty>", ""))
      COPY "public"."authors" ("id", "name", "notes") FROM stdin;
      1	Ruby\tAuthor	line\nnext\rline\\end
      2	\N	<empty>
      malformed	row
      \.
    SQL
    parser = Imports::Rubyandrailsinfo::SqlParser.new(@sql_path)

    assert_equal [
      { "id" => "1", "name" => "Ruby\tAuthor", "notes" => "line\nnext\rline\\end" },
      { "id" => "2", "name" => nil, "notes" => "" }
    ], parser.extract_table("authors")
    assert_empty parser.extract_table("missing")
  end

  def test_copy_parser_requires_a_complete_block_and_escapes_the_table_name
    File.write(@sql_path, <<~'SQL')
      COPY "public"."author.records" ("id") FROM stdin;
      12
      \.
      COPY "public"."unfinished" ("id") FROM stdin;
      13
    SQL
    parser = Imports::Rubyandrailsinfo::SqlParser.new(@sql_path)

    assert_equal [ { "id" => "12" } ], parser.extract_table("author.records")
    assert_empty parser.extract_table("author.records.*")
    assert_empty parser.extract_table("unfinished")
  end

  def test_converter_writes_every_table_and_separates_entity_and_entry_fields
    File.write(@sql_path, <<~'SQL')
      COPY "public"."tags" ("id", "title", "optional") FROM stdin;
      1	Testing	\N
      \.
      COPY "public"."books" ("id", "title", "content", "slug", "isbn", "year", "page", "website_url", "amazon_url", "free", "featured", "created_at", "updated_at") FROM stdin;
      2	Ruby Book	Read Ruby	book	1234567890	2024	300	https://book.example	https://shop.example	t	f	2024-01-01	2024-01-02
      \.
      COPY "public"."courses" ("id", "title", "free", "website_url") FROM stdin;
      3	Course	t	https://course.example
      \.
      COPY "public"."communities" ("id", "title", "platform_type", "members") FROM stdin;
      4	Community	Discord	12
      \.
      COPY "public"."lessons" ("id", "title", "url", "youtube_id") FROM stdin;
      5	Lesson	abcdefghijk	abcdefghijk
      \.
      COPY "public"."youtubes" ("id", "title", "website_url") FROM stdin;
      6	Youtube	https://youtube.example
      \.
      COPY "public"."newsletters" ("id", "title") FROM stdin;
      7	Newsletter
      \.
      COPY "public"."podcasts" ("id", "title") FROM stdin;
      8	Podcast
      \.
      COPY "public"."screencasts" ("id", "title") FROM stdin;
      9	Screencast
      \.
    SQL
    output = File.join(@directory, "yaml")
    converter = Imports::Rubyandrailsinfo::SqlToYamlConverter.new(sql_file: @sql_path, output_dir: output)
    capture_io { converter.convert_all }

    assert_equal %w[ authorings authors books communities courses lessons newsletters podcasts screencasts taggings tags youtubes ], Dir.children(output).map { |name| File.basename(name, ".yml") }.sort
    assert_equal [ { "id" => "1", "title" => "Testing" } ], YAML.load_file(File.join(output, "tags.yml"))
    book = YAML.load_file(File.join(output, "books.yml")).first
    assert_equal "1234567890", book["isbn"]
    assert_equal "300", book["page"]
    assert_equal "2024", book["year"]
    assert_equal "https://shop.example", book["amazon_url"]
    assert_equal({ "title" => "Ruby Book", "content" => "Read Ruby", "slug" => "book", "website_url" => "https://book.example" }, book["entry"])
    assert_equal({ "id" => "3", "free" => "t", "entry" => { "title" => "Course", "website_url" => "https://course.example" } }, YAML.load_file(File.join(output, "courses.yml")).first)
    assert_equal "Discord", YAML.load_file(File.join(output, "communities.yml")).first["platform_type"]
    assert_equal "abcdefghijk", YAML.load_file(File.join(output, "lessons.yml")).first.dig("entry", "url")
    assert_empty YAML.load_file(File.join(output, "authors.yml"))
  end

  def test_id_mapper_keeps_record_types_separate_and_reports_unique_mappings
    mapper = Imports::Rubyandrailsinfo::IdMapper.new
    book = Object.new
    author = Object.new
    category = Object.new
    mapper.register_entry("Book", "1", book)
    mapper.register_author(1, author)
    mapper.register_category(1, category)

    assert_same book, mapper.find_entry("Book", 1)
    assert_nil mapper.find_entry("Course", 1)
    assert_same author, mapper.find_author("1")
    assert_same category, mapper.find_category("1")
    assert_equal({ categories: 1, authors: 1, entries: 1 }, mapper.stats)
  end
end
