# frozen_string_literal: true

require "test_helper"

class CommunitiesControllerTest < ActionDispatch::IntegrationTest
  test "GET index renders the empty state when no community exists" do
    assert_equal 0, Community.count

    get communities_path

    assert_response :success
    assert_select "section", text: /We’re mapping the best Ruby meetups/
    assert_select "article", count: 0
  end

  test "GET index lists every community" do
    create_community(platform: "Discord", member_count: 4_000)
    create_community(platform: "Slack", member_count: 9_000)

    get communities_path

    assert_response :success
    assert_select "article", count: 2
    assert_select "h3", text: "Discord community"
    assert_select "h3", text: "Slack community"
  end

  test "GET index sorts official communities before the rest" do
    create_community(platform: "Reddit", member_count: 100_000, is_official: false)
    create_community(platform: "Discord", member_count: 500, is_official: true)

    get communities_path

    assert_response :success
    assert_equal [ "Discord", "Reddit" ], listed_platforms
  end

  test "GET index sorts by member count descending within the same official flag" do
    create_community(platform: "Slack", member_count: 1_000)
    create_community(platform: "Forum", member_count: 30_000)
    create_community(platform: "Discord", member_count: 8_000)

    get communities_path

    assert_response :success
    assert_equal [ "Forum", "Discord", "Slack" ], listed_platforms
  end

  test "GET index marks official communities" do
    create_community(platform: "Discord", member_count: 500, is_official: true)

    get communities_path

    assert_response :success
    assert_select "span", text: /Official/
  end

  test "GET index shows a placeholder for a community without a member count" do
    create_community(platform: "Forum", member_count: nil)

    get communities_path

    assert_response :success
    assert_select "p", text: /Growing members/
  end

  test "GET index formats the member count with a delimiter" do
    create_community(platform: "Slack", member_count: 12_500)

    get communities_path

    assert_response :success
    assert_select "p", text: /12,500 members/
  end

  test "GET index links to the join url of each community" do
    community = create_community(platform: "Discord", member_count: 500)

    get communities_path

    assert_response :success
    assert_select "a[href=?]", community.join_url
  end

  private

  def create_community(platform:, member_count:, is_official: false)
    Community.create!(
      platform: platform,
      join_url: "https://example.com/#{platform.parameterize}",
      member_count: member_count,
      is_official: is_official
    )
  end

  def listed_platforms
    css_select("article h3").map { |node| node.text.sub(" community", "").strip }
  end
end
