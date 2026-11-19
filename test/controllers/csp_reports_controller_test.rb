# frozen_string_literal: true

require "test_helper"

class CspReportsControllerTest < ActionDispatch::IntegrationTest
  REPORT = {
    "csp-report" => {
      "document-uri" => "https://chooseruby.test/",
      "blocked-uri" => "https://evil.test/tracker.js",
      "violated-directive" => "script-src"
    }
  }.freeze

  test "POST csp violation report answers with no content" do
    post "/csp-violation-report", params: REPORT.to_json, headers: { "CONTENT_TYPE" => "application/csp-report" }

    assert_response :no_content
    assert_predicate response.body, :empty?
  end

  test "POST csp violation report logs the raw report as a warning" do
    log = capture_warn_log do
      post "/csp-violation-report", params: REPORT.to_json, headers: { "CONTENT_TYPE" => "application/csp-report" }
    end

    assert_includes log, "CSP VIOLATION"
    assert_includes log, "https://evil.test/tracker.js"
  end

  test "POST csp violation report accepts an empty body" do
    post "/csp-violation-report", headers: { "CONTENT_TYPE" => "application/csp-report" }

    assert_response :no_content
  end

  test "POST csp violation report does not require an authenticity token" do
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true

    post "/csp-violation-report", params: REPORT.to_json, headers: { "CONTENT_TYPE" => "application/csp-report" }

    assert_response :no_content
  ensure
    ActionController::Base.allow_forgery_protection = original
  end

  private

  def capture_warn_log
    buffer = StringIO.new
    original_logger = Rails.logger
    Rails.logger = ActiveSupport::Logger.new(buffer)
    yield
    buffer.string
  ensure
    Rails.logger = original_logger
  end
end
