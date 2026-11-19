# frozen_string_literal: true

module Authentication
  # Finds a valid session and refreshes its activity timestamp.
  module SessionLookup
    extend ActiveSupport::Concern

    private

    def find_session_by_cookie
      token = cookies.signed[:session_token]
      return nil unless token

      # Eager load user to prevent N+1 queries
      Session.strict_loading.includes(:user).find_by(token: token)&.resume
    end
  end
end
