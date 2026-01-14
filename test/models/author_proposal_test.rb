# frozen_string_literal: true

# == Schema Information
#
# Table name: author_proposals
#
#  id                    :integer          not null, primary key
#  admin_comment         :text
#  author_name           :string
#  bio_text              :text
#  description_text      :text
#  link_updates          :text
#  original_resource_url :text
#  resource_url          :text
#  reviewed_at           :datetime
#  status                :integer          default("pending"), not null
#  submission_notes      :text
#  submitter_email       :string           not null
#  submitter_name        :string
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  author_id             :integer
#  matched_entry_id      :integer
#  reviewer_id           :integer
#
# Indexes
#
#  index_author_proposals_on_author_id         (author_id)
#  index_author_proposals_on_created_at        (created_at)
#  index_author_proposals_on_matched_entry_id  (matched_entry_id)
#  index_author_proposals_on_status            (status)
#  index_author_proposals_on_submitter_email   (submitter_email)
#
# Foreign Keys
#
#  author_id         (author_id => authors.id) ON DELETE => cascade
#  matched_entry_id  (matched_entry_id => entries.id) ON DELETE => nullify
#
require "test_helper"

class AuthorProposalTest < ActiveSupport::TestCase
  def setup
    @author = Author.create!(name: "Yukihiro Matsumoto", slug: "yukihiro-matsumoto-test")
  end

  # Test 1: Validations - submitter_email required and format validation
  test "should not save proposal without submitter_email" do
    proposal = AuthorProposal.new(
      author: @author,
      bio_text: "New bio text"
    )
    assert_not proposal.save, "Saved proposal without submitter_email"
    assert_includes proposal.errors[:submitter_email], "can't be blank"
  end

  test "should validate submitter_email format" do
    proposal = AuthorProposal.new(
      author: @author,
      bio_text: "New bio text",
      submitter_email: "invalid-email"
    )
    assert_not proposal.save, "Saved proposal with invalid email format"
    assert_includes proposal.errors[:submitter_email], "must be a valid email address"

    proposal.submitter_email = "valid@example.com"
    assert proposal.save, "Did not save proposal with valid email"
  end

  # Test 2: At least one change proposed validation
  test "should require at least one proposed change" do
    proposal = AuthorProposal.new(
      author: @author,
      submitter_email: "test@example.com"
    )
    assert_not proposal.save, "Saved proposal without any changes"
    assert_includes proposal.errors[:base], "At least one change must be proposed"
  end

  test "should save with resource_url change" do
    proposal = AuthorProposal.new(
      author: @author,
      resource_url: "https://example.com/resource",
      submitter_email: "test@example.com"
    )
    assert proposal.save, "Did not save proposal with resource_url"
  end

  test "should save with link_updates" do
    proposal = AuthorProposal.new(
      author: @author,
      link_updates: { "github_url" => "https://github.com/newuser" },
      submitter_email: "test@example.com"
    )
    assert proposal.save, "Did not save proposal with link_updates"
  end

  test "should save with bio or description changes" do
    proposal = AuthorProposal.new(
      author: @author,
      bio_text: "New biography text",
      submitter_email: "test@example.com"
    )
    assert proposal.save, "Did not save proposal with bio_text"

    # Use different email to avoid duplicate prevention validation
    proposal2 = AuthorProposal.new(
      author: @author,
      description_text: "New description",
      submitter_email: "different@example.com"
    )
    assert proposal2.save, "Did not save proposal with description_text"
  end

  # Test 3: Status enum transitions
  test "should have pending status by default" do
    proposal = AuthorProposal.create(
      author: @author,
      bio_text: "New bio",
      submitter_email: "test@example.com"
    )
    assert proposal.pending?, "Proposal should have pending status by default"
    assert_equal 0, proposal.status_before_type_cast
  end

  test "should transition from pending to approved" do
    proposal = AuthorProposal.create(
      author: @author,
      bio_text: "New bio",
      submitter_email: "test@example.com"
    )
    proposal.update(status: :approved, reviewed_at: Time.current)
    assert proposal.approved?, "Proposal should be approved"
    assert_equal 1, proposal.status_before_type_cast
  end

  test "should transition from pending to rejected" do
    proposal = AuthorProposal.create(
      author: @author,
      bio_text: "New bio",
      submitter_email: "test@example.com"
    )
    proposal.update(status: :rejected, reviewed_at: Time.current, admin_comment: "Rejected")
    assert proposal.rejected?, "Proposal should be rejected"
    assert_equal 2, proposal.status_before_type_cast
  end

  # Test 4: Link updates JSON structure and URL validations
  test "should serialize link_updates as JSON hash" do
    proposal = AuthorProposal.create(
      author: @author,
      link_updates: { "github_url" => "https://github.com/test", "website_url" => "https://example.com" },
      submitter_email: "test@example.com"
    )
    assert_instance_of Hash, proposal.link_updates
    assert_equal "https://github.com/test", proposal.link_updates["github_url"]
    assert_equal "https://example.com", proposal.link_updates["website_url"]
  end

  test "should validate link URL formats in link_updates" do
    proposal = AuthorProposal.new(
      author: @author,
      link_updates: { "github_url" => "not-a-valid-url" },
      submitter_email: "test@example.com"
    )
    assert_not proposal.save, "Saved proposal with invalid URL in link_updates"
    assert_includes proposal.errors[:link_updates], "github_url must be a valid URL starting with http:// or https://"
  end

  test "should allow valid URLs in link_updates" do
    proposal = AuthorProposal.new(
      author: @author,
      link_updates: {
        "github_url" => "https://github.com/matz",
        "twitter_url" => "https://twitter.com/yukihiro_matz"
      },
      submitter_email: "test@example.com"
    )
    assert proposal.save, "Did not save proposal with valid URLs in link_updates"
  end

  # Test 5: Duplicate proposal prevention
  test "should prevent duplicate pending proposals within 24 hours" do
    proposal1 = AuthorProposal.create(
      author: @author,
      bio_text: "First proposal",
      submitter_email: "test@example.com"
    )
    assert proposal1.persisted?, "First proposal should be saved"

    proposal2 = AuthorProposal.new(
      author: @author,
      bio_text: "Second proposal",
      submitter_email: "test@example.com"
    )
    assert_not proposal2.save, "Saved duplicate proposal within 24 hours"
    assert_includes proposal2.errors[:base], "You already have a pending proposal for this author submitted within the last 24 hours"
  end

  test "should allow proposal after 24 hours" do
    proposal1 = AuthorProposal.create(
      author: @author,
      bio_text: "First proposal",
      submitter_email: "test@example.com",
      created_at: 25.hours.ago
    )

    proposal2 = AuthorProposal.new(
      author: @author,
      bio_text: "Second proposal",
      submitter_email: "test@example.com"
    )
    assert proposal2.save, "Did not save proposal after 24 hours"
  end

  test "should allow multiple proposals from different emails" do
    proposal1 = AuthorProposal.create(
      author: @author,
      bio_text: "First proposal",
      submitter_email: "test1@example.com"
    )

    proposal2 = AuthorProposal.new(
      author: @author,
      bio_text: "Second proposal",
      submitter_email: "test2@example.com"
    )
    assert proposal2.save, "Did not save proposal from different email"
  end

  # Test 6: Resource URL matching logic with normalized URLs
  test "should normalize and match resource URLs" do
    entry = Entry.create!(
      title: "Test Entry",
      url: "https://example.com/resource",
      status: :approved,
      published: true,
      submitter_email: "creator@example.com"
    )

    # Test matching with different URL variations
    proposal = AuthorProposal.create(
      author: @author,
      resource_url: "http://example.com/resource/",  # http, trailing slash
      submitter_email: "test@example.com"
    )

    assert_not_nil proposal.matched_entry_id, "Should match entry despite URL variations"
    assert_equal entry.id, proposal.matched_entry_id
  end

  test "should preserve original_resource_url" do
    proposal = AuthorProposal.create(
      author: @author,
      resource_url: "HTTP://EXAMPLE.COM/Resource/",
      submitter_email: "test@example.com"
    )

    assert_equal "HTTP://EXAMPLE.COM/Resource/", proposal.original_resource_url
    assert_equal "http://example.com/resource", proposal.resource_url
  end

  # Test 7: New author proposal validation
  test "should require author_name when author_id is nil" do
    proposal = AuthorProposal.new(
      author_id: nil,
      bio_text: "New author bio",
      submitter_email: "test@example.com"
    )
    assert_not proposal.save, "Saved new author proposal without author_name"
    assert_includes proposal.errors[:author_name], "can't be blank"
  end

  test "should save new author proposal with author_name" do
    proposal = AuthorProposal.new(
      author_id: nil,
      author_name: "New Author",
      bio_text: "New author bio",
      submitter_email: "test@example.com"
    )
    assert proposal.save, "Did not save new author proposal with author_name"
  end

  # Test 8: Bio text validation
  test "should validate bio_text maximum 500 characters" do
    proposal = AuthorProposal.new(
      author: @author,
      bio_text: "a" * 501,
      submitter_email: "test@example.com"
    )
    assert_not proposal.save, "Saved proposal with bio_text longer than 500 characters"
    assert_includes proposal.errors[:bio_text], "is too long (maximum is 500 characters)"
  end

  test "should save bio_text with 500 characters" do
    proposal = AuthorProposal.new(
      author: @author,
      bio_text: "a" * 500,
      submitter_email: "test@example.com"
    )
    assert proposal.save, "Did not save proposal with bio_text at 500 characters"
  end

  # ========================================
  # Task Group 2: Approval/Rejection Tests
  # ========================================

  # Test 2.1.1: approve! method creates/updates Author correctly
  test "approve! should update existing author with bio" do
    proposal = AuthorProposal.create!(
      author: @author,
      bio_text: "Updated bio for Matz",
      submitter_email: "test@example.com"
    )

    assert_changes -> { @author.reload.bio }, from: nil, to: "Updated bio for Matz" do
      proposal.approve!
    end

    assert proposal.approved?
    assert_not_nil proposal.reviewed_at
  end

  # Test 2.1.2: approve! creates EntriesAuthor when matched_entry_id exists
  test "approve! should create EntriesAuthor when matched_entry_id exists" do
    entry = Entry.create!(
      title: "RSpec Testing",
      url: "https://rspec.info",
      status: :approved,
      published: true,
      submitter_email: "creator@example.com"
    )

    proposal = AuthorProposal.create!(
      author: @author,
      resource_url: "https://rspec.info",
      submitter_email: "test@example.com"
    )

    assert_equal entry.id, proposal.matched_entry_id, "Entry should be matched"

    assert_difference "EntriesAuthor.count", 1 do
      proposal.approve!
    end

    entries_author = EntriesAuthor.find_by(author: @author, entry: entry)
    assert_not_nil entries_author, "EntriesAuthor association should be created"
    assert proposal.approved?
  end

  # Test 2.1.3: approve! applies link_updates to Author
  test "approve! should apply link_updates to author" do
    proposal = AuthorProposal.create!(
      author: @author,
      link_updates: {
        "github_url" => "https://github.com/matz",
        "twitter_url" => "https://twitter.com/yukihiro_matz"
      },
      submitter_email: "test@example.com"
    )

    proposal.approve!

    @author.reload
    assert_equal "https://github.com/matz", @author.github_url
    assert_equal "https://twitter.com/yukihiro_matz", @author.twitter_url
    assert proposal.approved?
  end

  # Test 2.1.4: approve! transaction rollback on failure
  test "approve! should rollback transaction on failure" do
    # Create a proposal that will fail when applied (name too short for new author)
    proposal = AuthorProposal.create!(
      author_id: nil,
      author_name: "X",  # Invalid: Author requires min 2 characters
      bio_text: "Some bio",
      submitter_email: "test@example.com"
    )

    # Should raise error and rollback
    assert_raises(ActiveRecord::RecordInvalid) do
      proposal.approve!
    end

    proposal.reload
    assert proposal.pending?, "Proposal should remain pending after failed approval"
    assert_nil proposal.reviewed_at, "reviewed_at should not be set on failed approval"
    assert_equal 0, Author.where(name: "X").count, "No author should be created on rollback"
  end

  # Test 2.1.5: reject! method sets status and records reviewer info
  test "reject! should set status to rejected and record admin comment" do
    proposal = AuthorProposal.create!(
      author: @author,
      bio_text: "Some bio text",
      submitter_email: "test@example.com"
    )

    freeze_time do
      proposal.reject!(admin_comment: "Bio needs more detail")

      assert proposal.rejected?
      assert_equal "Bio needs more detail", proposal.admin_comment
      assert_equal Time.current, proposal.reviewed_at
    end
  end

  test "reject! should require admin_comment" do
    proposal = AuthorProposal.create!(
      author: @author,
      bio_text: "Some bio text",
      submitter_email: "test@example.com"
    )

    assert_raises(ArgumentError) do
      proposal.reject!
    end

    assert proposal.pending?, "Proposal should remain pending without admin_comment"
  end

  # Test 2.1.6: New author creation flow via approve!
  test "approve! should create new author from proposal" do
    proposal = AuthorProposal.create!(
      author_id: nil,
      author_name: "DHH",
      bio_text: "Creator of Ruby on Rails",
      link_updates: {
        "github_url" => "https://github.com/dhh",
        "twitter_url" => "https://twitter.com/dhh"
      },
      submitter_email: "test@example.com"
    )

    assert_difference "Author.count", 1 do
      proposal.approve!
    end

    proposal.reload
    assert_not_nil proposal.author_id, "Author should be created and associated"

    # Reload with association to avoid strict loading violation
    new_author = Author.find(proposal.author_id)
    assert_equal "DHH", new_author.name
    assert_equal "Creator of Ruby on Rails", new_author.bio
    assert_equal "https://github.com/dhh", new_author.github_url
    assert_equal "https://twitter.com/dhh", new_author.twitter_url
    assert proposal.approved?
  end

  # ========================================
  # Task Group 2: Domain Methods Tests
  # ========================================

  test "new_author_proposal? should return true when author_id is nil" do
    proposal = AuthorProposal.new(
      author_id: nil,
      author_name: "New Author",
      bio_text: "Bio",
      submitter_email: "test@example.com"
    )
    assert proposal.new_author_proposal?
  end

  test "new_author_proposal? should return false when author_id is present" do
    proposal = AuthorProposal.new(
      author: @author,
      bio_text: "Bio",
      submitter_email: "test@example.com"
    )
    assert_not proposal.new_author_proposal?
  end

  test "existing_author_proposal? should return true when author_id is present" do
    proposal = AuthorProposal.new(
      author: @author,
      bio_text: "Bio",
      submitter_email: "test@example.com"
    )
    assert proposal.existing_author_proposal?
  end

  test "existing_author_proposal? should return false when author_id is nil" do
    proposal = AuthorProposal.new(
      author_id: nil,
      author_name: "New Author",
      bio_text: "Bio",
      submitter_email: "test@example.com"
    )
    assert_not proposal.existing_author_proposal?
  end

  test "has_resource_proposal? should return true when resource_url is present" do
    proposal = AuthorProposal.new(
      author: @author,
      resource_url: "https://example.com",
      submitter_email: "test@example.com"
    )
    assert proposal.has_resource_proposal?
  end

  test "has_resource_proposal? should return false when resource_url is blank" do
    proposal = AuthorProposal.new(
      author: @author,
      bio_text: "Bio",
      submitter_email: "test@example.com"
    )
    assert_not proposal.has_resource_proposal?
  end

  test "has_link_updates? should return true when link_updates is present" do
    proposal = AuthorProposal.new(
      author: @author,
      link_updates: { "github_url" => "https://github.com/test" },
      submitter_email: "test@example.com"
    )
    assert proposal.has_link_updates?
  end

  test "has_link_updates? should return false when link_updates is blank" do
    proposal = AuthorProposal.new(
      author: @author,
      bio_text: "Bio",
      submitter_email: "test@example.com"
    )
    assert_not proposal.has_link_updates?
  end

  test "has_bio_changes? should return true when bio_text or description_text present" do
    proposal1 = AuthorProposal.new(
      author: @author,
      bio_text: "Bio",
      submitter_email: "test@example.com"
    )
    assert proposal1.has_bio_changes?

    proposal2 = AuthorProposal.new(
      author: @author,
      description_text: "Description",
      submitter_email: "test2@example.com"
    )
    assert proposal2.has_bio_changes?

    proposal3 = AuthorProposal.new(
      author: @author,
      bio_text: "Bio",
      description_text: "Description",
      submitter_email: "test3@example.com"
    )
    assert proposal3.has_bio_changes?
  end

  test "has_bio_changes? should return false when bio_text and description_text are blank" do
    proposal = AuthorProposal.new(
      author: @author,
      link_updates: { "github_url" => "https://github.com/test" },
      submitter_email: "test@example.com"
    )
    assert_not proposal.has_bio_changes?
  end

  test "matched_entry? should return true when matched_entry_id is present" do
    entry = Entry.create!(
      title: "Test Entry",
      url: "https://example.com",
      status: :approved,
      published: true,
      submitter_email: "creator@example.com"
    )

    proposal = AuthorProposal.create!(
      author: @author,
      resource_url: "https://example.com",
      submitter_email: "test@example.com"
    )

    assert proposal.matched_entry?
  end

  test "matched_entry? should return false when matched_entry_id is nil" do
    proposal = AuthorProposal.new(
      author: @author,
      bio_text: "Bio",
      submitter_email: "test@example.com"
    )
    assert_not proposal.matched_entry?
  end
end
