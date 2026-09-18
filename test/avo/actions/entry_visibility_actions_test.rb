# frozen_string_literal: true

require "test_helper"

class Avo::Actions::EntryVisibilityActionsTest < ActiveSupport::TestCase
  setup do
    @entry = Entry.create!(title: "Toggle Me", url: "https://example.com", status: :approved, published: false)
  end

  test "publish action publishes the selected entries" do
    action = Avo::Actions::PublishEntries.new(record: @entry, resource: nil, user: nil, view: :index)
    action.handle(records: [ @entry ], fields: {}, current_user: nil, resource: nil)

    assert @entry.reload.published
    assert_equal "1 resource published successfully!", action.response[:messages].sole[:body]
  end

  test "unpublish action unpublishes the selected entries" do
    @entry.update!(published: true)

    action = Avo::Actions::UnpublishEntries.new(record: @entry, resource: nil, user: nil, view: :index)
    action.handle(records: [ @entry ], fields: {}, current_user: nil, resource: nil)

    assert_not @entry.reload.published
    assert_equal "1 resource unpublished successfully!", action.response[:messages].sole[:body]
  end
end
