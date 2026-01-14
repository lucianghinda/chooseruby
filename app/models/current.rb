# frozen_string_literal: true

class Current < ActiveSupport::CurrentAttributes
  attribute :user, :session, :request_id, :user_agent, :ip_address
end
