# frozen_string_literal: true

require "test_helper"

class AuthorProposalSummaryTest < ActiveSupport::TestCase
  setup do
    @author = Author.create!(name: "Yukihiro Matsumoto", bio: "Creator of Ruby", github_url: "https://github.com/matz")
  end

  test "proposal_type distinguishes new author proposals from edits" do
    new_author = AuthorProposal.new(author_name: "Someone New", submitter_email: "a@example.com")
    edit = AuthorProposal.new(author: @author, bio_text: "New bio", submitter_email: "a@example.com")

    assert_equal "New Author", new_author.proposal_type
    assert_equal "Edit Existing Author", edit.proposal_type
  end

  test "changes_summary describes a new author proposal with unmatched resource and links" do
    proposal = AuthorProposal.new(
      author_name: "Someone New",
      resource_url: "https://example.com/unmatched",
      link_updates: { "github_url" => "https://github.com/new" },
      submitter_email: "a@example.com"
    )

    assert_equal <<~SUMMARY.chomp, proposal.changes_summary
      Creating new author: Someone New

      Resource: Unmatched URL - https://example.com/unmatched

      Link Updates:
        - github_url: (blank) → https://github.com/new
    SUMMARY
  end

  test "changes_summary describes an edit with matched resource, links, bio and description" do
    entry = Entry.create!(title: "Ruby Guide", url: "https://example.com/guide", status: :approved, published: true)
    proposal = AuthorProposal.create!(
      author: @author,
      resource_url: "https://example.com/guide",
      link_updates: { "github_url" => "https://github.com/matz2", "gitlab_url" => "https://gitlab.com/matz" },
      bio_text: "Chief Ruby designer",
      description_text: "Long description",
      submitter_email: "a@example.com"
    )
    proposal = AuthorProposal.includes(:author, :matched_entry).find(proposal.id)

    assert_equal <<~SUMMARY.chomp, proposal.changes_summary
      Editing author: Yukihiro Matsumoto

      Resource: Matched entry ##{entry.id} - Ruby Guide

      Link Updates:
        - github_url: https://github.com/matz → https://github.com/matz2
        - gitlab_url: (blank) → https://gitlab.com/matz

      Bio:
        Current: Creator of Ruby
        Proposed: Chief Ruby designer

      Description:
        Proposed: Long description
    SUMMARY
  end

  test "changes_summary shows a blank current bio for a new author" do
    proposal = AuthorProposal.new(author_name: "Someone New", bio_text: "Fresh bio", submitter_email: "a@example.com")

    assert_equal <<~SUMMARY.chomp, proposal.changes_summary
      Creating new author: Someone New

      Bio:
        Current: (blank)
        Proposed: Fresh bio
    SUMMARY
  end
end
