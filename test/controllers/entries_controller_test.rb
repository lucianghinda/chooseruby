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
    assert_not entry.published
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
    assert entry.entryable.is_official
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

  test "POST create stores the entry when the submitted author no longer exists" do
    missing_author_id = Author.maximum(:id).to_i + 1

    assert_difference("Entry.count", 1) do
      post entries_path, params: {
        entry: {
          title: "Entry with a stale author reference",
          url: "https://example.com/stale-author",
          description: "Test description",
          resource_type: "RubyGem",
          submitter_email: "john@example.com",
          gem_name: "stale-author-gem",
          author_id: missing_author_id
        }
      }
    end

    assert_empty Entry.last.authors
    assert_redirected_to entry_success_path
  end

  test "POST create leaves the price unset for a Course submitted without one" do
    assert_difference([ "Entry.count", "Course.count" ], 1) do
      post entries_path, params: {
        entry: {
          title: "Free Ruby Course",
          url: "https://example.com/free-course",
          description: "Test description",
          resource_type: "Course",
          submitter_email: "john@example.com",
          platform: "YouTube",
          instructor: "Jane Doe",
          is_free: true
        }
      }
    end

    assert_nil Entry.last.entryable.price_cents
    assert_redirected_to entry_success_path
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

  test "POST create with Tutorial type creates Entry and Tutorial" do
    assert_difference([ "Entry.count", "Tutorial.count" ], 1) do
      post entries_path, params: {
        entry: {
          title: "Build a Rails App",
          url: "https://example.com/tutorial",
          description: "Step by step tutorial",
          resource_type: "Tutorial",
          submitter_email: "submitter@example.com",
          platform: "GoRails",
          author_name: "Tom Tutorialwriter",
          reading_time_minutes: 15
        }
      }
    end

    entry = Entry.last
    assert_equal "Tutorial", entry.entryable_type
    assert_equal "Tom Tutorialwriter", entry.entryable.author_name
    assert_equal 15, entry.entryable.reading_time_minutes
  end

  test "POST create with Article type creates Entry and Article" do
    assert_difference([ "Entry.count", "Article.count" ], 1) do
      post entries_path, params: {
        entry: {
          title: "Why Ruby Still Wins",
          url: "https://example.com/article",
          description: "An opinion piece",
          resource_type: "Article",
          submitter_email: "submitter@example.com",
          platform: "Dev.to",
          author_name: "Ada Articlewriter",
          reading_time_minutes: 7
        }
      }
    end

    entry = Entry.last
    assert_equal "Article", entry.entryable_type
    assert_equal "Ada Articlewriter", entry.entryable.author_name
    assert_equal "Dev.to", entry.entryable.platform
  end

  test "POST create with Tool type creates Entry and Tool" do
    assert_difference([ "Entry.count", "Tool.count" ], 1) do
      post entries_path, params: {
        entry: {
          title: "RuboCop",
          url: "https://example.com/tool",
          description: "A Ruby linter",
          resource_type: "Tool",
          submitter_email: "submitter@example.com",
          tool_type: "Linter",
          license: "MIT",
          is_open_source: true,
          github_url: "https://github.com/rubocop/rubocop"
        }
      }
    end

    entry = Entry.last
    assert_equal "Tool", entry.entryable_type
    assert_equal "Linter", entry.entryable.tool_type
    assert_equal "MIT", entry.entryable.license
    assert entry.entryable.is_open_source
  end

  test "POST create with Podcast type creates Entry and Podcast" do
    assert_difference([ "Entry.count", "Podcast.count" ], 1) do
      post entries_path, params: {
        entry: {
          title: "Remote Ruby",
          url: "https://example.com/podcast",
          description: "A Ruby podcast",
          resource_type: "Podcast",
          submitter_email: "submitter@example.com",
          host: "Pat Podcasthost",
          episode_count: 120,
          frequency: "Weekly",
          rss_feed_url: "https://example.com/feed.xml"
        }
      }
    end

    entry = Entry.last
    assert_equal "Podcast", entry.entryable_type
    assert_equal "Pat Podcasthost", entry.entryable.host
    assert_equal 120, entry.entryable.episode_count
  end

  test "POST create converts a submitted Course price into cents" do
    post entries_path, params: {
      entry: {
        title: "Paid Ruby Course",
        url: "https://example.com/paid-course",
        description: "Test description",
        resource_type: "Course",
        submitter_email: "john@example.com",
        platform: "Avo Academy",
        instructor: "Jane Doe",
        currency: "USD",
        price: "49.99"
      }
    }

    assert_equal 4999, Entry.last.entryable.price_cents
    assert_redirected_to entry_success_path
  end

  test "POST create rejects a submission filed under more than three categories" do
    category_ids = Category.order(:id).limit(4).pluck(:id)
    assert_equal 4, category_ids.size

    assert_no_difference("Entry.count") do
      post entries_path, params: {
        entry: {
          title: "Over-categorised Resource",
          url: "https://example.com/over-categorised",
          description: "Test description",
          resource_type: "RubyGem",
          submitter_email: "submitter@example.com",
          gem_name: "over-categorised-gem",
          category_ids: category_ids
        }
      }
    end

    assert_response :unprocessable_entity
    assert_match "You can select a maximum of 3 categories", response.body
  end

  test "POST create attaches the submitted author to the entry" do
    author = Author.create!(name: "Submitting Author", status: :approved)

    post entries_path, params: {
      entry: {
        title: "Entry with an author",
        url: "https://example.com/with-author",
        description: "Test description",
        resource_type: "RubyGem",
        submitter_email: "john@example.com",
        gem_name: "with-author-gem",
        author_id: author.id
      }
    }

    assert_equal [ author ], Entry.last.authors.to_a
    assert_redirected_to entry_success_path
  end

  test "POST create refuses to build an entryable for an unknown resource type" do
    error = assert_raises(ArgumentError) do
      post entries_path, params: {
        entry: {
          title: "Mystery Resource",
          url: "https://example.com/mystery",
          description: "Test description",
          resource_type: "Grimoire",
          submitter_email: "submitter@example.com"
        }
      }
    end

    assert_equal "Unknown resource type: Grimoire", error.message
    assert_equal 0, Entry.where(title: "Mystery Resource").count
  end

  # ====================================================================
  # Typeahead suggestion tests
  # ====================================================================

  test "GET suggestions returns an empty body for a query below two characters" do
    get entries_suggestions_path, params: { q: "p" }

    assert_response :success
    assert_empty response.body.strip
  end

  test "GET suggestions lists matching entries, categories and types" do
    category = Category.create!(name: "Podcasting", slug: "podcasting")
    entry = Entry.create!(
      title: "Podcast Playbook",
      url: "https://example.com/podcast-playbook",
      description: "A guide to Ruby podcasts",
      status: :approved,
      published: true
    )

    get entries_suggestions_path, params: { q: "podcast" }

    assert_response :success
    assert_match entry.title, response.body
    assert_match category.name, response.body
    assert_match "Podcasts", response.body
  end

  test "GET suggestions hides entries that are not visible" do
    Entry.create!(
      title: "Unapproved Podcast Draft",
      url: "https://example.com/unapproved-podcast",
      description: "Still pending review",
      status: :pending,
      published: false,
      submitter_email: "draft@example.com"
    )

    get entries_suggestions_path, params: { q: "podcast" }

    assert_response :success
    assert_no_match(/Unapproved Podcast Draft/, response.body)
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
