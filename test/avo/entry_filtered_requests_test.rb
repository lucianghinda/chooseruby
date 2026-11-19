# frozen_string_literal: true

require "test_helper"

class AvoEntryFilteredRequestsTest < ActionDispatch::IntegrationTest
  setup do
    post session_url, params: { email_address: "admin@test.com", password: "password" }
    @category = Category.create!(name: "Filtered category")
    create_entry(title: "Matching beginner gem", entryable: RubyGem.new)
    create_entry(title: "Advanced book", experience_level: :advanced)
    create_entry(title: "Unpublished book", published: false)
    create_entry(title: "Uncategorized book", categories: [])
  end

  test "combined category visibility and experience filters render and paginate matching entries" do
    get "/avo/resources/entries", params: { encoded_filters: encoded_filters }

    assert_response :success
    assert_select "tbody tr", count: 1
    assert_select "tbody", text: /Matching beginner gem/
    assert_select "tbody", text: /Advanced book|Unpublished book|Uncategorized book/, count: 0
    assert_select ".pagy.info", text: "Displaying 1 item"
    assert_equal 1, controller.view_assigns.fetch("pagy").count
  end

  test "combined filters render an empty result when category has no matching entry" do
    empty_category = Category.create!(name: "Empty category")

    get "/avo/resources/entries", params: { encoded_filters: encoded_filters(category: empty_category) }

    assert_response :success
    assert_select "tbody tr", count: 0
    assert_select "body", text: /No record found/
    assert_equal 0, controller.view_assigns.fetch("pagy").count
  end

  private

  def encoded_filters(category: @category)
    Avo::Filters::BaseFilter.encode_filters(
      "Avo::Filters::EntryExperienceLevelFilter" => "beginner",
      "Avo::Filters::EntryPublishedFilter" => { "true" => true, "false" => false },
      "Avo::Filters::EntryCategoryFilter" => category.id.to_s
    )
  end

  def create_entry(**attributes)
    Entry.create!({ description: "Combined filter regression", url: "https://example.com/filter-request",
      entryable: Book.new, status: :approved, published: true, experience_level: :beginner,
      categories: [ @category ] }.merge(attributes))
  end
end
