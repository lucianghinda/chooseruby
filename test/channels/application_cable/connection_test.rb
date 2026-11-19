# frozen_string_literal: true

require "test_helper"

module ApplicationCable
  class ConnectionTest < ActionCable::Connection::TestCase
    tests ApplicationCable::Connection

    test "connects and identifies the user behind a valid session cookie" do
      session = sessions(:admin_session)
      cookies.signed[:session_token] = session.token

      connect

      assert_equal users(:admin), connection.current_user
    end

    test "rejects a connection without a session cookie" do
      assert_reject_connection { connect }
    end

    test "rejects a connection whose session token is unknown" do
      cookies.signed[:session_token] = "not-a-real-token"

      assert_reject_connection { connect }
    end

    test "rejects a connection whose session has expired" do
      session = sessions(:admin_session)
      session.update_column(:last_active_at, 31.days.ago)
      cookies.signed[:session_token] = session.token

      assert_reject_connection { connect }
    end

    test "rejects a connection whose session cookie is not signed" do
      cookies[:session_token] = sessions(:admin_session).token

      assert_reject_connection { connect }
    end
  end
end
