# frozen_string_literal: true

module Authentication
  module SessionLookup
    extend ActiveSupport::Concern

    private

    def find_session_by_cookie
      token = cookies.signed[:session_token]
      return nil unless token

      # Eager load user to prevent N+1 queries
      session = Session.includes(:user).find_by(token: token)
      return nil unless session
      return nil if session.expired?

      # Touch last_active_at to keep session alive
      session.touch_last_active

      session
    end
  end
end
