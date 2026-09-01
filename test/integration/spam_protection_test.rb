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

  test "rack attack uses the application cache" do
    assert_same Rails.cache, Rack::Attack.cache.store
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

  test "hourly throttle is defined for author proposals creation" do
    throttles = Rack::Attack.throttles
    assert throttles.key?("author_proposals/create/hourly"), "Hourly author proposal throttle should be defined"
  end

  test "daily throttle is defined for author proposals creation" do
    throttles = Rack::Attack.throttles
    assert throttles.key?("author_proposals/create/daily"), "Daily author proposal throttle should be defined"
  end

  test "entry submissions are throttled across route variants" do
    [ "/entries", "/entries.json", "/entries/" ].each do |path|
      assert_equal [ 200, 200, 200, 429 ], response_statuses_after_requests(path, count: 4)
    end
  end

  test "author proposals are throttled across route variants" do
    [ "/author_proposals", "/author_proposals.json", "/author_proposals/" ].each do |path|
      assert_equal [ 200, 200, 200, 429 ], response_statuses_after_requests(path, count: 4)
    end
  end

  test "sessions are throttled across route variants" do
    [ "/session", "/session.json", "/session/" ].each do |path|
      assert_equal [ *Array.new(10, 200), 429 ], response_statuses_after_requests(path, count: 11)
    end
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
    status, headers, body = Rack::Attack.throttled_responder.call(rack_attack_request(env))

    assert_equal 429, status, "Should return 429 status"
    assert_equal "text/html", headers["Content-Type"], "Should return HTML content type"
    assert_match(/rate limit/i, body.first, "Response should mention rate limit")
  end

  test "throttled responder names the window for author proposal limits" do
    env = {
      "rack.attack.matched" => "author_proposals/create/daily",
      "rack.attack.match_type" => :throttle,
      "rack.attack.match_data" => {
        epoch_time: Time.now.to_i,
        period: 1.day.to_i
      }
    }

    _status, _headers, body = Rack::Attack.throttled_responder.call(rack_attack_request(env))

    assert_match(/daily submission limit/i, body.first, "Response should name the daily window")
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

  private

  def response_statuses_after_requests(path, count:)
    original_store = Rack::Attack.cache.store
    test_safelist = Rack::Attack.safelists.delete("allow-test-environment")
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    request = Rack::MockRequest.new(Rack::Attack.new(->(_env) { [ 200, {}, [ "OK" ] ] }))

    count.times.map do
      request.post(path, "REMOTE_ADDR" => "203.0.113.1").status
    end
  ensure
    Rack::Attack.cache.store = original_store
    Rack::Attack.safelists["allow-test-environment"] = test_safelist
  end

  def rack_attack_request(env)
    Rack::Attack::Request.new(Rack::MockRequest.env_for("/", env))
  end
end
