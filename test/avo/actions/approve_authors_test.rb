# frozen_string_literal: true

require "test_helper"

class Avo::Actions::ApproveAuthorsTest < ActiveSupport::TestCase
  test "approve action approves every selected author" do
    matz = Author.create!(name: "Yukihiro Matsumoto", status: :pending)
    dhh = Author.create!(name: "David Heinemeier Hansson", status: :pending)

    action = Avo::Actions::ApproveAuthors.new(record: matz, resource: nil, user: nil, view: :index)
    action.handle(records: [ matz, dhh ], fields: {}, current_user: nil, resource: nil)

    assert_predicate matz.reload, :approved?
    assert_predicate dhh.reload, :approved?
  end

  test "approve action reports the number of approved authors in plural" do
    matz = Author.create!(name: "Yukihiro Matsumoto", status: :pending)
    dhh = Author.create!(name: "David Heinemeier Hansson", status: :pending)

    action = Avo::Actions::ApproveAuthors.new(record: matz, resource: nil, user: nil, view: :index)
    action.handle(records: [ matz, dhh ], fields: {}, current_user: nil, resource: nil)

    message = action.response[:messages].last
    assert_equal :success, message[:type]
    assert_equal "2 authors approved successfully!", message[:body]
  end

  test "approve action reports a single author in singular" do
    author = Author.create!(name: "Aaron Patterson", status: :pending)

    action = Avo::Actions::ApproveAuthors.new(record: author, resource: nil, user: nil, view: :index)
    action.handle(records: [ author ], fields: {}, current_user: nil, resource: nil)

    message = action.response[:messages].last
    assert_equal :success, message[:type]
    assert_equal "1 author approved successfully!", message[:body]
  end

  test "approve action leaves already approved authors approved" do
    author = Author.create!(name: "Jeremy Evans", status: :approved)

    action = Avo::Actions::ApproveAuthors.new(record: author, resource: nil, user: nil, view: :index)
    action.handle(records: [ author ], fields: {}, current_user: nil, resource: nil)

    assert_predicate author.reload, :approved?
  end
end
