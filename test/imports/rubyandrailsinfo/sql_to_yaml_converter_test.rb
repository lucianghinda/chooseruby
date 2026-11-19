# frozen_string_literal: true

require "test_helper"
require "tmpdir"

class RubyandrailsinfoSqlToYamlConverterTest < ActiveSupport::TestCase
  # Pipes stand in for the tab delimiters of a COPY block.
  DUMP = <<~'SQL'
    COPY "public"."tags" ("id", "title", "slug", "created_at", "updated_at") FROM stdin;
    1|Rails|rails|2024-01-01 00:00:00|2024-01-02 00:00:00
    \.

    COPY "public"."authors" ("id", "name", "slug") FROM stdin;
    1|Matz|matz
    \.

    COPY "public"."books" ("id", "isbn", "year", "page", "amazon_url", "website_url", "free", "featured", "created_at", "updated_at", "title", "content", "slug") FROM stdin;
    1|978|2020|300|https://amazon.example/1|https://book.example|f|t|2024-01-01 00:00:00|2024-01-02 00:00:00|Eloquent Ruby|A book|eloquent-ruby
    \.

    COPY "public"."courses" ("id", "free", "created_at", "updated_at", "title", "content", "slug", "website_url") FROM stdin;
    1|t|2024-01-01 00:00:00|2024-01-02 00:00:00|Course One|A course|course-one|https://course.example
    \.

    COPY "public"."newsletters" ("id", "created_at", "updated_at", "title", "content", "slug", "website_url") FROM stdin;
    1|2024-01-01 00:00:00|2024-01-02 00:00:00|News|A newsletter|news|https://news.example
    \.

    COPY "public"."podcasts" ("id", "created_at", "updated_at", "title", "content", "slug", "website_url") FROM stdin;
    1|2024-01-01 00:00:00|2024-01-02 00:00:00|Pod|\N|pod|https://pod.example
    \.

    COPY "public"."communities" ("id", "platform_type", "members", "created_at", "updated_at", "title", "content", "slug", "website_url") FROM stdin;
    1|slack|42|2024-01-01 00:00:00|2024-01-02 00:00:00|Comm|A community|comm|https://comm.example
    \.

    COPY "public"."youtubes" ("id", "created_at", "updated_at", "title", "content", "slug", "website_url") FROM stdin;
    1|2024-01-01 00:00:00|2024-01-02 00:00:00|Tube|A channel|tube|https://tube.example
    \.

    COPY "public"."screencasts" ("id", "created_at", "updated_at", "title", "content", "slug", "website_url") FROM stdin;
    1|2024-01-01 00:00:00|2024-01-02 00:00:00|Cast|A screencast|cast|https://cast.example
    \.

    COPY "public"."lessons" ("id", "youtube_id", "created_at", "updated_at", "title", "content", "slug", "url") FROM stdin;
    1|abc123|2024-01-01 00:00:00|2024-01-02 00:00:00|Lesson|A lesson|lesson|dQw4w9WgXcQ
    \.

    COPY "public"."authorings" ("id", "author_id", "authorabble_type", "authorabble_id") FROM stdin;
    1|1|Book|1
    \.

    COPY "public"."taggings" ("id", "tag_id", "taggable_type", "taggable_id") FROM stdin;
    1|1|Book|1
    \.
  SQL

  setup do
    @dir = Dir.mktmpdir
    sql_file = File.join(@dir, "latest.sql")
    File.write(sql_file, DUMP.gsub("|", "\t"))
    @output_dir = File.join(@dir, "out")
    converter = Imports::Rubyandrailsinfo::SqlToYamlConverter.new(
      sql_file: sql_file, output_dir: @output_dir
    )
    @out, = capture_io { converter.convert_all }
  end

  teardown { FileUtils.remove_entry(@dir) }

  test "creates one YAML file per converted table" do
    assert_equal %w[authorings.yml authors.yml books.yml communities.yml courses.yml
      lessons.yml newsletters.yml podcasts.yml screencasts.yml taggings.yml
      tags.yml youtubes.yml].sort, Dir.children(@output_dir).sort
  end

  test "writes a simple table row for row" do
    assert_equal [ { "id" => "1", "title" => "Rails", "slug" => "rails",
                    "created_at" => "2024-01-01 00:00:00",
                    "updated_at" => "2024-01-02 00:00:00" } ], yaml("tags.yml")
  end

  test "writes a join table row for row" do
    assert_equal [ { "id" => "1", "author_id" => "1", "authorabble_type" => "Book",
                    "authorabble_id" => "1" } ], yaml("authorings.yml")
  end

  test "keeps the book-specific columns and nests the entry" do
    assert_equal [ { "id" => "1", "isbn" => "978", "year" => "2020", "page" => "300",
                    "amazon_url" => "https://amazon.example/1",
                    "website_url" => "https://book.example",
                    "free" => "f", "featured" => "t",
                    "created_at" => "2024-01-01 00:00:00",
                    "updated_at" => "2024-01-02 00:00:00",
                    "entry" => { "title" => "Eloquent Ruby", "content" => "A book",
                                 "slug" => "eloquent-ruby",
                                 "website_url" => "https://book.example" } } ],
      yaml("books.yml")
  end

  test "keeps the free flag for courses" do
    assert_equal "t", yaml("courses.yml").first["free"]
  end

  test "keeps platform and member count for communities" do
    community = yaml("communities.yml").first

    assert_equal "slack", community["platform_type"]
    assert_equal "42", community["members"]
  end

  test "keeps the youtube id for lessons and takes the url from the url column" do
    assert_equal [ { "id" => "1", "youtube_id" => "abc123",
                    "created_at" => "2024-01-01 00:00:00",
                    "updated_at" => "2024-01-02 00:00:00",
                    "entry" => { "title" => "Lesson", "content" => "A lesson",
                                 "slug" => "lesson", "url" => "dQw4w9WgXcQ" } } ],
      yaml("lessons.yml")
  end

  test "keeps only id and timestamps for tables without own columns" do
    %w[newsletters.yml youtubes.yml screencasts.yml].each do |filename|
      record = yaml(filename).first

      assert_equal %w[id created_at updated_at entry], record.keys, filename
      assert record["entry"].key?("website_url"), filename
    end
  end

  test "drops null values instead of writing them out" do
    entry = yaml("podcasts.yml").first["entry"]

    assert_equal %w[title slug website_url], entry.keys
  end

  test "reports every conversion and where the files went" do
    assert_includes @out, "✓ Converted books: 1 records → books.yml"
    assert_includes @out, "✓ Converted taggings: 1 records → taggings.yml"
    assert_includes @out, "All conversions complete! YAML files created in #{@output_dir}"
  end

  private

  def yaml(filename)
    YAML.load_file(File.join(@output_dir, filename))
  end
end
