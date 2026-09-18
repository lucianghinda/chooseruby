# frozen_string_literal: true

require "test_helper"

class Avo::Filters::StatusFiltersTest < ActiveSupport::TestCase
  test "author status filter narrows to approved or pending authors" do
    approved = Author.create!(name: "Approved Author", status: :approved)
    pending = Author.create!(name: "Pending Author", status: :pending)
    filter = Avo::Filters::AuthorStatusFilter.new

    assert_equal [ approved ], filter.apply(nil, Author.where(id: [ approved, pending ]), "approved").to_a
    assert_equal [ pending ], filter.apply(nil, Author.where(id: [ approved, pending ]), "pending").to_a
    assert_equal 2, filter.apply(nil, Author.where(id: [ approved, pending ]), "bogus").count
    assert_equal %w[approved pending], filter.options.values
  end

  test "author proposal status filter narrows by status and defaults to pending" do
    author = Author.create!(name: "Proposal Author", status: :approved)
    pending = AuthorProposal.create!(author: author, bio_text: "Bio", submitter_email: "p@example.com")
    approved = AuthorProposal.create!(author: author, bio_text: "Bio", submitter_email: "a@example.com", status: :approved)
    rejected = AuthorProposal.create!(author: author, bio_text: "Bio", submitter_email: "r@example.com", status: :rejected)
    proposals = AuthorProposal.where(author: author)
    filter = Avo::Filters::AuthorProposalStatusFilter.new

    assert_equal [ pending ], filter.apply(nil, proposals, "pending").to_a
    assert_equal [ approved ], filter.apply(nil, proposals, "Approved").to_a
    assert_equal [ rejected ], filter.apply(nil, proposals, "rejected").to_a
    assert_equal 3, filter.apply(nil, proposals, nil).count
    assert_equal "pending", filter.default
    assert_equal %w[pending approved rejected], filter.options.values
  end
end
