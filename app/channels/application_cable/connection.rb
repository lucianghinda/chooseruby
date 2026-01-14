# frozen_string_literal: true

module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private

    def find_verified_user
      token = cookies.signed[:session_token]
      return reject_unauthorized_connection unless token

      session = Session.includes(:user).find_by(token: token)
      return reject_unauthorized_connection unless session
      return reject_unauthorized_connection if session.expired?

      session.user
    end
  end
end
