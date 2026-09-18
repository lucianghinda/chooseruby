# frozen_string_literal: true

require "test_helper"

class BlockBannedRequestsTest < ActionDispatch::IntegrationTest
  test "requests from a banned IP address are denied" do
    Ban.create!(ip_address: "127.0.0.1", reason: "Abuse")

    get root_path

    assert_response :forbidden
    assert_equal "Access denied", response.body
  end

  test "requests from a suspended signed-in user are denied" do
    post session_path, params: { email_address: "admin@test.com", password: "password" }
    users(:admin).suspended!

    get root_path

    assert_response :forbidden
  end

  test "requests from a signed-in user in good standing are served" do
    post session_path, params: { email_address: "admin@test.com", password: "password" }

    get root_path

    assert_response :success
  end
end
