# frozen_string_literal: true

require "test_helper"
require "action_cable/connection/test_case"

class ApplicationCable::ConnectionTest < ActionCable::Connection::TestCase
  tests ApplicationCable::Connection

  test "a valid signed session identifies the user without refreshing activity" do
    user = User.create!(email_address: "cable@example.com", name: "Cable User", password: "password123")
    session = user.sessions.create!(last_active_at: 1.day.ago)
    last_active_at = session.last_active_at
    cookies.signed[:session_token] = session.token

    connect

    assert_equal user, connection.current_user
    assert_equal last_active_at, session.reload.last_active_at
  end

  test "a missing session cookie is rejected" do
    assert_reject_connection { connect }
  end

  test "an unsigned session cookie cannot authenticate" do
    user = User.create!(email_address: "unsigned@example.com", name: "Unsigned User", password: "password123")
    cookies[:session_token] = user.sessions.create!.token

    assert_reject_connection { connect }
  end

  test "an unknown signed session token is rejected" do
    cookies.signed[:session_token] = "unknown-token"

    assert_reject_connection { connect }
  end

  test "an expired signed session is rejected" do
    user = User.create!(email_address: "expired-cable@example.com", name: "Expired User", password: "password123")
    session = user.sessions.create!(last_active_at: 31.days.ago)
    cookies.signed[:session_token] = session.token

    assert_reject_connection { connect }
  end
end
