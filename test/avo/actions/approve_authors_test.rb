# frozen_string_literal: true

require "test_helper"

class Avo::Actions::ApproveAuthorsTest < ActiveSupport::TestCase
  test "approve action approves the selected authors" do
    authors = [ Author.create!(name: "First Pending"), Author.create!(name: "Second Pending") ]

    action = Avo::Actions::ApproveAuthors.new(record: nil, resource: nil, user: nil, view: :index)
    action.handle(records: authors, fields: {}, current_user: nil, resource: nil)

    assert authors.all? { |author| author.reload.approved? }
    assert_equal "2 authors approved successfully!", action.response[:messages].sole[:body]
  end
end
