# frozen_string_literal: true

require "test_helper"

# Integration tests for end-to-end author proposal workflows
# These tests verify the complete flow from submission to approval/rejection
# covering multiple models, controllers, and mailers working together.
class AuthorProposalWorkflowTest < ActionDispatch::IntegrationTest
  # ========================================
  # Integration Test 1: Full Proposal Submission and Approval Flow
  # ========================================
  # Tests the complete workflow of an anonymous user submitting an edit proposal
  # and an admin approving it, resulting in the author being updated and email sent
  test "anonymous user submits edit proposal, admin approves, author is updated and email sent" do
    author = Author.create!(name: "Yukihiro Matsumoto", slug: "matz", status: :approved)

    # Step 1: Anonymous user submits proposal
    assert_difference "AuthorProposal.count", 1 do
      post author_proposals_path, params: {
        author_proposal: {
          author_id: author.id,
          bio_text: "Creator of Ruby programming language",
          link_updates: {
            "github_url" => "https://github.com/matz",
            "twitter_url" => "https://twitter.com/yukihiro_matz"
          },
          submitter_email: "community@example.com",
          submitter_name: "Ruby Fan",
          submission_notes: "Adding verified links for Matz"
        }
      }
    end

    proposal = AuthorProposal.last
    assert_equal "pending", proposal.status
    assert_redirected_to author_proposal_success_path(proposal)

    # Step 2: Verify submission confirmation email was sent
    assert_enqueued_emails 1

    # Step 3: Admin approves the proposal
    perform_enqueued_jobs do
      proposal.approve!
    end

    # Step 4: Verify author was updated with all changes
    author.reload
    assert_equal "Creator of Ruby programming language", author.bio
    assert_equal "https://github.com/matz", author.github_url
    assert_equal "https://twitter.com/yukihiro_matz", author.twitter_url

    # Step 5: Verify proposal status updated
    proposal.reload
    assert_equal "approved", proposal.status
    assert_not_nil proposal.reviewed_at

    # Step 6: Verify approval email was sent
    assert_enqueued_emails 1
  end

  # ========================================
  # Integration Test 2: New Author Proposal Flow
  # ========================================
  # Tests the complete workflow of proposing and creating a new author
  test "anonymous user proposes new author, admin approves, new author is created" do
    initial_author_count = Author.count

    # Step 1: User submits new author proposal
    post author_proposals_path, params: {
      author_proposal: {
        author_id: nil,
        author_name: "David Heinemeier Hansson",
        bio_text: "Creator of Ruby on Rails",
        link_updates: {
          "github_url" => "https://github.com/dhh",
          "twitter_url" => "https://twitter.com/dhh",
          "website_url" => "https://dhh.dk"
        },
        submitter_email: "rails-fan@example.com"
      }
    }

    proposal = AuthorProposal.last
    assert_equal "pending", proposal.status
    assert_nil proposal.author_id, "Should not have author_id yet"

    # Step 2: Admin approves proposal
    perform_enqueued_jobs do
      assert_difference "Author.count", 1 do
        proposal.approve!
      end
    end

    # Step 3: Verify new author was created with all attributes
    proposal.reload
    assert_not_nil proposal.author_id, "Should have author_id after approval"

    new_author = Author.find(proposal.author_id)
    assert_equal "David Heinemeier Hansson", new_author.name
    assert_equal "Creator of Ruby on Rails", new_author.bio
    assert_equal "https://github.com/dhh", new_author.github_url
    assert_equal "https://twitter.com/dhh", new_author.twitter_url
    assert_equal "https://dhh.dk", new_author.website_url

    # Step 4: Verify proposal is marked approved
    assert_equal "approved", proposal.status
  end

  # ========================================
  # Integration Test 3: Resource Matching Creates EntriesAuthor
  # ========================================
  # Tests resource URL matching and EntriesAuthor association creation
  test "user submits resource URL, system matches entry, admin approves, EntriesAuthor is created" do
    author = Author.create!(name: "Aaron Patterson", slug: "tenderlove", status: :approved)
    entry = Entry.create!(
      title: "Rails Performance Guide",
      url: "https://guides.rubyonrails.org/performance",
      status: :approved,
      published: true,
      submitter_email: "editor@example.com"
    )

    # Step 1: User submits proposal with resource URL (with variations)
    post author_proposals_path, params: {
      author_proposal: {
        author_id: author.id,
        resource_url: "HTTP://WWW.GUIDES.RUBYONRAILS.ORG/Performance/",  # Different case, protocol, www, trailing slash
        submitter_email: "contributor@example.com"
      }
    }

    proposal = AuthorProposal.last

    # Step 2: Verify URL was matched to entry
    assert_equal entry.id, proposal.matched_entry_id, "Should match entry despite URL variations"
    assert proposal.matched_entry?, "matched_entry? should return true"

    # Step 3: Admin approves proposal
    assert_difference "EntriesAuthor.count", 1 do
      proposal.approve!
    end

    # Step 4: Verify EntriesAuthor association was created
    entries_author = EntriesAuthor.find_by(author: author, entry: entry)
    assert_not_nil entries_author, "EntriesAuthor association should exist"
    assert_equal author.id, entries_author.author_id
    assert_equal entry.id, entries_author.entry_id
  end

  # ========================================
  # Integration Test 4: Rejection Notification Flow
  # ========================================
  # Tests admin rejecting a proposal and submitter receiving email with feedback
  test "admin rejects proposal, submitter receives email with feedback" do
    author = Author.create!(name: "Sandi Metz", status: :approved, bio: "Original bio text")

    # Step 1: User submits proposal
    post author_proposals_path, params: {
      author_proposal: {
        author_id: author.id,
        bio_text: "OOP expert",
        submitter_email: "proposer@example.com"
      }
    }

    proposal = AuthorProposal.last
    original_bio = author.bio

    # Step 2: Admin rejects with feedback
    perform_enqueued_jobs do
      proposal.reject!(admin_comment: "Bio is too short. Please provide more detail about contributions to Ruby community.")
    end

    # Step 3: Verify proposal status
    proposal.reload
    assert_equal "rejected", proposal.status
    assert_equal "Bio is too short. Please provide more detail about contributions to Ruby community.", proposal.admin_comment
    assert_not_nil proposal.reviewed_at

    # Step 4: Verify author was NOT updated
    author.reload
    assert_equal original_bio, author.bio, "Author should not be updated on rejection"

    # Step 5: Verify rejection email was sent
    assert_enqueued_emails 1
  end

  # ========================================
  # Integration Test 5: Multiple Changes in Single Proposal
  # ========================================
  # Tests submitting resource + link updates + bio all in one proposal
  test "user submits proposal with resource, links, and bio changes all together" do
    author = Author.create!(name: "Koichi Sasada", status: :approved)
    entry = Entry.create!(
      title: "YARV Implementation",
      url: "https://github.com/ruby/ruby",
      status: :approved,
      published: true,
      submitter_email: "ruby-core@example.com"
    )

    # Step 1: Submit comprehensive proposal with multiple change types
    post author_proposals_path, params: {
      author_proposal: {
        author_id: author.id,
        resource_url: "https://github.com/ruby/ruby",  # Resource association
        bio_text: "Lead developer of YARV, Ruby's virtual machine",  # Bio change
        link_updates: {  # Multiple link updates
          "github_url" => "https://github.com/ko1",
          "twitter_url" => "https://twitter.com/ko1_ruby"
        },
        submitter_email: "ruby-enthusiast@example.com",
        submission_notes: "Adding comprehensive information about Koichi-san's work"
      }
    }

    proposal = AuthorProposal.last

    # Step 2: Verify proposal captured all changes
    assert_equal entry.id, proposal.matched_entry_id
    assert_equal "Lead developer of YARV, Ruby's virtual machine", proposal.bio_text
    assert_equal "https://github.com/ko1", proposal.link_updates["github_url"]
    assert_equal "https://twitter.com/ko1_ruby", proposal.link_updates["twitter_url"]

    # Step 3: Approve and verify all changes applied
    assert_difference "EntriesAuthor.count", 1 do
      proposal.approve!
    end

    author.reload
    assert_equal "Lead developer of YARV, Ruby's virtual machine", author.bio
    assert_equal "https://github.com/ko1", author.github_url
    assert_equal "https://twitter.com/ko1_ruby", author.twitter_url

    # Verify EntriesAuthor was created
    assert EntriesAuthor.exists?(author: author, entry: entry)
  end

  # ========================================
  # Integration Test 6: Duplicate Proposal Prevention (Controller Level)
  # ========================================
  # Tests that duplicate proposal prevention works through the controller
  test "controller prevents duplicate proposal submissions within 24 hours" do
    author = Author.create!(name: "Matz", status: :approved)

    # Step 1: Submit first proposal
    post author_proposals_path, params: {
      author_proposal: {
        author_id: author.id,
        bio_text: "First proposal",
        submitter_email: "duplicate-test@example.com"
      }
    }

    first_proposal = AuthorProposal.last
    assert_redirected_to author_proposal_success_path(first_proposal)

    # Step 2: Attempt duplicate submission within 24 hours
    assert_no_difference "AuthorProposal.count" do
      post author_proposals_path, params: {
        author_proposal: {
          author_id: author.id,
          bio_text: "Second proposal (duplicate)",
          submitter_email: "duplicate-test@example.com"
        }
      }
    end

    # Step 3: Verify error response
    assert_response :unprocessable_entity
    assert_select "div.text-rose-700", text: /pending proposal/

    # Step 4: Verify duplicate is allowed after 24 hours
    travel 25.hours do
      assert_difference "AuthorProposal.count", 1 do
        post author_proposals_path, params: {
          author_proposal: {
            author_id: author.id,
            bio_text: "Second proposal after 24 hours",
            submitter_email: "duplicate-test@example.com"
          }
        }
      end

      assert_redirected_to author_proposal_success_path(AuthorProposal.last)
    end
  end

  # ========================================
  # Integration Test 7: Full Email Notification Flow
  # ========================================
  # Tests email delivery through the entire workflow from creation to approval
  test "emails are delivered at each stage of the workflow" do
    author = Author.create!(name: "Why the Lucky Stiff", status: :approved)

    # Step 1: Create proposal and verify submission confirmation email
    assert_performed_jobs 1, only: ActionMailer::MailDeliveryJob do
      post author_proposals_path, params: {
        author_proposal: {
          author_id: author.id,
          bio_text: "Legendary Ruby educator and artist",
          submitter_email: "poignant-guide@example.com"
        }
      }
    end

    proposal = AuthorProposal.last

    # Step 2: Approve proposal and verify approval notification email
    assert_performed_jobs 1, only: ActionMailer::MailDeliveryJob do
      proposal.approve!
    end

    # Step 3: Test rejection flow with new proposal
    assert_performed_jobs 1, only: ActionMailer::MailDeliveryJob do
      post author_proposals_path, params: {
        author_proposal: {
          author_id: author.id,
          bio_text: "Test rejection bio",
          submitter_email: "different-user@example.com"
        }
      }
    end

    rejection_proposal = AuthorProposal.last

    # Step 4: Reject and verify rejection notification email
    assert_performed_jobs 1, only: ActionMailer::MailDeliveryJob do
      rejection_proposal.reject!(admin_comment: "Needs more information")
    end
  end

  # ========================================
  # Integration Test 8: Transaction Rollback on Approval Failure
  # ========================================
  # Tests that partial failures during approval rollback all changes
  test "approval transaction rolls back all changes when author save fails" do
    # Create proposal that will fail during approval (invalid author name length)
    proposal = AuthorProposal.create!(
      author_id: nil,
      author_name: "X",  # Too short - Author requires minimum 2 characters
      bio_text: "Test bio",
      link_updates: { "github_url" => "https://github.com/test" },
      submitter_email: "test@example.com"
    )

    initial_author_count = Author.count
    initial_proposal_status = proposal.status

    # Step 1: Attempt approval which should fail and rollback
    assert_raises(ActiveRecord::RecordInvalid) do
      proposal.approve!
    end

    # Step 2: Verify no author was created (rollback successful)
    assert_equal initial_author_count, Author.count, "No author should be created on rollback"

    # Step 3: Verify proposal status unchanged (rollback successful)
    proposal.reload
    assert_equal initial_proposal_status, proposal.status, "Proposal status should not change on failed approval"
    assert_nil proposal.reviewed_at, "reviewed_at should not be set on failed approval"
    assert_nil proposal.author_id, "author_id should remain nil on failed approval"

    # Step 4: Verify proposal can be corrected and approved successfully
    proposal.update!(author_name: "Valid Name")

    assert_difference "Author.count", 1 do
      proposal.approve!
    end

    proposal.reload
    assert_equal "approved", proposal.status
    assert_not_nil proposal.author_id
  end
end
