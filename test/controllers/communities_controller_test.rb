# frozen_string_literal: true

require "test_helper"

class CommunitiesControllerTest < ActionDispatch::IntegrationTest
  test "index lists communities with official ones first" do
    Community.create!(platform: "Discord", join_url: "https://example.com/discord", member_count: 500, is_official: false)
    Community.create!(platform: "Slack", join_url: "https://example.com/slack", member_count: 100, is_official: true)

    get communities_path

    assert_response :success
    assert_select "h1", text: "Connect with the Ruby community"
    assert_equal [ "Slack community", "Discord community" ], css_select("h3").map(&:text)
  end
end
