# frozen_string_literal: true

require "test_helper"

class FtsIndexTest < ActiveSupport::TestCase
  AUTHOR_ID = 987_654

  setup do
    @index = FtsIndex.new(table: "authors_fts", key_column: "author_id", key: AUTHOR_ID)
  end

  test "replace indexes the record under its own key" do
    @index.replace(name: "Grace Hopper")

    assert_equal [ "Grace Hopper" ], indexed_names
  end

  test "replace leaves only the values of the latest sync behind" do
    @index.replace(name: "Grace Hopper")
    @index.replace(name: "Grace B. Hopper")

    assert_equal [ "Grace B. Hopper" ], indexed_names
  end

  test "delete takes the record out of the index" do
    @index.replace(name: "Grace Hopper")
    @index.delete

    assert_empty indexed_names
  end

  private

  def indexed_names
    ActiveRecord::Base.connection.select_values(
      ActiveRecord::Base.sanitize_sql_array([ "SELECT name FROM authors_fts WHERE author_id = ?", AUTHOR_ID ])
    )
  end
end
