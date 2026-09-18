# frozen_string_literal: true

require "test_helper"

class CspReportsControllerTest < ActionDispatch::IntegrationTest
  test "create logs the violation report and returns no content" do
    report = { "csp-report" => { "blocked-uri" => "https://evil.example.com" } }.to_json

    post "/csp-violation-report", params: report, headers: { "CONTENT_TYPE" => "application/csp-report" }

    assert_response :no_content
  end
end
