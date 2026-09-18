# frozen_string_literal: true

require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "a suspended signed-in user is blocked on public and admin pages" do
    post session_url, params: { email_address: "admin@test.com", password: "password" }
    assert_redirected_to "/avo/"

    users(:admin).suspended!

    [ root_path, "/avo/resources/entries" ].each do |path|
      get path
      assert_response :forbidden
      assert_equal "Access denied", response.body
    end
  end

  test "sign in supports an authenticated request before signing out" do
    post session_url, params: { email_address: "admin@test.com", password: "password" }
    get "/avo/resources/entries"
    assert_response :success

    delete "/session"
    assert_redirected_to "/"
    assert_empty cookies[:session_token]

    get "/avo/resources/entries"
    assert_redirected_to "/session/new"
  end

  test "logout without an existing session is idempotent" do
    assert_no_difference "Session.count" do
      delete session_url
    end
    assert_redirected_to root_path
  end

  test "GET new renders login form" do
    get new_session_url
    assert_response :success
  end

  test "POST create with valid credentials redirects to avo" do
    post session_url, params: {
      email_address: "admin@test.com",
      password: "password"
    }
    assert_redirected_to "/avo/"
  end

  test "POST create with valid credentials sets cookie" do
    post session_url, params: {
      email_address: "admin@test.com",
      password: "password"
    }
    assert cookies[:session_token].present?
  end

  test "POST create with invalid email shows error" do
    post session_url, params: {
      email_address: "wrong@test.com",
      password: "password"
    }
    assert_response :unprocessable_entity
    assert_select "div", text: /Invalid email or password/
  end

  test "POST create with invalid password shows error" do
    post session_url, params: {
      email_address: "admin@test.com",
      password: "wrongpassword"
    }
    assert_response :unprocessable_entity
    assert_select "div", text: /Invalid email or password/
  end

  test "POST create with suspended user fails" do
    post session_url, params: {
      email_address: "suspended@test.com",
      password: "password"
    }
    assert_response :unprocessable_entity
    assert_select "div", text: /Invalid email or password/
  end

  test "DELETE destroy clears session and cookie" do
    # First login
    post session_url, params: {
      email_address: "admin@test.com",
      password: "password"
    }
    assert cookies[:session_token].present?

    # Then logout
    delete session_url
    assert_empty cookies[:session_token]
  end

  test "DELETE destroy redirects to root" do
    # Login first
    post session_url, params: {
      email_address: "admin@test.com",
      password: "password"
    }

    # Then logout
    delete session_url
    assert_redirected_to root_path
  end
end
