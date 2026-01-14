# frozen_string_literal: true

require "test_helper"

class SpamProtectionTest < ActionDispatch::IntegrationTest
  setup do
    # Clear rate limiting data before each test
    Rack::Attack.cache.store.clear if defined?(Rack::Attack)
  end

  test "rack attack middleware is loaded" do
    assert Rails.application.config.middleware.include?(Rack::Attack), "Rack::Attack middleware should be loaded"
  end

  test "rack attack cache store is configured" do
    assert_not_nil Rack::Attack.cache.store, "Rack::Attack cache store should be configured"
  end

  test "hourly throttle is defined for entries creation" do
    # Check that the throttle is registered
    throttles = Rack::Attack.throttles
    assert throttles.key?("entries/create/hourly"), "Hourly throttle should be defined"
  end

  test "daily throttle is defined for entries creation" do
    # Check that the throttle is registered
    throttles = Rack::Attack.throttles
    assert throttles.key?("entries/create/daily"), "Daily throttle should be defined"
  end

  test "localhost is safelisted from rate limiting" do
    # Verify safelist exists for localhost
    safelists = Rack::Attack.safelists
    assert safelists.key?("allow-localhost"), "Localhost safelist should be defined"
  end

  test "test environment is safelisted from rate limiting" do
    # Verify safelist exists for test environment
    safelists = Rack::Attack.safelists
    assert safelists.key?("allow-test-environment"), "Test environment safelist should be defined"
  end

  test "throttled responder returns 429 status" do
    # Create a mock environment that simulates a throttled request
    env = {
      "rack.attack.matched" => "entries/create/hourly",
      "rack.attack.match_type" => :throttle,
      "rack.attack.match_data" => {
        epoch_time: Time.now.to_i,
        period: 3600
      }
    }

    # Call the throttled responder
    status, headers, body = Rack::Attack.throttled_responder.call(env)

    assert_equal 429, status, "Should return 429 status"
    assert_equal "text/html", headers["Content-Type"], "Should return HTML content type"
    assert_match(/rate limit/i, body.first, "Response should mention rate limit")
  end

  test "active hashcash gem is loaded" do
    # Verify ActiveHashcash module is defined
    assert defined?(ActiveHashcash), "ActiveHashcash should be defined"
  end

  test "active hashcash difficulty bits is set to appropriate level" do
    # Verify difficulty level is set (should be between 12-16 for forms)
    assert_not_nil ActiveHashcash.bits, "ActiveHashcash.bits should be configured"
    assert ActiveHashcash.bits >= 10, "Difficulty should be at least 10 bits"
    assert ActiveHashcash.bits <= 20, "Difficulty should be at most 20 bits"
  end
end
