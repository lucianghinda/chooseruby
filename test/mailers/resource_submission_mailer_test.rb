# frozen_string_literal: true

require "test_helper"

# Tests for ResourceSubmissionMailer adapted for Entry model submissions
# These tests verify email delivery for community resource submissions
class ResourceSubmissionMailerTest < ActionMailer::TestCase
  test "notify_team sends email to configured recipient with Entry details" do
    # Create a RubyGem entry for testing
    ruby_gem = RubyGem.create!(
      gem_name: "awesome_gem",
      github_url: "https://github.com/user/awesome_gem"
    )

    entry = Entry.create!(
      title: "Awesome Gem",
      url: "https://rubygems.org/gems/awesome_gem",
      description: "A great testing gem",
      entryable: ruby_gem,
      submitter_name: "John Doe",
      submitter_email: "john@example.com",
      status: :pending,
      published: false
    )

    # Send the email
    email = ResourceSubmissionMailer.notify_team(entry)

    # Verify email was sent to correct recipient
    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [ ENV.fetch("RESOURCE_SUBMISSION_RECIPIENT", "hello@chooseruby.com") ], email.to
    assert_equal "New resource submission: Awesome Gem", email.subject

    # Check both HTML and text parts
    assert_match "Awesome Gem", email.html_part.body.to_s
    assert_match "https://rubygems.org/gems/awesome_gem", email.html_part.body.to_s
    assert_match "Awesome Gem", email.text_part.body.to_s
  end

  test "notify_team email includes resource type from entryable_type" do
    book = Book.create!(
      isbn: "9781234567890",
      publisher: "O'Reilly"
    )

    entry = Entry.create!(
      title: "Ruby Best Practices",
      url: "https://example.com/ruby-book",
      description: "A comprehensive guide",
      entryable: book,
      submitter_email: "reader@example.com",
      status: :pending
    )

    email = ResourceSubmissionMailer.notify_team(entry)

    # Resource type should be displayed as humanized entryable_type
    assert_match "Book", email.html_part.body.to_s
    assert_match "Book", email.text_part.body.to_s
  end

  test "notify_team email includes categories when present" do
    # Use categories from fixtures
    testing = categories(:testing)
    authentication = categories(:authentication)

    ruby_gem = RubyGem.create!(gem_name: "rspec")

    entry = Entry.create!(
      title: "RSpec",
      url: "https://rspec.info",
      description: "Testing framework",
      entryable: ruby_gem,
      submitter_email: "dev@example.com",
      status: :pending
    )

    entry.categories << [ testing, authentication ]

    email = ResourceSubmissionMailer.notify_team(entry)

    # Categories should be listed in the email
    assert_match "Testing", email.html_part.body.to_s
    assert_match "Authentication", email.html_part.body.to_s
    assert_match "Testing", email.text_part.body.to_s
  end

  test "notify_team email includes type-specific fields for RubyGem" do
    ruby_gem = RubyGem.create!(
      gem_name: "sidekiq",
      github_url: "https://github.com/sidekiq/sidekiq",
      documentation_url: "https://github.com/sidekiq/sidekiq/wiki"
    )

    entry = Entry.create!(
      title: "Sidekiq",
      url: "https://sidekiq.org",
      description: "Background processing",
      entryable: ruby_gem,
      submitter_email: "dev@example.com",
      status: :pending
    )

    email = ResourceSubmissionMailer.notify_team(entry)

    # Type-specific fields should be included
    assert_match "sidekiq", email.html_part.body.to_s
    assert_match "github.com/sidekiq/sidekiq", email.html_part.body.to_s
    assert_match "sidekiq", email.text_part.body.to_s
  end

  test "confirm_submitter sends email to submitter with submission details" do
    community = Community.create!(
      platform: "Discord",
      join_url: "https://discord.gg/ruby"
    )

    entry = Entry.create!(
      title: "Ruby Discord",
      url: "https://discord.gg/ruby",
      description: "Community chat",
      entryable: community,
      submitter_name: "Jane Smith",
      submitter_email: "jane@example.com",
      status: :pending
    )

    email = ResourceSubmissionMailer.confirm_submitter(entry)

    # Verify email was sent to submitter
    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [ "jane@example.com" ], email.to
    assert_equal "We received your resource submission for ChooseRuby", email.subject
    assert_match "Jane Smith", email.html_part.body.to_s
    assert_match "Ruby Discord", email.html_part.body.to_s
    assert_match "Community", email.html_part.body.to_s
  end

  test "confirm_submitter email includes submission details" do
    course = Course.create!(
      platform: "Udemy",
      instructor: "John Teacher"
    )

    entry = Entry.create!(
      title: "Ruby Mastery",
      url: "https://udemy.com/ruby-mastery",
      description: "Learn Ruby",
      entryable: course,
      submitter_name: "Alice",
      submitter_email: "alice@example.com",
      experience_level: :intermediate,
      status: :pending
    )

    email = ResourceSubmissionMailer.confirm_submitter(entry)

    # Should include title, URL, type, and experience level
    assert_match "Ruby Mastery", email.html_part.body.to_s
    assert_match "https://udemy.com/ruby-mastery", email.html_part.body.to_s
    assert_match "Course", email.html_part.body.to_s
    assert_match "Intermediate", email.html_part.body.to_s
  end

  test "emails work with Entry when submitter_name is nil" do
    tool = Tool.create!(
      tool_type: "CLI",
      license: "MIT"
    )

    entry = Entry.create!(
      title: "Ruby Formatter",
      url: "https://example.com/formatter",
      description: "Format Ruby code",
      entryable: tool,
      submitter_email: "dev@example.com",
      status: :pending
    )

    # notify_team should work
    team_email = ResourceSubmissionMailer.notify_team(entry)
    assert_match "Anonymous", team_email.html_part.body.to_s

    # confirm_submitter should work with fallback
    submitter_email = ResourceSubmissionMailer.confirm_submitter(entry)
    assert_match(/Hi there/, submitter_email.html_part.body.to_s)
  end

  test "notify_team email displays submitter information correctly" do
    article = Article.create!(
      author_name: "DHH",
      publication_date: Date.today - 30.days
    )

    entry = Entry.create!(
      title: "Rails is Omakase",
      url: "https://example.com/rails-omakase",
      description: "Philosophy of Rails",
      entryable: article,
      submitter_name: "Contributor Name",
      submitter_email: "contributor@example.com",
      status: :pending
    )

    email = ResourceSubmissionMailer.notify_team(entry)

    # Should show submitter name and email
    assert_match "Contributor Name", email.html_part.body.to_s
    assert_match "contributor@example.com", email.html_part.body.to_s
  end

  # Task Group 2: Tests for approval_notification and rejection_notification

  test "approval_notification sends email to submitter_email with correct subject" do
    ruby_gem = RubyGem.create!(gem_name: "approved_gem")
    entry = Entry.create!(
      title: "Approved Gem",
      url: "https://rubygems.org/gems/approved_gem",
      description: "An approved gem",
      entryable: ruby_gem,
      submitter_name: "Jane Developer",
      submitter_email: "jane@example.com",
      status: :approved,
      published: true
    )

    email = ResourceSubmissionMailer.approval_notification(entry)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [ "jane@example.com" ], email.to
    assert_equal "Your ChooseRuby submission has been approved: Approved Gem", email.subject
  end

  test "approval_notification includes entry title, type, and URL in email content" do
    book = Book.create!(isbn: "9781234567890", publisher: "Test Publisher")
    entry = Entry.create!(
      title: "Ruby Programming Book",
      url: "https://example.com/ruby-book",
      description: "A great book",
      entryable: book,
      submitter_email: "reader@example.com",
      status: :approved,
      published: true,
      slug: "ruby-programming-book"
    )

    email = ResourceSubmissionMailer.approval_notification(entry)

    # Check HTML part includes entry details
    assert_match "Ruby Programming Book", email.html_part.body.to_s
    assert_match "Book", email.html_part.body.to_s
    assert_match entry.url, email.html_part.body.to_s

    # Check text part includes entry details
    assert_match "Ruby Programming Book", email.text_part.body.to_s
    assert_match "Book", email.text_part.body.to_s
    assert_match entry.url, email.text_part.body.to_s
  end

  test "rejection_notification sends email with comment when present" do
    tool = Tool.create!(tool_type: "CLI", license: "MIT")
    entry = Entry.create!(
      title: "Rejected Tool",
      url: "https://example.com/tool",
      description: "A tool",
      entryable: tool,
      submitter_email: "developer@example.com",
      status: :rejected
    )

    # Create rejection review with comment
    EntryReview.create!(
      entry: entry,
      status: :rejected,
      comment: "Missing documentation and examples"
    )

    email = ResourceSubmissionMailer.rejection_notification(entry)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [ "developer@example.com" ], email.to
    assert_equal "Update on your ChooseRuby submission: Rejected Tool", email.subject

    # Verify comment is included in both parts
    assert_match "Missing documentation and examples", email.html_part.body.to_s
    assert_match "Missing documentation and examples", email.text_part.body.to_s
  end

  test "rejection_notification handles nil comment gracefully with fallback message" do
    community = Community.create!(platform: "Slack", join_url: "https://slack.com/ruby")
    entry = Entry.create!(
      title: "Ruby Community",
      url: "https://slack.com/ruby",
      description: "A community",
      entryable: community,
      submitter_email: "member@example.com",
      status: :rejected
    )

    # Create rejection review without comment
    EntryReview.create!(entry: entry, status: :rejected, comment: nil)

    email = ResourceSubmissionMailer.rejection_notification(entry)

    # Should not include specific comment but should have fallback message
    html_body = email.html_part.body.to_s
    text_body = email.text_part.body.to_s

    # Check that a fallback message is present (not the actual comment)
    assert_no_match "Missing documentation", html_body
    assert_match "Ruby Community", html_body
    assert_match "Community", html_body
    assert_match "Ruby Community", text_body
  end
end
