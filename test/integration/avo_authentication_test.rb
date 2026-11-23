# frozen_string_literal: true

require "test_helper"

class AvoAuthenticationTest < ActionDispatch::IntegrationTest
  test "redirects signed-out visitors from the dashboard and resource pages" do
    get "/avo/"
    assert_redirected_to "/session/new"

    get "/avo/resources/entries"
    assert_redirected_to "/session/new"
  end

  test "keeps admin pages restricted to admins" do
    sign_in(users(:editor))

    get "/avo/"
    assert_redirected_to "/session/new"

    get "/avo/resources/entries"
    assert_redirected_to "/session/new"
  end

  test "renders the dashboard and resources for an admin" do
    sign_in(users(:admin))
    assert_redirected_to "/avo/"

    get "/avo/"
    follow_redirect! if response.redirect?
    assert_response :success

    get "/avo/resources/entries?page=2"
    assert_response :success

    get "/avo/resources/authors"
    assert_response :success

    get "/avo/resources/author_proposals"
    assert_response :success
  end

  private

  def sign_in(user)
    post session_url, params: { email_address: user.email_address, password: "password" }
  end
end
