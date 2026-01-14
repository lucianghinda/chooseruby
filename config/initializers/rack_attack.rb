# frozen_string_literal: true

# Configure Rack::Attack for rate limiting and throttling
# Documentation: https://github.com/rack/rack-attack

class Rack::Attack
  # Use Rails.cache for storing throttle data
  # This leverages the configured cache store (solid_cache in production)
  Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

  # Safelist: Allow requests from localhost and testing environments
  safelist("allow-localhost") do |req|
    req.ip == "127.0.0.1" || req.ip == "::1"
  end

  safelist("allow-test-environment") do |_req|
    Rails.env.test?
  end

  # Throttle: Limit entry submissions to 3 requests per IP per hour
  # This prevents rapid-fire spam submissions
  throttle("entries/create/hourly", limit: 3, period: 1.hour) do |req|
    if req.path == "/entries" && req.post?
      # Return the IP address to track the request
      req.ip
    end
  end

  # Throttle: Limit entry submissions to 10 requests per IP per day
  # This provides a broader safety net for daily submission limits
  throttle("entries/create/daily", limit: 10, period: 1.day) do |req|
    if req.path == "/entries" && req.post?
      # Return the IP address to track the request
      req.ip
    end
  end

  # Throttle: Limit login attempts to 10 requests per IP per 3 minutes
  # This prevents brute force attacks on the login page
  throttle("sessions/create", limit: 10, period: 3.minutes) do |req|
    if req.path == "/session" && req.post?
      req.ip
    end
  end

  # Custom response for throttled requests
  # Return a user-friendly 429 (Too Many Requests) response
  self.throttled_responder = lambda do |env|
    match_data = env["rack.attack.match_data"]
    now = match_data[:epoch_time]

    headers = {
      "Content-Type" => "text/html",
      "Retry-After" => match_data[:period].to_s
    }

    # Determine which limit was exceeded
    limit_type = if env["rack.attack.matched"] == "entries/create/hourly"
      "hourly"
    elsif env["rack.attack.matched"] == "entries/create/daily"
      "daily"
    else
      "rate"
    end

    # User-friendly error message
    body = <<~HTML
      <!DOCTYPE html>
      <html>
      <head>
        <title>Rate Limit Exceeded</title>
        <style>
          body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
            margin: 0;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          }
          .container {
            background: white;
            padding: 3rem;
            border-radius: 1rem;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            max-width: 500px;
            text-align: center;
          }
          h1 {
            color: #e53e3e;
            margin-bottom: 1rem;
          }
          p {
            color: #4a5568;
            line-height: 1.6;
          }
          .emoji {
            font-size: 4rem;
            margin-bottom: 1rem;
          }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="emoji">🚫</div>
          <h1>Rate Limit Exceeded</h1>
          <p>
            You've exceeded the #{limit_type} submission limit.
            Please try again later.
          </p>
          <p>
            <small>If you need to submit multiple resources, please wait a bit between submissions.</small>
          </p>
        </div>
      </body>
      </html>
    HTML

    [ 429, headers, [ body ] ]
  end

  # Log throttled requests for monitoring
  ActiveSupport::Notifications.subscribe("rack.attack") do |name, start, finish, request_id, payload|
    req = payload[:request]
    if [ :throttle ].include?(req.env["rack.attack.match_type"])
      Rails.logger.warn("[Rack::Attack] Throttled request from #{req.ip} to #{req.path}")
    end
  end
end
