# frozen_string_literal: true

require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "GET why_ruby renders the pillars" do
    get why_ruby_path

    assert_response :success
    assert_select "body", text: /Velocity without the overhead/
    assert_select "body", text: /Curated ecosystem of gems/
    assert_select "body", text: /Human-friendly language/
  end

  test "GET why_ruby renders the modern Rails highlights" do
    get why_ruby_path

    assert_response :success
    assert_select "body", text: /Rails 8 \+ Hotwire/
    assert_select "body", text: /Solid Queue & Solid Cache/
    assert_select "body", text: /Vibrant communities/
  end

  test "GET mission renders the mission points" do
    get mission_path

    assert_response :success
    assert_select "body", text: /Surface the best of Ruby/
    assert_select "body", text: /Maintain ecosystem credibility/
    assert_select "body", text: /Champion the community/
  end

  test "GET mission renders every persona" do
    get mission_path

    assert_response :success
    assert_select "body", text: /Sarah/
    assert_select "body", text: /Marcus/
    assert_select "body", text: /Priya/
    assert_select "body", text: /Jordan/
  end

  test "GET roadmap renders the MVP tracks" do
    get roadmap_path

    assert_response :success
    assert_select "body", text: /Searchable directory/
    assert_select "body", text: /Resource profiles/
    assert_select "body", text: /Contribution workflow/
  end

  test "GET roadmap renders the phased roadmap pillars" do
    get roadmap_path

    assert_response :success
    assert_select "body", text: /Phase 1: Foundation/
    assert_select "body", text: /Phase 2: Community/
    assert_select "body", text: /Phase 3: Engagement/
  end
end
