# frozen_string_literal: true

require "test_helper"

class FtsQueryTest < ActiveSupport::TestCase
  test "quoted phrases stay exact while ordinary words use prefixes" do
    query = FtsQuery.new('ruby "web framework"')

    assert_equal 'ruby* "web framework"', query.call
    assert_equal 'ruby* "web framework"', query.call
  end

  test "blank and punctuation-only words contribute no search terms" do
    assert_empty FtsQuery.new(" ").call
    assert_equal "ruby*", FtsQuery.new("ruby** (-)").call
  end

  test "callers can also remove apostrophes from search terms" do
    assert_equal "Rubys*", FtsQuery.new("Ruby's", ignored_characters: /[()\-']/).call
  end
end
