# frozen_string_literal: true

require "test_helper"

class AvoAuthorProposalComparisonTest < ActiveSupport::TestCase
  test "missing or unrelated records do not render a proposal comparison" do
    [ nil, Object.new ].each do |record|
      comparison = Avo::AuthorProposalComparison.new(record)
      assert_not comparison.new_author?
      assert_equal "", comparison.type
      assert_equal "", comparison.summary
    end
  end

  test "new author comparison includes proposed details and blank current values" do
    proposal = AuthorProposal.new(author_name: "New Author", bio_text: "New bio", description_text: "New description", link_updates: { "github_url" => "https://github.com/new" })
    comparison = Avo::AuthorProposalComparison.new(proposal)

    assert comparison.new_author?
    assert_equal "New Author", comparison.type
    assert_equal <<~TEXT.strip, comparison.summary
      Creating new author: New Author

      Link Updates:
        - github_url: (blank) → https://github.com/new

      Bio:
        Current: (blank)
        Proposed: New bio

      Description:
        Current: (blank)
        Proposed: New description
    TEXT
  end

  test "existing author comparison includes current values and matched resource" do
    author = Author.new(id: 71, name: "Existing Author", bio: "Current bio", github_url: "https://github.com/old")
    entry = Entry.new(id: 42, title: "Matched resource")
    proposal = AuthorProposal.new(author: author, matched_entry: entry, resource_url: "https://example.com/matched", bio_text: "New bio", description_text: "New description", link_updates: { "github_url" => "https://github.com/new" })
    comparison = Avo::AuthorProposalComparison.new(proposal)

    assert_not comparison.new_author?
    assert_equal "Edit Existing Author", comparison.type
    assert_includes comparison.summary, "Editing author: Existing Author"
    assert_includes comparison.summary, "Resource: Matched entry #42 - Matched resource"
    assert_includes comparison.summary, "github_url: https://github.com/old → https://github.com/new"
    assert_includes comparison.summary, "Current: Current bio"
    assert_includes comparison.summary, "Description:\n  Current: (blank)\n  Proposed: New description"
  end

  test "unmatched resource is shown and empty optional changes are omitted" do
    proposal = AuthorProposal.new(author_name: "New Author", resource_url: "https://example.com/unmatched")

    assert_equal "Creating new author: New Author\n\nResource: Unmatched URL - https://example.com/unmatched",
      Avo::AuthorProposalComparison.new(proposal).summary
  end

  test "removed author and missing matched entry remain displayable" do
    proposal = AuthorProposal.new(author_id: 998_001, matched_entry_id: 998_002, resource_url: "https://example.com/missing")
    proposal.association(:author).loaded!
    proposal.association(:matched_entry).loaded!

    assert_equal "Editing author: \n\nResource: Matched entry #998002 - ",
      Avo::AuthorProposalComparison.new(proposal).summary
  end
end
