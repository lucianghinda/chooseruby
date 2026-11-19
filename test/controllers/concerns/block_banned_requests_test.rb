# frozen_string_literal: true

require "test_helper"

# Probe controller used to exercise the BlockBannedRequests concern through the
# before_action that ApplicationController installs.
class BlockBannedProbeController < ApplicationController
  def show
    render plain: "welcome"
  end
end

class BlockBannedRequestsTest < ActionDispatch::IntegrationTest
  BANNED_IP = "203.0.113.7"
  ALLOWED_IP = "203.0.113.8"

  test "a request from an unbanned ip is served" do
    with_probe_routes do
      get_from ALLOWED_IP

      assert_response :success
      assert_equal "welcome", response.body
    end
  end

  test "a request from a permanently banned ip is refused" do
    Ban.create!(ip_address: BANNED_IP, reason: "Abuse", expires_at: nil)

    with_probe_routes do
      get_from BANNED_IP

      assert_response :forbidden
      assert_equal "Access denied", response.body
    end
  end

  test "a request from an ip with a ban that has not run out yet is refused" do
    Ban.create!(ip_address: BANNED_IP, reason: "Abuse", expires_at: 1.day.from_now)

    with_probe_routes do
      get_from BANNED_IP

      assert_response :forbidden
    end
  end

  test "a request from an ip whose ban has run out is served again" do
    Ban.create!(ip_address: BANNED_IP, reason: "Abuse", expires_at: 1.day.ago)

    with_probe_routes do
      get_from BANNED_IP

      assert_response :success
    end
  end

  test "a ban only blocks the ip address it was issued for" do
    Ban.create!(ip_address: BANNED_IP, reason: "Abuse", expires_at: nil)

    with_probe_routes do
      get_from ALLOWED_IP

      assert_response :success
    end
  end

  # Regression guard: BlockBannedRequests must be included after Authentication,
  # otherwise block_if_banned reads a Current.user that is still nil and a
  # suspended user browses the public site unhindered.
  test "a signed in user who has been banned is refused on the public site" do
    user = User.create!(
      email_address: "banned-visitor@test.com",
      name: "Banned Visitor",
      password: "password",
      status: "active"
    )
    post "/session", params: { email_address: user.email_address, password: "password" }
    assert cookies[:session_token].present?

    # A real route, not the probe: with_routing starts a fresh integration
    # session, which drops the signed session cookie this test depends on.
    get root_path
    assert_response :success

    user.update!(status: "suspended")

    get root_path
    assert_response :forbidden
    assert_equal "Access denied", response.body
  end

  test "a signed in user who has been banned is refused inside Avo" do
    admin = User.create!(
      email_address: "banned-admin@test.com",
      name: "Banned Admin",
      password: "password",
      role: "admin",
      status: "active"
    )
    post "/session", params: { email_address: admin.email_address, password: "password" }
    assert cookies[:session_token].present?

    get "/avo/resources/articles"
    assert_response :success

    admin.update!(status: "suspended")

    get "/avo/resources/articles"
    assert_response :forbidden
    assert_equal "Access denied", response.body
  end

  private

  def get_from(ip_address)
    get "/probe", headers: { "REMOTE_ADDR" => ip_address }
  end

  def with_probe_routes(&block)
    with_routing do |set|
      set.draw do
        root to: "block_banned_probe#show"
        resource :session, only: :new
        get "/probe", to: "block_banned_probe#show"
      end

      block.call
    end
  end
end
