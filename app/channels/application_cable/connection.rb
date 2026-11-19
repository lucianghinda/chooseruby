# frozen_string_literal: true

module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private

    def find_verified_user
      session = verified_session
      return reject_unauthorized_connection unless session

      session.user
    end

    # The session the cookie points at, as long as it is still usable
    def verified_session
      token = cookies.signed[:session_token]
      return unless token

      session = Session.includes(:user).find_by(token: token)
      session unless session&.expired?
    end
  end
end
