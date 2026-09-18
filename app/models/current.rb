# frozen_string_literal: true

# Per-request attributes available globally for the duration of a request.
class Current < ActiveSupport::CurrentAttributes
  attribute :user, :session, :request_id, :user_agent, :ip_address
end
