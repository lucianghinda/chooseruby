# frozen_string_literal: true

require "test_helper"

# Probe controller used to exercise the Authentication concern over a real
# request/response cycle. It inherits ApplicationController, so it picks up the
# concern exactly the way the application's controllers do.
class AuthenticationProbeController < ApplicationController
  before_action :require_authentication, only: :members_only

  def show
    render json: {
      email: current_user&.email_address,
      authenticated: authenticated?,
      session_id: Current.session&.id
    }
  end

  def members_only
    render plain: "members area"
  end

  def sign_in
    start_new_session_for(User.find(params[:user_id]))

    render plain: Current.session.token
  end

  def sign_out
    terminate_session

    render json: { email: current_user&.email_address, session_id: Current.session&.id }
  end
end

class AuthenticationTest < ActionDispatch::IntegrationTest
  test "anonymous request has no current user" do
    with_probe_routes do
      get "/probe"

      assert_response :success
      assert_nil response.parsed_body["email"]
      assert_not response.parsed_body["authenticated"]
      assert_nil response.parsed_body["session_id"]
    end
  end

  test "request carrying a valid session cookie exposes the signed in user" do
    with_probe_routes do
      token = sign_in_as(users(:editor))

      get "/probe"

      assert_response :success
      assert_equal "editor@test.com", response.parsed_body["email"]
      assert response.parsed_body["authenticated"]
      assert_equal Session.find_by!(token: token).id, response.parsed_body["session_id"]
    end
  end

  test "starting a session records the request details and sets a session cookie" do
    with_probe_routes do
      token = sign_in_as(users(:admin), user_agent: "ProbeAgent/1.0")

      session_record = Session.find_by!(token: token)

      assert_equal users(:admin).id, session_record.user_id
      assert_equal "127.0.0.1", session_record.ip_address
      assert_equal "ProbeAgent/1.0", session_record.user_agent
      assert cookies[:session_token].present?
    end
  end

  test "require_authentication sends anonymous visitors to the sign in page" do
    with_probe_routes do
      get "/probe/members_only"

      assert_redirected_to "/session/new"
      assert_equal "Please sign in to continue", flash[:alert]
    end
  end

  test "require_authentication lets a signed in user through" do
    with_probe_routes do
      sign_in_as(users(:editor))

      get "/probe/members_only"

      assert_response :success
      assert_equal "members area", response.body
    end
  end

  test "terminate_session destroys the session record and clears the cookie" do
    with_probe_routes do
      token = sign_in_as(users(:editor))

      delete "/probe/sign_out"

      assert_response :success
      assert_nil response.parsed_body["email"]
      assert_nil response.parsed_body["session_id"]
      assert_nil Session.find_by(token: token)
      assert_empty cookies[:session_token]
    end
  end

  test "terminate_session is a no-op for a visitor without a session" do
    with_probe_routes do
      assert_no_difference -> { Session.count } do
        delete "/probe/sign_out"
      end

      assert_response :success
      assert_nil response.parsed_body["email"]
    end
  end

  private

  def sign_in_as(user, user_agent: nil)
    headers = user_agent ? { "User-Agent" => user_agent } : {}
    post "/probe/sign_in/#{user.id}", headers: headers

    assert_response :success
    response.body
  end

  def with_probe_routes(&block)
    with_routing do |set|
      set.draw do
        root to: "authentication_probe#show"
        resource :session, only: :new
        get "/probe", to: "authentication_probe#show"
        get "/probe/members_only", to: "authentication_probe#members_only"
        post "/probe/sign_in/:user_id", to: "authentication_probe#sign_in"
        delete "/probe/sign_out", to: "authentication_probe#sign_out"
      end

      block.call
    end
  end
end
