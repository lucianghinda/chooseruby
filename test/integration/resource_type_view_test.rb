# frozen_string_literal: true

require "test_helper"

class ResourceTypeViewTest < ActionDispatch::IntegrationTest
  # ====================================================================
  # Resource Type Browse Page View Tests (Task Group 4.1)
  # ====================================================================

  setup do
    @testing_category = categories(:testing)
    @auth_category = categories(:authentication)

    # Create author for gem entries
    @author = Author.create!(
      name: "Test Author #{SecureRandom.hex(4)}",
      slug: "test-author-#{SecureRandom.hex(4)}",
      status: :approved
    )

    # Create a RubyGem entry with author
    @ruby_gem = RubyGem.create!(gem_name: "test-gem-#{SecureRandom.hex(4)}")
    @gem_entry = Entry.create!(
      title: "Test Gem",
      url: "https://example.com/test-gem",
      description: "A testing framework for Ruby",
      entryable: @ruby_gem,
      status: :approved,
      published: true,
      experience_level: :intermediate
    )
    @gem_entry.categories << @testing_category
    @gem_entry.authors << @author

    # Create a Book entry
    @book = Book.create!(
      publisher: "OReilly Media",
      publication_year: 2023,
      format: :both
    )
    @book_entry = Entry.create!(
      title: "Ruby Best Practices",
      url: "https://example.com/ruby-book",
      description: "Learn Ruby best practices",
      entryable: @book,
      status: :approved,
      published: true,
      experience_level: :advanced
    )
    @book_entry.categories << @testing_category
    @book_entry.authors << @author

    # Create a Course entry
    @course = Course.create!(
      platform: "Udemy",
      instructor: "John Instructor",
      duration_hours: 12.5
    )
    @course_entry = Entry.create!(
      title: "Complete Ruby Course",
      url: "https://example.com/ruby-course",
      description: "Master Ruby programming",
      entryable: @course,
      status: :approved,
      published: true,
      experience_level: :beginner
    )
    @course_entry.categories << @testing_category
  end

  # Test 4.1.1: View renders type-specific heading with emoji
  test "type browse page renders type-specific heading with emoji" do
    get resource_type_path("gems")

    assert_response :success
    assert_select "h1", text: /💎.*Ruby Gems Directory/
  end

  # Test 4.1.2: View shows entry count in subtitle
  test "type browse page shows entry count in subtitle" do
    # We have 1 gem entry from setup
    get resource_type_path("gems")

    assert_response :success
    # Should show count with type description
    assert_select "p", text: /1.*curated/i
  end

  # Test 4.1.3: View renders entry cards with correct metadata
  test "type browse page renders entry cards with type-specific metadata" do
    get resource_type_path("gems")

    assert_response :success
    # Should show gem entry
    assert_select "h3", text: "Test Gem"
    # Should show author metadata (from authors association for gems)
    assert_select "span", text: /by.*#{@author.name}/
  end

  # Test 4.1.4: View includes category filter sidebar
  test "type browse page includes category filter sidebar" do
    get resource_type_path("gems")

    assert_response :success
    assert_select "h2", text: "Categories"
    assert_select "a", text: @testing_category.name
  end

  # Test 4.1.5: View includes level filter buttons
  test "type browse page includes level filter buttons" do
    get resource_type_path("gems")

    assert_response :success
    assert_select "h2", text: "Experience level"
    assert_select "a", text: "All levels"
    assert_select "a", text: "Beginner"
    assert_select "a", text: "Intermediate"
    assert_select "a", text: "Advanced"
  end

  # Test 4.1.6: View includes search bar
  test "type browse page includes search bar" do
    get resource_type_path("gems")

    assert_response :success
    assert_select "input[type='text'][name='q']"
    assert_select "input[placeholder*='Search']"
  end

  # Test 4.1.7: Book metadata displays correctly
  test "type browse page shows book-specific metadata" do
    get resource_type_path("books")

    assert_response :success
    assert_select "h3", text: "Ruby Best Practices"
    # Book should show publisher and publication year
    response_body = response.body
    assert_match(/OReilly Media/, response_body)
    assert_match(/2023/, response_body)
  end

  # Test 4.1.8: Course metadata displays correctly
  test "type browse page shows course-specific metadata" do
    get resource_type_path("courses")

    assert_response :success
    assert_select "h3", text: "Complete Ruby Course"
    # Course should show platform and instructor
    response_body = response.body
    assert_match(/Udemy/, response_body)
  end
end
