# frozen_string_literal: true

require "test_helper"

# Probe controller used to exercise the Authorization concern over a real
# request/response cycle.
class AuthorizationProbeController < ApplicationController
  before_action :ensure_can_administer, only: :admin_area

  def show
    render json: { can_administer: can_administer? }
  end

  def admin_area
    render plain: "admin area"
  end

  def sign_in
    start_new_session_for(User.find(params[:user_id]))

    head :ok
  end
end

class AuthorizationTest < ActionDispatch::IntegrationTest
  test "an anonymous visitor cannot administer" do
    with_probe_routes do
      get "/probe"

      assert_response :success
      assert_nil response.parsed_body["can_administer"]
    end
  end

  test "an editor cannot administer" do
    with_probe_routes do
      sign_in_as users(:editor)

      get "/probe"

      assert_response :success
      assert_not response.parsed_body["can_administer"]
    end
  end

  test "an admin can administer" do
    with_probe_routes do
      sign_in_as users(:admin)

      get "/probe"

      assert_response :success
      assert response.parsed_body["can_administer"]
    end
  end

  test "ensure_can_administer turns an anonymous visitor away" do
    with_probe_routes do
      get "/probe/admin_area"

      assert_redirected_to "/"
      assert_equal "You are not authorized to access this page", flash[:alert]
    end
  end

  test "ensure_can_administer turns an editor away" do
    with_probe_routes do
      sign_in_as users(:editor)

      get "/probe/admin_area"

      assert_redirected_to "/"
      assert_equal "You are not authorized to access this page", flash[:alert]
    end
  end

  test "ensure_can_administer lets an admin through" do
    with_probe_routes do
      sign_in_as users(:admin)

      get "/probe/admin_area"

      assert_response :success
      assert_equal "admin area", response.body
    end
  end

  private

  def sign_in_as(user)
    post "/probe/sign_in/#{user.id}"

    assert_response :success
  end

  def with_probe_routes(&block)
    with_routing do |set|
      set.draw do
        root to: "authorization_probe#show"
        resource :session, only: :new
        get "/probe", to: "authorization_probe#show"
        get "/probe/admin_area", to: "authorization_probe#admin_area"
        post "/probe/sign_in/:user_id", to: "authorization_probe#sign_in"
      end

      block.call
    end
  end
end
