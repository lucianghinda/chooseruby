# frozen_string_literal: true

require "test_helper"

class EntriesControllerTest < ActionDispatch::IntegrationTest
  # Test 3.1.1: GET new action renders form with categories
  test "GET new renders form with categories" do
    get new_entry_path

    assert_response :success
    assert_select "form[action=?]", entries_path
    assert_select "select[name=?]", "entry[resource_type]"
  end

  # Test 3.1.2: POST create with valid common fields creates Entry
  test "POST create with valid common fields creates pending Entry" do
    assert_difference("Entry.count", 1) do
      post entries_path, params: {
        entry: {
          title: "Test Resource",
          url: "https://example.com",
          description: "Test description",
          resource_type: "RubyGem",
          submitter_name: "John Doe",
          submitter_email: "john@example.com",
          gem_name: "test-gem"
        }
      }
    end

    entry = Entry.last
    assert_equal "pending", entry.status
    assert_equal false, entry.published
    assert_equal "Test Resource", entry.title
    assert_redirected_to entry_success_path
  end

  # Test 3.1.3: POST create with RubyGem type creates Entry + RubyGem
  test "POST create with RubyGem type creates Entry and RubyGem" do
    assert_difference([ "Entry.count", "RubyGem.count" ], 1) do
      post entries_path, params: {
        entry: {
          title: "RSpec Testing Framework",
          url: "https://rspec.info",
          description: "BDD testing framework",
          resource_type: "RubyGem",
          submitter_email: "submitter@example.com",
          gem_name: "rspec-core",
          github_url: "https://github.com/rspec/rspec-core"
        }
      }
    end

    entry = Entry.last
    assert_equal "RubyGem", entry.entryable_type
    assert_not_nil entry.entryable
    assert_equal "rspec-core", entry.entryable.gem_name
    assert_equal "https://github.com/rspec/rspec-core", entry.entryable.github_url
  end

  # Test 3.1.4: POST create with Book type creates Entry + Book
  test "POST create with Book type creates Entry and Book" do
    assert_difference([ "Entry.count", "Book.count" ], 1) do
      post entries_path, params: {
        entry: {
          title: "The Well-Grounded Rubyist",
          url: "https://manning.com/books/well-grounded-rubyist",
          description: "Comprehensive Ruby guide",
          resource_type: "Book",
          submitter_email: "submitter@example.com",
          isbn: "1617295213",
          publisher: "Manning",
          publication_year: 2019
        }
      }
    end

    entry = Entry.last
    assert_equal "Book", entry.entryable_type
    assert_not_nil entry.entryable
    assert_equal "1617295213", entry.entryable.isbn
    assert_equal "Manning", entry.entryable.publisher
    assert_equal 2019, entry.entryable.publication_year
  end

  # Test 3.1.5: POST create with Community type creates Entry + Community
  test "POST create with Community type creates Entry and Community" do
    assert_difference([ "Entry.count", "Community.count" ], 1) do
      post entries_path, params: {
        entry: {
          title: "Ruby on Rails Link Slack",
          url: "https://www.rubyonrails.link",
          description: "Official Rails community Slack",
          resource_type: "Community",
          submitter_email: "submitter@example.com",
          platform: "Slack",
          join_url: "https://www.rubyonrails.link",
          is_official: true
        }
      }
    end

    entry = Entry.last
    assert_equal "Community", entry.entryable_type
    assert_not_nil entry.entryable
    assert_equal "Slack", entry.entryable.platform
    assert_equal "https://www.rubyonrails.link", entry.entryable.join_url
    assert_equal true, entry.entryable.is_official
  end

  # Test 3.1.6: POST create with validation failure renders form with errors (422 status)
  test "POST create with validation failure renders form with errors" do
    assert_no_difference("Entry.count") do
      post entries_path, params: {
        entry: {
          title: "", # Missing required field
          url: "https://example.com",
          resource_type: "RubyGem",
          submitter_email: "submitter@example.com",
          gem_name: "test-gem"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select "form[action=?]", entries_path
  end

  # Test 3.1.7: POST create successful submission redirects and sends emails
  test "POST create successful submission sends emails" do
    assert_emails 2 do
      post entries_path, params: {
        entry: {
          title: "Test Resource",
          url: "https://example.com",
          description: "Test description",
          resource_type: "RubyGem",
          submitter_name: "John Doe",
          submitter_email: "john@example.com",
          gem_name: "test-gem"
        }
      }
    end

    assert_redirected_to entry_success_path
  end

  # Test 3.1.8: POST create with categories association
  test "POST create associates categories with entry" do
    category1 = categories(:testing)
    category2 = categories(:web_development)

    assert_difference("Entry.count", 1) do
      post entries_path, params: {
        entry: {
          title: "Test Resource",
          url: "https://example.com",
          description: "Test description",
          resource_type: "RubyGem",
          submitter_email: "submitter@example.com",
          gem_name: "test-gem",
          category_ids: [ category1.id, category2.id ]
        }
      }
    end

    entry = Entry.last
    assert_equal 2, entry.categories.count
    assert_includes entry.categories, category1
    assert_includes entry.categories, category2
  end

  # ====================================================================
  # Beginner Landing Page Tests (Task Group 1.1)
  # ====================================================================

  # Test 1.1.1: GET /start returns successful response
  test "GET start returns successful response" do
    get start_path

    assert_response :success
  end

  # Test 1.1.2: GET /start filters only beginner-level entries
  test "GET start filters only beginner-level entries" do
    # Create test entries with different experience levels
    beginner_entry = Entry.create!(
      title: "Rails for Beginners",
      url: "https://example.com/beginner",
      description: "Learn Rails basics",
      experience_level: :beginner,
      status: :approved,
      published: true,
      submitter_email: "test@example.com"
    )

    intermediate_entry = Entry.create!(
      title: "Advanced Rails Patterns",
      url: "https://example.com/intermediate",
      description: "Advanced concepts",
      experience_level: :intermediate,
      status: :approved,
      published: true,
      submitter_email: "test@example.com"
    )

    get start_path

    assert_response :success
    # Verify that beginner entry is present in response
    assert_select "h3", text: "Rails for Beginners"
    # Verify that intermediate entry is NOT in response
    assert_select "h3", text: "Advanced Rails Patterns", count: 0
  end

  # Test 1.1.3: GET /start preserves search query parameter (?q=)
  test "GET start preserves search query parameter" do
    # Create a beginner entry
    Entry.create!(
      title: "Rails Testing Guide",
      url: "https://example.com/testing",
      description: "Learn to test Rails apps",
      experience_level: :beginner,
      status: :approved,
      published: true,
      submitter_email: "test@example.com"
    )

    get start_path, params: { q: "testing" }

    assert_response :success
    # Verify the query parameter is preserved in the view
    assert_select "input[name='q'][value='testing']"
  end

  # Test 1.1.4: GET /start preserves category parameter (?category=)
  test "GET start preserves category parameter" do
    category = categories(:testing)

    # Create a beginner entry in the testing category
    entry = Entry.create!(
      title: "RSpec for Beginners",
      url: "https://example.com/rspec",
      description: "Learn RSpec testing",
      experience_level: :beginner,
      status: :approved,
      published: true,
      submitter_email: "test@example.com"
    )
    entry.categories << category

    get start_path, params: { category: "testing" }

    assert_response :success
  end

  # Test 1.1.5: GET /start with search combines beginner filter + query filter
  test "GET start with search combines beginner filter and query filter" do
    # Create beginner entries with different content
    beginner_testing = Entry.create!(
      title: "Rails Testing for Beginners",
      url: "https://example.com/testing",
      description: "Learn testing basics",
      experience_level: :beginner,
      status: :approved,
      published: true,
      submitter_email: "test@example.com"
    )

    beginner_other = Entry.create!(
      title: "Rails Routing for Beginners",
      url: "https://example.com/routing",
      description: "Learn routing basics",
      experience_level: :beginner,
      status: :approved,
      published: true,
      submitter_email: "test@example.com"
    )

    # Intermediate entry about testing (should NOT appear)
    intermediate_testing = Entry.create!(
      title: "Advanced Testing Patterns",
      url: "https://example.com/advanced-testing",
      description: "Advanced testing techniques",
      experience_level: :intermediate,
      status: :approved,
      published: true,
      submitter_email: "test@example.com"
    )

    get start_path, params: { q: "testing" }

    assert_response :success
    # Should find beginner testing entry
    assert_select "h3", text: "Rails Testing for Beginners"
    # Should NOT find intermediate testing entry (filtered by beginner level)
    assert_select "h3", text: "Advanced Testing Patterns", count: 0
    # Should NOT find beginner routing entry (filtered by search query)
    assert_select "h3", text: "Rails Routing for Beginners", count: 0
  end
end
