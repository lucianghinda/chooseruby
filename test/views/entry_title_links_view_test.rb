# frozen_string_literal: true

require "test_helper"

class EntryTitleLinksViewTest < ActionDispatch::IntegrationTest
  setup do
    @category = categories(:testing)
    @author = Author.create!(name: "Directory Test Author", slug: "directory-test-author", status: :approved)
    @entry = Entry.create!(
      title: "Directory Test Entry",
      description: "Test description",
      url: "https://example.com/entry",
      entryable: RubyGem.create!(gem_name: "directory-test-gem"),
      status: :approved,
      published: true,
      slug: "directory-test-entry"
    )
    @entry.categories << @category
    @entry.authors << @author
  end

  test "directory listing cards link to the resource detail page" do
    get entries_path

    assert_select "a[href=?]", resource_path(@entry.slug) do
      assert_select "h3", text: @entry.title
    end
    assert_select "a[href=?]", @entry.url, count: 0
  end

  test "category page titles link to the resource detail page" do
    get category_path(@category.slug)

    assert_select "h3 a[href=?]", resource_path(@entry.slug), text: @entry.title
    assert_select "h3 a[href=?]", @entry.url, count: 0
  end

  test "author profile page titles link to the external URL in a new tab" do
    get author_path(@author.slug)

    assert_select "h3 a[href=?][target=_blank][rel=noopener]", @entry.url, text: @entry.title
    assert_select "h3 a[href=?]", resource_path(@entry.slug), count: 0
  end
end
