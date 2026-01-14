# frozen_string_literal: true

require "application_system_test_case"

class DirectoryLinkBehaviorTest < ApplicationSystemTestCase
  setup do
    # Use category fixture
    @category = categories(:testing)

    # Create author for testing
    @author = Author.create!(name: "Directory Test Author", slug: "directory-test-author", status: :approved)

    # Create visible entries for testing
    @ruby_gem_1 = RubyGem.create!(gem_name: "directory-test-gem-1")
    @entry_1 = Entry.create!(
      title: "Directory Test Entry 1",
      description: "Test description 1",
      url: "https://example.com/entry1",
      entryable: @ruby_gem_1,
      status: :approved,
      published: true,
      slug: "directory-test-entry-1"
    )
    @entry_1.categories << @category
    @entry_1.authors << @author

    @ruby_gem_2 = RubyGem.create!(gem_name: "directory-test-gem-2")
    @entry_2 = Entry.create!(
      title: "Directory Test Entry 2",
      description: "Test description 2",
      url: "https://example.com/entry2",
      entryable: @ruby_gem_2,
      status: :approved,
      published: true,
      slug: "directory-test-entry-2"
    )
    @entry_2.categories << @category
    @entry_2.authors << @author
  end

  test "entry titles in directory listing link to resource detail page" do
    visit entries_path

    # Find the entry card link (the <a> wraps the entire card including the h3)
    entry_link = find("h3", text: "Directory Test Entry 1").ancestor("a")

    # Verify it links to the resource detail page (check path includes slug), not external URL
    assert_includes entry_link[:href], "/resources/directory-test-entry-1"
    assert_not_equal @entry_1.url, entry_link[:href]
  end

  test "entry titles in category pages link to resource detail page" do
    visit category_path(@category.slug)

    # Find the entry title link (link is inside the h3 on category pages)
    entry_link = find("h3", text: "Directory Test Entry 1").find("a")

    # Verify it links to the resource detail page (check path includes slug), not external URL
    assert_includes entry_link[:href], "/resources/directory-test-entry-1"
    assert_not_equal @entry_1.url, entry_link[:href]
  end

  test "author profile pages still link titles to external URL" do
    visit author_path(@author.slug)

    # Find the entry title link on author page (link is inside the h3 on author pages)
    entry_link = find("h3", text: "Directory Test Entry 1").find("a")

    # Verify it still links to external URL, not resource detail page
    assert_equal @entry_1.url, entry_link[:href]
    assert_not_includes entry_link[:href], "/resources/"

    # Verify it opens in new tab
    assert_equal "_blank", entry_link[:target]
    assert_equal "noopener", entry_link[:rel]
  end

  test "links have correct href format for resource detail pages" do
    visit entries_path

    # Check both entries (the <a> wraps the entire card including the h3)
    entry_1_link = find("h3", text: "Directory Test Entry 1").ancestor("a")
    entry_2_link = find("h3", text: "Directory Test Entry 2").ancestor("a")

    # Verify correct format /resources/:slug (checking the path portion)
    assert_includes entry_1_link[:href], "/resources/directory-test-entry-1"
    assert_includes entry_2_link[:href], "/resources/directory-test-entry-2"
  end
end
