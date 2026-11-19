# frozen_string_literal: true

module ApplicationCable
  # Authenticates WebSocket connections using the signed browser session token.
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private

    def find_verified_user
      session = session_from_cookie
      return reject_unauthorized_connection unless session
      return reject_unauthorized_connection if session.expired?

      session.user
    end

    def session_from_cookie
      token = cookies.signed[:session_token]
      Session.includes(:user).find_by(token: token) if token
    end
  end
end
