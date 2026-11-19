# frozen_string_literal: true

require "test_helper"

class UserPermissionsTest < ActiveSupport::TestCase
  test "editors may edit but may not administer" do
    user = User.new(role: :editor)

    assert_predicate user, :can_edit?
    assert_not user.can_administer?
  end

  test "admins may edit and administer" do
    user = User.new(role: :admin)

    assert_predicate user, :can_edit?
    assert_predicate user, :can_administer?
  end

  test "banning suspends the user and closes active sessions" do
    user = users(:editor)
    user.sessions.create!

    user.ban!(reason: "Spam", ip_address: "192.0.2.1", expires_at: 1.day.from_now)

    assert_predicate user.reload, :banned?
    assert_empty user.sessions
    assert_equal "Spam", user.bans.last.reason
    assert_equal "192.0.2.1", user.bans.last.ip_address
  end

  test "unbanning expires active bans and restores access" do
    user = users(:editor)
    user.ban!(reason: "Spam")

    user.unban!

    assert_predicate user.reload, :active?
    assert_not user.banned?
    assert_empty user.bans.active
  end
end
