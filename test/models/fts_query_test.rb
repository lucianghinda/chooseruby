# frozen_string_literal: true

require "test_helper"

class FtsQueryTest < ActiveSupport::TestCase
  cover "FtsQuery*"

  test "wildcards a single word so that typing a prefix already matches" do
    assert_equal "matz*", FtsQuery.new("matz").to_s
  end

  test "wildcards every word of a multi word search" do
    assert_equal "david* hansson*", FtsQuery.new("david hansson").to_s
  end

  test "keeps a quoted phrase verbatim" do
    assert_equal '"Yukihiro Matsumoto"', FtsQuery.new('"Yukihiro Matsumoto"').to_s
  end

  test "combines wildcarded words with quoted phrases" do
    assert_equal 'david* "heinemeier hansson"', FtsQuery.new('david "heinemeier hansson"').to_s
  end

  test "restores every phrase of a search that carries more than one" do
    assert_equal '"web framework" "job board"', FtsQuery.new('"web framework" "job board"').to_s
  end

  test "drops the characters FTS5 would read as syntax" do
    assert_equal "test* alpha*", FtsQuery.new("test (alpha)").to_s
  end

  test "drops a word that is nothing but syntax" do
    assert_equal "rails*", FtsQuery.new("rails ()").to_s
  end

  test "does not wildcard a word that already ends in a wildcard" do
    assert_equal "rails*", FtsQuery.new("rails**").to_s
  end

  test "is empty for a blank search" do
    assert_equal "", FtsQuery.new("   ").to_s
  end

  test "is empty when there is no search at all" do
    assert_equal "", FtsQuery.new(nil).to_s
  end

  test "keeps apostrophes by default" do
    assert_equal "o'brien*", FtsQuery.new("o'brien").to_s
  end

  test "drops the extra characters it is asked to ignore" do
    assert_equal "Entr*", FtsQuery.new("Entr'", ignored_characters: /[()\-']/).to_s
  end

  test "leaves text that looks like one of its own phrase placeholders alone" do
    assert_equal "__PHRASE_0__", FtsQuery.new("__PHRASE_0__").to_s
  end
end
