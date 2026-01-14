# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/resource_submission_mailer
class ResourceSubmissionMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/resource_submission_mailer/approval_notification
  def approval_notification
    # Create a sample approved entry with published status
    ruby_gem = RubyGem.new(
      gem_name: "amazing_gem",
      github_url: "https://github.com/user/amazing_gem"
    )

    entry = Entry.new(
      id: 1,
      title: "Amazing Ruby Gem",
      url: "https://rubygems.org/gems/amazing_gem",
      description: "An amazing gem for Ruby developers",
      entryable: ruby_gem,
      submitter_name: "Jane Developer",
      submitter_email: "jane@example.com",
      status: :approved,
      published: true,
      slug: "amazing-ruby-gem"
    )

    ResourceSubmissionMailer.approval_notification(entry)
  end

  # Preview this email at http://localhost:3000/rails/mailers/resource_submission_mailer/rejection_notification_with_comment
  def rejection_notification_with_comment
    # Create a sample rejected entry with a review comment
    book = Book.new(
      isbn: "9781234567890",
      publisher: "Tech Books Publishing"
    )

    entry = Entry.new(
      id: 2,
      title: "Ruby Programming Guide",
      url: "https://example.com/ruby-guide",
      description: "A comprehensive guide to Ruby",
      entryable: book,
      submitter_name: "John Author",
      submitter_email: "john@example.com",
      status: :rejected,
      published: false,
      slug: "ruby-programming-guide"
    )

    # Create a sample review with comment
    review = EntryReview.new(
      entry: entry,
      status: :rejected,
      comment: "Thank you for your submission. Unfortunately, this resource lacks sufficient detail and examples. We'd encourage you to expand the content and resubmit."
    )

    # Mock the entry_reviews association to return the review
    entry.define_singleton_method(:entry_reviews) do
      Class.new do
        def self.where(conditions)
          self
        end

        def self.last
          EntryReview.new(
            status: :rejected,
            comment: "Thank you for your submission. Unfortunately, this resource lacks sufficient detail and examples. We'd encourage you to expand the content and resubmit."
          )
        end
      end
    end

    ResourceSubmissionMailer.rejection_notification(entry)
  end

  # Preview this email at http://localhost:3000/rails/mailers/resource_submission_mailer/rejection_notification_without_comment
  def rejection_notification_without_comment
    # Create a sample rejected entry without a review comment
    tool = Tool.new(
      tool_type: "CLI",
      license: "MIT"
    )

    entry = Entry.new(
      id: 3,
      title: "Ruby Development Tool",
      url: "https://example.com/ruby-tool",
      description: "A useful development tool",
      entryable: tool,
      submitter_name: "Alice Developer",
      submitter_email: "alice@example.com",
      status: :rejected,
      published: false,
      slug: "ruby-development-tool"
    )

    # Mock the entry_reviews association to return nil comment
    entry.define_singleton_method(:entry_reviews) do
      Class.new do
        def self.where(conditions)
          self
        end

        def self.last
          EntryReview.new(
            status: :rejected,
            comment: nil
          )
        end
      end
    end

    ResourceSubmissionMailer.rejection_notification(entry)
  end
end
