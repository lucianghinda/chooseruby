# frozen_string_literal: true

module Authentication
  extend ActiveSupport::Concern

  include Authentication::SessionLookup

  included do
    before_action :set_current_user
  end

  private

  def set_current_user
    if session = find_session_by_cookie
      Current.user = session.user
      Current.session = session
    end
  end

  def start_new_session_for(user)
    session = user.sessions.create!(
      ip_address: request.remote_ip,
      user_agent: request.user_agent
    )

    cookies.signed.permanent[:session_token] = {
      value: session.token,
      httponly: true,
      same_site: :lax
    }

    Current.session = session
    Current.user = user
  end

  def terminate_session
    Current.session&.destroy
    cookies.delete(:session_token)
    Current.user = nil
    Current.session = nil
  end
end
