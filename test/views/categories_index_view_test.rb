# frozen_string_literal: true

require "test_helper"

class CategoriesIndexViewTest < ActionDispatch::IntegrationTest
  test "category index displays resource count for each category" do
    category = categories(:testing)

    # Create visible entries for the testing category
    2.times do |i|
      entry = Entry.create!(
        title: "Test Entry #{i + 1}",
        url: "https://example.com/test-#{i + 1}",
        published: true,
        status: :approved
      )
      CategoriesEntry.create!(category: category, entry: entry)
    end

    # Create a non-visible entry (should not be counted)
    unpublished_entry = Entry.create!(
      title: "Unpublished Entry",
      url: "https://example.com/unpublished",
      published: false,
      status: :approved
    )
    CategoriesEntry.create!(category: category, entry: unpublished_entry)

    get categories_path

    assert_response :success
    assert_select "article" do
      assert_select "h3", text: "Testing"
      # Check that the resource count is displayed (should be 2 visible entries)
      assert_select "p.text-sm", text: /2 resources?/
    end
  end
end
