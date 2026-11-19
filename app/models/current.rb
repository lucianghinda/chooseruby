# frozen_string_literal: true

# Stores request-local authentication state.
class Current < ActiveSupport::CurrentAttributes
  attribute :user, :session, :request_id, :user_agent, :ip_address
end
