# frozen_string_literal: true

require "test_helper"

# Probe controller that echoes back what SetCurrentRequest put on Current.
# Current is reset once the request is done, so the only way to observe it is
# from inside the request itself.
class SetCurrentRequestProbeController < ApplicationController
  def show
    render json: {
      request_id: Current.request_id,
      user_agent: Current.user_agent,
      ip_address: Current.ip_address
    }
  end
end

class SetCurrentRequestTest < ActionDispatch::IntegrationTest
  test "the request details are put on Current before the action runs" do
    with_probe_routes do
      get "/probe", headers: {
        "REMOTE_ADDR" => "203.0.113.42",
        "User-Agent" => "ProbeAgent/1.0"
      }

      assert_response :success
      assert_equal "203.0.113.42", response.parsed_body["ip_address"]
      assert_equal "ProbeAgent/1.0", response.parsed_body["user_agent"]
      assert_equal request.request_id, response.parsed_body["request_id"]
    end
  end

  test "every request gets its own request id" do
    with_probe_routes do
      get "/probe"
      first_request_id = response.parsed_body["request_id"]

      get "/probe"
      second_request_id = response.parsed_body["request_id"]

      assert first_request_id.present?
      assert_not_equal first_request_id, second_request_id
    end
  end

  test "a request without a user agent leaves Current.user_agent empty" do
    with_probe_routes do
      get "/probe"

      assert_response :success
      assert_nil response.parsed_body["user_agent"]
      assert_equal "127.0.0.1", response.parsed_body["ip_address"]
    end
  end

  private

  def with_probe_routes(&block)
    with_routing do |set|
      set.draw do
        root to: "set_current_request_probe#show"
        resource :session, only: :new
        get "/probe", to: "set_current_request_probe#show"
      end

      block.call
    end
  end
end
