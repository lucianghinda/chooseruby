# frozen_string_literal: true

require "test_helper"

# Probe controller used to exercise Authentication::SessionLookup through the
# before_action that ApplicationController installs.
class SessionLookupProbeController < ApplicationController
  def show
    render json: { email: current_user&.email_address }
  end

  def sign_in
    start_new_session_for(User.find(params[:user_id]))

    render plain: Current.session.token
  end
end

class SessionLookupTest < ActionDispatch::IntegrationTest
  test "without a session cookie no user is looked up" do
    with_probe_routes do
      get "/probe"

      assert_response :success
      assert_nil response.parsed_body["email"]
    end
  end

  test "a valid cookie resolves to the session owner" do
    with_probe_routes do
      token = sign_in_as(users(:admin))

      get "/probe"

      assert_response :success
      assert_equal "admin@test.com", response.parsed_body["email"]
      assert_equal users(:admin).id, Session.find_by!(token: token).user_id
    end
  end

  test "looking up a session keeps it alive by touching last_active_at" do
    with_probe_routes do
      token = sign_in_as(users(:admin))
      session_record = Session.find_by!(token: token)
      session_record.update_column(:last_active_at, 2.hours.ago)

      get "/probe"

      assert_response :success
      assert_operator session_record.reload.last_active_at, :>, 1.minute.ago
    end
  end

  test "a cookie whose session no longer exists is ignored" do
    with_probe_routes do
      token = sign_in_as(users(:admin))
      Session.find_by!(token: token).destroy

      get "/probe"

      assert_response :success
      assert_nil response.parsed_body["email"]
    end
  end

  test "an expired session is ignored and not kept alive" do
    with_probe_routes do
      token = sign_in_as(users(:admin))
      session_record = Session.find_by!(token: token)
      expired_at = 31.days.ago
      session_record.update_column(:last_active_at, expired_at)

      get "/probe"

      assert_response :success
      assert_nil response.parsed_body["email"]
      assert_in_delta expired_at, session_record.reload.last_active_at, 1.second
    end
  end

  private

  def sign_in_as(user)
    post "/probe/sign_in/#{user.id}"

    assert_response :success
    response.body
  end

  def with_probe_routes(&block)
    with_routing do |set|
      set.draw do
        root to: "session_lookup_probe#show"
        resource :session, only: :new
        get "/probe", to: "session_lookup_probe#show"
        post "/probe/sign_in/:user_id", to: "session_lookup_probe#sign_in"
      end

      block.call
    end
  end
end
