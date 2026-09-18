# frozen_string_literal: true

require "test_helper"
require "tmpdir"

class ImportsRubyandrailsinfoHelpersTest < Minitest::Test
  def setup
    @helpers = Imports::Rubyandrailsinfo::Helpers.new
  end

  def test_entry_mapping_distinguishes_types_and_normalizes_ids
    book = Object.new
    course = Object.new
    @helpers.register_entry("Book", 12, book)
    @helpers.register_entry("Course", "12", course)

    assert_same book, @helpers.find_entry("Book", "12")
    assert_same course, @helpers.find_entry("Course", 12)
    assert_nil @helpers.find_entry("Video", 12)
  end

  def test_author_and_category_mapping_normalizes_ids
    author = Object.new
    category = Object.new
    @helpers.register_author(7, author)
    @helpers.register_category("7", category)

    assert_same author, @helpers.find_author("7")
    assert_same category, @helpers.find_category(7)
    assert_nil @helpers.find_author(8)
    assert_nil @helpers.find_category(8)
  end

  def test_separate_imports_do_not_share_mappings
    other_import = Imports::Rubyandrailsinfo::Helpers.new
    @helpers.register_entry("Book", 1, Object.new)
    @helpers.register_author(1, Object.new)
    @helpers.register_category(1, Object.new)

    assert_nil other_import.find_entry("Book", 1)
    assert_nil other_import.find_author(1)
    assert_nil other_import.find_category(1)
  end

  def test_reset_clears_all_mappings
    @helpers.register_entry("Book", 1, Object.new)
    @helpers.register_author(1, Object.new)
    @helpers.register_category(1, Object.new)
    @helpers.reset_lookups!

    assert_nil @helpers.find_entry("Book", 1)
    assert_nil @helpers.find_author(1)
    assert_nil @helpers.find_category(1)
  end

  def test_parses_timestamps_in_the_current_time_zone
    Time.use_zone("Prague") do
      assert_equal Time.zone.local(2024, 1, 15, 9, 30), Imports::Rubyandrailsinfo::Values.parse_time("2024-01-15 09:30:00")
    end
  end

  def test_missing_and_invalid_timestamps_return_nil
    [ nil, "", '\N', "not-a-time", "2024-99-99" ].each do |value|
      assert_nil Imports::Rubyandrailsinfo::Values.parse_time(value)
    end
  end

  def test_yaml_timestamps_preserve_offsets_and_reject_invalid_values
    assert_equal Time.utc(2024, 1, 15, 7, 30), Imports::Rubyandrailsinfo::Values.parse_timestamp("2024-01-15 09:30:00 +0200")
    [ nil, "", "not-a-time", "2024-99-99", 12 ].each do |value|
      assert_nil Imports::Rubyandrailsinfo::Values.parse_timestamp(value)
    end
  end

  def test_boolean_conversion_accepts_only_postgresql_true_values
    [ "t", "true" ].each { |value| assert_same true, Imports::Rubyandrailsinfo::Values.parse_bool(value) }
    [ nil, "", '\N', "f", "false", "TRUE", "1" ].each do |value|
      assert_same false, Imports::Rubyandrailsinfo::Values.parse_bool(value)
    end
  end

  def test_integer_conversion_handles_nulls_and_signed_numbers
    [ nil, "", '\N' ].each { |value| assert_nil Imports::Rubyandrailsinfo::Values.to_int(value) }

    assert_equal 42, Imports::Rubyandrailsinfo::Values.to_int("42")
    assert_equal(-7, Imports::Rubyandrailsinfo::Values.to_int("-7"))
    assert_equal 0, Imports::Rubyandrailsinfo::Values.to_int("0")
  end

  def test_progress_ends_the_completed_batch_with_a_newline
    assert_output("\r  Books: 1/2") { @helpers.progress(1, 2, "Books") }
    assert_output("\r  Books: 2/2\n") { @helpers.progress(2, 2, "Books") }
  end

  def test_seed_files_share_mapping_and_methods_only_within_one_import
    Dir.mktmpdir("rubyandrailsinfo-seeds") do |directory|
      first_seed = File.join(directory, "first.rb")
      second_seed = File.join(directory, "second.rb")
      File.write(first_seed, <<~RUBY)
        def imported_title
          "Imported book"
        end

        register_entry("Book", 42, imported_title)
      RUBY
      File.write(second_seed, 'find_entry("Book", "42")')
      @helpers.load_seed(first_seed)

      assert_equal "Imported book", @helpers.load_seed(second_seed)
      assert_nil Imports::Rubyandrailsinfo::Helpers.new.load_seed(second_seed)
      refute_respond_to Imports::Rubyandrailsinfo::Helpers.new, :imported_title
    end
  end
end
