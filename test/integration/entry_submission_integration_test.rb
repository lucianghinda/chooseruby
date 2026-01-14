# frozen_string_literal: true

require "test_helper"

# Integration tests for Community Resource Submission Form feature
# These tests fill critical coverage gaps by testing complete end-to-end workflows
class EntrySubmissionIntegrationTest < ActionDispatch::IntegrationTest
  setup do
    # Clear rate limiting data before each test
    Rack::Attack.cache.store.clear if defined?(Rack::Attack)
  end

  # Test 1: End-to-end submission flow for Course type (representative of types not tested in controller)
  test "complete submission flow creates Course entry and sends emails" do
    category = categories(:testing)

    assert_difference [ "Entry.count", "Course.count" ], 1 do
      assert_emails 2 do
        post entries_path, params: {
          entry: {
            title: "Ruby on Rails Mastery",
            url: "https://udemy.com/ruby-mastery",
            description: "Complete Ruby on Rails course",
            resource_type: "Course",
            submitter_name: "Course Creator",
            submitter_email: "creator@example.com",
            category_ids: [ category.id ],
            experience_level: "intermediate",
            # Course-specific fields
            platform: "Udemy",
            instructor: "John Doe",
            duration_hours: 40,
            price: "99.99", # Should be converted to cents
            currency: "USD",
            is_free: false,
            enrollment_url: "https://udemy.com/ruby-mastery/enroll"
          }
        }
      end
    end

    entry = Entry.last
    assert_equal "pending", entry.status
    assert_equal false, entry.published
    assert_equal "Course", entry.entryable_type
    assert_equal "Udemy", entry.entryable.platform
    assert_equal "John Doe", entry.entryable.instructor
    assert_equal 40, entry.entryable.duration_hours
    assert_equal 9999, entry.entryable.price_cents # Converted from 99.99 dollars
    assert_equal "USD", entry.entryable.currency
    assert_equal false, entry.entryable.is_free
    assert_redirected_to entry_success_path
  end

  # Test 2: Transaction rollback when Entry validation fails (missing required fields)
  test "transaction rollback when Entry validation fails" do
    assert_no_difference [ "Entry.count", "RubyGem.count" ] do
      post entries_path, params: {
        entry: {
          title: "", # Missing required title - should fail Entry validation
          url: "https://example.com",
          description: "Test",
          resource_type: "RubyGem",
          submitter_email: "test@example.com",
          gem_name: "test-gem"
        }
      }
    end

    assert_response :unprocessable_entity
    # Verify both Entry and RubyGem were not created
    assert_not RubyGem.exists?(gem_name: "test-gem")
  end

  # Test 3: Category limit validation (reject submissions with > 3 categories)
  test "rejects submission with more than 3 categories" do
    categories_list = [
      categories(:testing),
      categories(:web_development),
      categories(:authentication),
      Category.create!(name: "Fourth Category", slug: "fourth-category")
    ]

    assert_no_difference "Entry.count" do
      post entries_path, params: {
        entry: {
          title: "Too Many Categories",
          url: "https://example.com",
          description: "Test",
          resource_type: "RubyGem",
          submitter_email: "test@example.com",
          gem_name: "test-gem",
          category_ids: categories_list.map(&:id) # 4 categories - should fail
        }
      }
    end

    assert_response :unprocessable_entity
  end

  # Test 4: Author dual input - selecting existing author
  test "submission with existing author creates association via entries_authors" do
    author = Author.create!(name: "Test Author Integration", status: :approved)

    assert_difference "Entry.count", 1 do
      post entries_path, params: {
        entry: {
          title: "Entry with Existing Author",
          url: "https://example.com",
          description: "Test",
          resource_type: "RubyGem",
          submitter_email: "test@example.com",
          gem_name: "author-gem",
          author_id: author.id
        }
      }
    end

    entry = Entry.last
    assert_includes entry.authors, author
    assert_equal 1, entry.authors.count
  end

  # Test 5: Author dual input - manual text entry for Tutorial
  test "submission with manual author name stores in Tutorial author_name field" do
    assert_difference [ "Entry.count", "Tutorial.count" ], 1 do
      post entries_path, params: {
        entry: {
          title: "Tutorial with Manual Author",
          url: "https://example.com/tutorial",
          description: "Test tutorial",
          resource_type: "Tutorial",
          submitter_email: "test@example.com",
          # Tutorial-specific fields
          author_name: "Manual Author Name",
          reading_time_minutes: 15,
          publication_date: Date.today - 30.days,
          platform: "Dev.to"
        }
      }
    end

    entry = Entry.last
    assert_equal "Tutorial", entry.entryable_type
    assert_equal "Manual Author Name", entry.entryable.author_name
    assert_equal 15, entry.entryable.reading_time_minutes
    assert_equal "Dev.to", entry.entryable.platform
  end

  # Test 6: Complete submission flow for Tool type
  test "complete submission flow creates Tool entry with all fields" do
    assert_difference [ "Entry.count", "Tool.count" ], 1 do
      post entries_path, params: {
        entry: {
          title: "Ruby Formatter Tool",
          url: "https://example.com/formatter",
          description: "Formats Ruby code beautifully",
          resource_type: "Tool",
          submitter_email: "dev@example.com",
          image_url: "https://example.com/tool-logo.png",
          # Tool-specific fields
          tool_type: "CLI",
          github_url: "https://github.com/user/formatter",
          documentation_url: "https://docs.example.com",
          license: "MIT",
          is_open_source: true
        }
      }
    end

    entry = Entry.last
    assert_equal "Tool", entry.entryable_type
    assert_equal "CLI", entry.entryable.tool_type
    assert_equal "https://github.com/user/formatter", entry.entryable.github_url
    assert_equal "MIT", entry.entryable.license
    assert_equal true, entry.entryable.is_open_source
  end

  # Test 7: Complete submission flow for Podcast type
  test "complete submission flow creates Podcast entry" do
    assert_difference [ "Entry.count", "Podcast.count" ], 1 do
      post entries_path, params: {
        entry: {
          title: "Ruby Rogues",
          url: "https://rubyrogues.com",
          description: "Ruby discussion podcast",
          resource_type: "Podcast",
          submitter_email: "listener@example.com",
          # Podcast-specific fields
          host: "Panel of Ruby experts",
          episode_count: 500,
          frequency: "Weekly",
          rss_feed_url: "https://rubyrogues.com/feed.xml",
          spotify_url: "https://spotify.com/show/ruby-rogues",
          apple_podcasts_url: "https://podcasts.apple.com/ruby-rogues"
        }
      }
    end

    entry = Entry.last
    assert_equal "Podcast", entry.entryable_type
    assert_equal "Panel of Ruby experts", entry.entryable.host
    assert_equal 500, entry.entryable.episode_count
    assert_equal "Weekly", entry.entryable.frequency
  end

  # Test 8: Complete submission flow for Article type
  test "complete submission flow creates Article entry" do
    assert_difference [ "Entry.count", "Article.count" ], 1 do
      post entries_path, params: {
        entry: {
          title: "Understanding Ruby Blocks",
          url: "https://blog.example.com/ruby-blocks",
          description: "Deep dive into Ruby blocks",
          resource_type: "Article",
          submitter_email: "writer@example.com",
          # Article-specific fields
          author_name: "Jane Writer",
          reading_time_minutes: 8,
          publication_date: Date.today - 7.days,
          platform: "Medium"
        }
      }
    end

    entry = Entry.last
    assert_equal "Article", entry.entryable_type
    assert_equal "Jane Writer", entry.entryable.author_name
    assert_equal 8, entry.entryable.reading_time_minutes
    assert_equal "Medium", entry.entryable.platform
  end

  # Test 9: Validation error preserves form state (category selections, field values)
  test "validation failure re-renders form with preserved field values" do
    category = categories(:testing)

    post entries_path, params: {
      entry: {
        title: "", # Invalid - empty title
        url: "https://example.com",
        description: "Test description",
        resource_type: "RubyGem",
        submitter_name: "Test User",
        submitter_email: "test@example.com",
        gem_name: "test-gem",
        category_ids: [ category.id ]
      }
    }

    assert_response :unprocessable_entity
    assert_select "form[action=?]", entries_path
    # Verify field values are preserved
    assert_select "input[name='entry[submitter_name]'][value='Test User']"
    assert_select "input[name='entry[submitter_email]'][value='test@example.com']"
    # Verify category selection is preserved
    assert_select "input[name='entry[category_ids][]'][value='#{category.id}'][checked='checked']"
  end

  # Test 10: Email notifications contain correct submission details for team and submitter
  test "email notifications include all submission details" do
    category = categories(:testing)

    perform_enqueued_jobs do
      post entries_path, params: {
        entry: {
          title: "Test Email Details",
          url: "https://example.com/test",
          description: "Testing email content",
          resource_type: "RubyGem",
          submitter_name: "Email Tester",
          submitter_email: "tester@example.com",
          gem_name: "email-test-gem",
          github_url: "https://github.com/test/gem",
          category_ids: [ category.id ]
        }
      }
    end

    # Check team notification email
    team_email = ActionMailer::Base.deliveries[-2]
    assert_equal [ ENV.fetch("RESOURCE_SUBMISSION_RECIPIENT", "hello@chooseruby.com") ], team_email.to
    assert_match "Test Email Details", team_email.html_part.body.to_s
    assert_match "RubyGem", team_email.html_part.body.to_s
    assert_match "email-test-gem", team_email.html_part.body.to_s
    assert_match category.name, team_email.html_part.body.to_s

    # Check submitter confirmation email
    submitter_email = ActionMailer::Base.deliveries.last
    assert_equal [ "tester@example.com" ], submitter_email.to
    assert_match "Email Tester", submitter_email.html_part.body.to_s
    assert_match "Test Email Details", submitter_email.html_part.body.to_s
  end
end
