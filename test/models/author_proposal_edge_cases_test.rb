# frozen_string_literal: true

require "test_helper"

class AuthorProposalEdgeCasesTest < ActiveSupport::TestCase
  test "rejection requires a useful comment" do
    proposal = AuthorProposal.new

    assert_raises(ArgumentError) { proposal.reject!(admin_comment: " ") }
  end

  test "approval ignores blank link changes" do
    author = Author.create!(name: "Blank Link Author", website_url: "https://example.com")
    proposal = AuthorProposal.create!(author: author, bio_text: "Updated bio",
      link_updates: { "website_url" => "" }, submitter_email: "author@example.com")

    proposal.approve!

    assert_equal "https://example.com", author.reload.website_url
    assert_equal "Updated bio", author.bio
  end

  test "unrecognized link fields are rejected" do
    proposal = AuthorProposal.new(author_name: "Link Author", submitter_email: "author@example.com",
      link_updates: { "unknown_url" => "https://example.com" })

    assert_not proposal.valid?
    assert_includes proposal.errors[:link_updates], "unknown_url is not a valid link field"
  end

  test "approval rejects a persisted invalid link field" do
    proposal = AuthorProposal.create!(author_name: "Link Author", submitter_email: "author@example.com")
    proposal.update_column(:link_updates, { "unknown_url" => "https://example.com" })

    assert_raises(ArgumentError) { proposal.approve! }
    assert_predicate proposal.reload, :pending?
  end

  test "approval does not duplicate an existing author entry association" do
    author = Author.create!(name: "Linked Author")
    entry = Entry.create!(title: "Linked resource", url: "http://example.com/linked", status: :approved)
    author.entries << entry
    proposal = AuthorProposal.create!(author: author, resource_url: entry.url,
      submitter_email: "author@example.com")

    assert_no_difference "EntriesAuthor.count" do
      proposal.approve!
    end

    assert_predicate proposal, :approved?
  end

  test "a slash alone normalizes to an empty unmatched resource" do
    proposal = AuthorProposal.new(author_name: "New Author", resource_url: "/",
      submitter_email: "author@example.com")

    assert_predicate proposal, :valid?
    assert_empty proposal.resource_url
    assert_nil proposal.matched_entry_id
  end
end
