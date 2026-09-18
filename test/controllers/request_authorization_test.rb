# frozen_string_literal: true

require "test_helper"

class RequestAuthorizationProbeController < ApplicationController
  prepend_before_action do
    request.set_header("action_dispatch.request_id", request.headers["X-Request-Id"])
  end
  before_action :require_authentication, only: :private_page
  before_action :ensure_can_administer, only: :admin_page

  def private_page
    render plain: current_user.email_address
  end

  def admin_page
    head :ok
  end

  def details
    render json: { request_id: Current.request_id, user_agent: Current.user_agent, ip_address: Current.ip_address }
  end
end

class RequestAuthorizationTest < ActionController::TestCase
  tests RequestAuthorizationProbeController

  setup do
    @routes = ActionDispatch::Routing::RouteSet.new
    @routes.draw do
      get "/private", to: "request_authorization_probe#private_page"
      get "/admin", to: "request_authorization_probe#admin_page"
      get "/details", to: "request_authorization_probe#details"
      get "/", to: "request_authorization_probe#details", as: :root
      get "/session/new", to: "sessions#new", as: :new_session
    end
    Current.reset
  end

  teardown { Current.reset }

  test "unauthenticated requests are redirected to sign in" do
    get :private_page
    assert_redirected_to "/session/new"
  end

  test "unknown signed session token is rejected" do
    @request.cookie_jar.signed[:session_token] = "unknown"
    get :private_page
    assert_redirected_to "/session/new"
  end

  test "expired session is rejected without refreshing activity" do
    session_record = users(:admin).sessions.create!(last_active_at: 31.days.ago)
    @request.cookie_jar.signed[:session_token] = session_record.token
    get :private_page
    assert_redirected_to "/session/new"
    assert_operator session_record.reload.last_active_at, :<, 30.days.ago
  end

  test "valid session supplies the user and refreshes activity" do
    session_record = users(:admin).sessions.create!(last_active_at: 1.day.ago)
    @request.cookie_jar.signed[:session_token] = session_record.token
    get :private_page
    assert_response :success
    assert_equal "admin@test.com", response.body
    assert_operator session_record.reload.last_active_at, :>, 1.hour.ago
  end

  test "editors cannot administer" do
    session_record = users(:editor).sessions.create!
    @request.cookie_jar.signed[:session_token] = session_record.token
    get :admin_page
    assert_redirected_to "/"
  end

  test "admins can administer" do
    session_record = users(:admin).sessions.create!
    @request.cookie_jar.signed[:session_token] = session_record.token
    get :admin_page
    assert_response :success
  end

  test "a banned IP is denied" do
    Ban.create!(ip_address: @request.remote_ip, reason: "Blocked address")
    get :details
    assert_response :forbidden
    assert_equal "Access denied", response.body
  end

  test "a banned user is denied on the first authenticated request" do
    user = users(:admin)
    session_record = user.sessions.create!
    user.suspended!
    @request.cookie_jar.signed[:session_token] = session_record.token

    get :details

    assert_response :forbidden
    assert_equal "Access denied", response.body
  end

  test "anonymous requests cannot administer" do
    get :admin_page
    assert_redirected_to "/"
  end

  test "current request records metadata" do
    @request.user_agent = "ChooseRuby test browser"
    @request.set_header("HTTP_X_REQUEST_ID", "chooseruby-request")
    get :details
    assert_response :success
    details = response.parsed_body
    assert_equal "ChooseRuby test browser", details.fetch("user_agent")
    assert_equal @request.remote_ip, details.fetch("ip_address")
    assert_equal "chooseruby-request", details.fetch("request_id")
  end
end
