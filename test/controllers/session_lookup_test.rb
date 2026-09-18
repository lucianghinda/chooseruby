# frozen_string_literal: true

require "test_helper"

class SessionLookupTest < ActionDispatch::IntegrationTest
  setup do
    post session_path, params: { email_address: "admin@test.com", password: "password" }
    @session = users(:admin).sessions.order(:created_at).last
  end

  test "a signed-in request touches the session's last_active_at" do
    @session.update_column(:last_active_at, 2.hours.ago)

    get root_path

    assert_in_delta Time.current, @session.reload.last_active_at, 5.seconds
  end

  test "a tampered session cookie is ignored" do
    cookies[:session_token] = "not-a-signed-value"

    get root_path

    assert_response :success
  end

  test "a session cookie for a deleted session is ignored" do
    @session.destroy

    get root_path

    assert_response :success
  end

  test "an expired session is ignored" do
    @session.update_column(:last_active_at, 31.days.ago)

    get root_path

    assert_response :success
    assert_equal 31.days.ago.to_date, @session.reload.last_active_at.to_date
  end
end
