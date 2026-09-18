# frozen_string_literal: true

require "test_helper"

class Imports::Rubyandrailsinfo::SqlToYamlConverterTest < ActiveSupport::TestCase
  test "convert_all writes one YAML file per table with entry data nested" do
    Dir.mktmpdir do |output_dir|
      converter = Imports::Rubyandrailsinfo::SqlToYamlConverter.new(
        sql_file: file_fixture("rubyandrailsinfo/latest.sql"),
        output_dir: output_dir
      )

      output = capture_io { converter.convert_all }.first

      assert_match "Converted books: 1 records → books.yml", output
      assert_equal %w[authorings.yml authors.yml books.yml communities.yml courses.yml lessons.yml newsletters.yml podcasts.yml screencasts.yml taggings.yml tags.yml youtubes.yml],
                   Dir.children(output_dir).sort

      tags = YAML.load_file(File.join(output_dir, "tags.yml"))
      assert_equal "ruby-on-rails-7", tags.first["slug"]

      jane = YAML.load_file(File.join(output_dir, "authors.yml")).first
      assert_not jane.key?("github_url"), "nil columns are dropped"

      book = YAML.load_file(File.join(output_dir, "books.yml")).first
      assert_equal "9781680507218", book["isbn"]
      assert_equal({ "title" => "Modern Front-End Development for Rails", "content" => "A book about Rails front-ends.",
                     "slug" => "modern-front-end-development-for-rails", "website_url" => "https://pragprog.com/titles/nrclient2/" }, book["entry"])

      course = YAML.load_file(File.join(output_dir, "courses.yml")).first
      assert_equal "t", course["free"]
      assert_equal({ "title" => "Rails Course", "slug" => "rails-course", "website_url" => "https://example.com/rails-course" }, course["entry"])

      community = YAML.load_file(File.join(output_dir, "communities.yml")).first
      assert_equal "1000", community["members"]

      lesson = YAML.load_file(File.join(output_dir, "lessons.yml")).first
      assert_equal "1", lesson["youtube_id"]
      assert_equal "MwbmKqdDsyI", lesson["entry"]["url"]

      %w[newsletters podcasts youtubes screencasts].each do |table|
        record = YAML.load_file(File.join(output_dir, "#{table}.yml")).first
        assert_equal %w[id created_at updated_at entry], record.keys, "#{table} only keeps id, timestamps and entry"
      end
    end
  end
end
