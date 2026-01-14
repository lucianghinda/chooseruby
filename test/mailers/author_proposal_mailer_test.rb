# frozen_string_literal: true

require "test_helper"

# Tests for AuthorProposalMailer
# Verifies email delivery for author proposal notifications
class AuthorProposalMailerTest < ActionMailer::TestCase
  test "submission_confirmation sends email to submitter_email with proposal ID" do
    author = Author.create!(name: "Jane Developer")
    proposal = AuthorProposal.create!(
      author: author,
      link_updates: { "github_url" => "https://github.com/janedeveloper" },
      submitter_name: "John Smith",
      submitter_email: "john@example.com",
      status: :pending
    )

    email = AuthorProposalMailer.submission_confirmation(proposal)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [ "john@example.com" ], email.to
    assert_equal "Author Proposal Received - ID ##{proposal.id}", email.subject

    # Check HTML part includes proposal ID
    assert_match "ID ##{proposal.id}", email.html_part.body.to_s

    # Check text part includes proposal ID
    assert_match "ID ##{proposal.id}", email.text_part.body.to_s
  end

  test "approval_notification sends email to submitter_email with author profile link" do
    author = Author.create!(name: "Ruby Developer", slug: "ruby-developer")
    proposal = AuthorProposal.create!(
      author: author,
      bio_text: "A Ruby enthusiast",
      submitter_name: "Community Member",
      submitter_email: "member@example.com",
      status: :approved
    )

    email = AuthorProposalMailer.approval_notification(proposal)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [ "member@example.com" ], email.to
    assert_equal "Author Proposal Approved - #{author.name}", email.subject

    # Check HTML part includes author name and link
    assert_match author.name, email.html_part.body.to_s
    assert_match author.slug, email.html_part.body.to_s

    # Check text part includes author name
    assert_match author.name, email.text_part.body.to_s
  end

  test "rejection_notification sends email with admin_comment feedback" do
    author = Author.create!(name: "Test Author")
    proposal = AuthorProposal.create!(
      author: author,
      bio_text: "Short bio",
      submitter_email: "proposer@example.com",
      status: :rejected,
      admin_comment: "Bio needs more detail about Ruby experience"
    )

    email = AuthorProposalMailer.rejection_notification(proposal)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [ "proposer@example.com" ], email.to
    assert_equal "Author Proposal Feedback - ID ##{proposal.id}", email.subject

    # Check HTML part includes admin comment
    assert_match "Bio needs more detail about Ruby experience", email.html_part.body.to_s

    # Check text part includes admin comment
    assert_match "Bio needs more detail about Ruby experience", email.text_part.body.to_s
  end

  test "submission_confirmation includes review timeline information" do
    author = Author.create!(name: "Matz")
    proposal = AuthorProposal.create!(
      author: author,
      link_updates: { "website_url" => "https://example.com" },
      submitter_email: "contributor@example.com"
    )

    email = AuthorProposalMailer.submission_confirmation(proposal)

    # Should include information about review timeline
    assert_match(/review|business days|team/i, email.html_part.body.to_s)
    assert_match(/review|business days|team/i, email.text_part.body.to_s)
  end

  test "approval_notification thanks submitter for contribution" do
    author = Author.create!(name: "DHH", slug: "dhh")
    proposal = AuthorProposal.create!(
      author: author,
      link_updates: { "twitter_url" => "https://twitter.com/dhh" },
      submitter_email: "fan@example.com",
      status: :approved
    )

    email = AuthorProposalMailer.approval_notification(proposal)

    # Should include thank you message
    assert_match(/thank/i, email.html_part.body.to_s)
    assert_match(/thank/i, email.text_part.body.to_s)
  end
end
